-- Digital Banking System Database
-- Run this file first in the Supabase SQL Editor.

create extension if not exists pgcrypto;

do $$ begin create type public.user_role as enum ('customer', 'staff', 'admin'); exception when duplicate_object then null; end $$;
do $$ begin create type public.account_type as enum ('savings', 'current'); exception when duplicate_object then null; end $$;
do $$ begin create type public.account_status as enum ('active', 'frozen', 'closed'); exception when duplicate_object then null; end $$;
do $$ begin create type public.transaction_type as enum ('deposit', 'withdrawal', 'transfer'); exception when duplicate_object then null; end $$;
do $$ begin create type public.transaction_status as enum ('pending', 'completed', 'failed', 'reversed'); exception when duplicate_object then null; end $$;

create table if not exists public.branches (
  branch_id uuid primary key default gen_random_uuid(),
  branch_code text not null unique,
  branch_name text not null,
  address text not null,
  city text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  phone text unique,
  role public.user_role not null default 'customer',
  branch_id uuid references public.branches(branch_id),
  created_at timestamptz not null default now()
);

create table if not exists public.accounts (
  account_id uuid primary key default gen_random_uuid(),
  account_number text not null unique,
  user_id uuid not null references public.profiles(user_id) on delete restrict,
  branch_id uuid not null references public.branches(branch_id) on delete restrict,
  account_type public.account_type not null default 'savings',
  balance numeric(14,2) not null default 0 check (balance >= 0),
  status public.account_status not null default 'active',
  opened_on date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.beneficiaries (
  beneficiary_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  nickname text not null,
  beneficiary_name text not null,
  beneficiary_account_number text not null,
  bank_name text not null,
  ifsc_code text not null,
  created_at timestamptz not null default now(),
  unique(user_id, beneficiary_account_number)
);

create table if not exists public.transactions (
  transaction_id uuid primary key default gen_random_uuid(),
  from_account_id uuid references public.accounts(account_id),
  to_account_id uuid references public.accounts(account_id),
  amount numeric(14,2) not null check (amount > 0),
  transaction_type public.transaction_type not null,
  status public.transaction_status not null default 'completed',
  description text,
  initiated_by uuid not null references public.profiles(user_id),
  created_at timestamptz not null default now(),
  check (from_account_id is not null or to_account_id is not null),
  check (from_account_id is null or to_account_id is null or from_account_id <> to_account_id)
);

-- Durable demonstration audit entries. The actual pending transaction is rolled
-- back; this separate row records the attempted demo after the rollback.
create table if not exists public.recovery_demo_events (
  event_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  from_account_id uuid not null references public.accounts(account_id) on delete restrict,
  to_account_masked text not null,
  amount numeric(14,2) not null check (amount > 0),
  status text not null default 'rolled_back' check (status = 'rolled_back'),
  detail text not null,
  created_at timestamptz not null default now()
);

create index if not exists accounts_user_id_idx on public.accounts(user_id);
create index if not exists transactions_from_account_idx on public.transactions(from_account_id, created_at desc);
create index if not exists transactions_to_account_idx on public.transactions(to_account_id, created_at desc);
create index if not exists beneficiaries_user_id_idx on public.beneficiaries(user_id);
create index if not exists recovery_demo_events_user_idx on public.recovery_demo_events(user_id, created_at desc);

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where user_id = auth.uid();
$$;

drop view if exists public.account_summary;
create view public.account_summary with (security_invoker = true) as
select
  a.account_id,
  'XXXX-XXXX-' || right(a.account_number, 4) as masked_account_number,
  a.account_type,
  a.balance,
  a.status,
  b.branch_name,
  a.opened_on
from public.accounts a
join public.branches b on b.branch_id = a.branch_id;

alter view public.account_summary set (security_invoker = true);

create or replace function public.transfer_money(
  p_from_account uuid,
  p_to_account_number text,
  p_amount numeric,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_transaction_id uuid;
  v_to_account uuid;
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or public.current_user_role() is distinct from 'customer' then
    raise exception 'Only an authenticated customer can initiate a transfer';
  end if;
  if p_amount <= 0 then raise exception 'Transfer amount must be positive'; end if;

  select account_id into v_to_account
  from public.accounts
  where account_number = p_to_account_number and status = 'active';
  if v_to_account is null then raise exception 'Destination account is invalid or inactive'; end if;
  if p_from_account = v_to_account then raise exception 'Source and destination accounts must differ'; end if;

  perform 1 from public.accounts
  where account_id in (p_from_account, v_to_account)
  order by account_id for update;

  update public.accounts
  set balance = balance - p_amount
  where account_id = p_from_account and user_id = v_user_id
    and status = 'active' and balance >= p_amount;
  if not found then raise exception 'Source account is invalid or has insufficient balance'; end if;

  update public.accounts set balance = balance + p_amount
  where account_id = v_to_account and status = 'active';
  if not found then raise exception 'Destination account is invalid or inactive'; end if;

  insert into public.transactions(from_account_id, to_account_id, amount, transaction_type, status, description, initiated_by)
  values (p_from_account, v_to_account, p_amount, 'transfer', 'completed', p_description, v_user_id)
  returning transaction_id into v_transaction_id;
  return v_transaction_id;
end;
$$;

-- Recovery demo rolls back its nested financial changes and records a separate audit event.
drop function if exists public.demo_interrupted_transfer(uuid, text, numeric);
create function public.demo_interrupted_transfer(
  p_from_account uuid,
  p_to_account_number text,
  p_amount numeric
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_to_account uuid;
  v_user_id uuid := auth.uid();
  v_destination_number text;
  v_event_id uuid;
  v_detail text := 'The simulated interruption rolled back the debit and pending ledger row.';
begin
  if v_user_id is null or public.current_user_role() is distinct from 'customer' then
    raise exception 'Sign in as a customer to run the recovery demonstration';
  end if;
  if p_amount <= 0 then raise exception 'Demo amount must be positive'; end if;

  select account_id, account_number into v_to_account, v_destination_number from public.accounts
  where account_number = p_to_account_number and status = 'active';
  if v_to_account is null or v_to_account = p_from_account then
    raise exception 'Choose a different active destination account';
  end if;

  perform 1 from public.accounts
  where account_id in (p_from_account, v_to_account)
  order by account_id for update;

  begin
    update public.accounts set balance = balance - p_amount
    where account_id = p_from_account and user_id = v_user_id
      and status = 'active' and balance >= p_amount;
    if not found then raise exception 'Source account is invalid or has insufficient balance'; end if;

    insert into public.transactions(from_account_id, to_account_id, amount, transaction_type, status, description, initiated_by)
    values (p_from_account, v_to_account, p_amount, 'transfer', 'pending', 'RECOVERY DEMO - intentionally interrupted', v_user_id);

    -- A nested PL/pgSQL block is a subtransaction: this exception rolls back
    -- its debit and pending row, while the outer block can record the demo event.
    raise exception using errcode = 'PZ001', message = 'DEMO INTERRUPTION';
  exception when sqlstate 'PZ001' then
    insert into public.recovery_demo_events(user_id, from_account_id, to_account_masked, amount, status, detail)
    values (v_user_id, p_from_account, 'XXXX-XXXX-' || right(v_destination_number, 4), p_amount, 'rolled_back', v_detail)
    returning event_id into v_event_id;
  end;

  return jsonb_build_object('event_id', v_event_id, 'status', 'rolled_back', 'detail', v_detail);
end;
$$;

create or replace function public.staff_set_account_status(p_account_id uuid, p_status public.account_status)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if public.current_user_role() is distinct from 'staff' then raise exception 'Staff role required'; end if;
  if p_status not in ('active', 'frozen') then raise exception 'Staff may only activate or freeze accounts'; end if;
  update public.accounts set status = p_status where account_id = p_account_id;
  if not found then raise exception 'Account not found'; end if;
end;
$$;

create or replace function public.admin_set_account_status(p_account_id uuid, p_status public.account_status)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if public.current_user_role() is distinct from 'admin' then raise exception 'Admin role required'; end if;
  update public.accounts set status = p_status where account_id = p_account_id;
  if not found then raise exception 'Account not found'; end if;
end;
$$;

create or replace function public.admin_set_user_role(p_user_id uuid, p_role public.user_role)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if public.current_user_role() is distinct from 'admin' then raise exception 'Admin role required'; end if;
  if p_user_id = auth.uid() then raise exception 'Administrators cannot change their own role'; end if;
  update public.profiles set role = p_role where user_id = p_user_id;
  if not found then raise exception 'User profile not found'; end if;
end;
$$;

create or replace function public.admin_create_account(
  p_user_id uuid,
  p_account_number text,
  p_account_type public.account_type,
  p_opening_balance numeric,
  p_branch_id uuid
)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_account_id uuid;
begin
  if public.current_user_role() is distinct from 'admin' then raise exception 'Admin role required'; end if;
  if p_opening_balance < 0 then raise exception 'Opening balance cannot be negative'; end if;
  insert into public.accounts(account_number, user_id, branch_id, account_type, balance)
  values (p_account_number, p_user_id, p_branch_id, p_account_type, p_opening_balance)
  returning account_id into v_account_id;
  return v_account_id;
end;
$$;

create or replace function public.admin_dashboard_metrics()
returns table(customer_count bigint, staff_count bigint, admin_count bigint, account_count bigint,
              active_count bigint, frozen_count bigint, closed_count bigint,
              total_balance numeric, transfers_today bigint)
language plpgsql security definer set search_path = ''
as $$
begin
  if public.current_user_role() is distinct from 'admin' then raise exception 'Admin role required'; end if;
  return query
  select
    count(*) filter (where role='customer'), count(*) filter (where role='staff'), count(*) filter (where role='admin'),
    (select count(*) from public.accounts),
    (select count(*) from public.accounts where status='active'),
    (select count(*) from public.accounts where status='frozen'),
    (select count(*) from public.accounts where status='closed'),
    (select coalesce(sum(balance),0) from public.accounts where status <> 'closed'),
    (select count(*) from public.transactions where transaction_type='transfer' and created_at::date=current_date)
  from public.profiles;
end;
$$;

create or replace function public.admin_list_beneficiaries()
returns table(beneficiary_id uuid, customer_name text, customer_email text, nickname text,
              beneficiary_name text, masked_account_number text, bank_name text, ifsc_code text, created_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
begin
  if public.current_user_role() is distinct from 'admin' then raise exception 'Admin role required'; end if;
  return query
  select b.beneficiary_id, p.full_name, p.email, b.nickname, b.beneficiary_name,
         'XXXX-XXXX-' || right(b.beneficiary_account_number, 4), b.bank_name, b.ifsc_code, b.created_at
  from public.beneficiaries b join public.profiles p on p.user_id = b.user_id
  order by b.created_at desc;
end;
$$;

create or replace function public.admin_delete_beneficiary(p_beneficiary_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if public.current_user_role() is distinct from 'admin' then raise exception 'Admin role required'; end if;
  delete from public.beneficiaries where beneficiary_id = p_beneficiary_id;
  if not found then raise exception 'Beneficiary not found'; end if;
end;
$$;
