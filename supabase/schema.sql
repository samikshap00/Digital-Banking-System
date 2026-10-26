-- Digital Banking System Database
-- Run this file first in the Supabase SQL Editor.

create extension if not exists pgcrypto;

create type public.user_role as enum ('customer', 'staff', 'admin');
create type public.account_type as enum ('savings', 'current');
create type public.account_status as enum ('active', 'frozen', 'closed');
create type public.transaction_type as enum ('deposit', 'withdrawal', 'transfer');
create type public.transaction_status as enum ('pending', 'completed', 'failed', 'reversed');

create table public.branches (
  branch_id uuid primary key default gen_random_uuid(),
  branch_code text not null unique,
  branch_name text not null,
  address text not null,
  city text not null,
  created_at timestamptz not null default now()
);

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  phone text unique,
  role public.user_role not null default 'customer',
  branch_id uuid references public.branches(branch_id),
  created_at timestamptz not null default now()
);

create table public.accounts (
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

create table public.beneficiaries (
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

create table public.transactions (
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

create index accounts_user_id_idx on public.accounts(user_id);
create index transactions_from_account_idx on public.transactions(from_account_id, created_at desc);
create index transactions_to_account_idx on public.transactions(to_account_id, created_at desc);
create index beneficiaries_user_id_idx on public.beneficiaries(user_id);

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where user_id = auth.uid();
$$;

create or replace view public.account_summary as
select
  a.account_id,
  a.account_number,
  a.user_id,
  p.full_name,
  p.email,
  a.account_type,
  a.balance,
  a.status,
  b.branch_name,
  a.opened_on
from public.accounts a
join public.profiles p on p.user_id = a.user_id
join public.branches b on b.branch_id = a.branch_id;

create or replace function public.transfer_money(
  p_from_account uuid,
  p_to_account_number text,
  p_amount numeric,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_transaction_id uuid;
  v_to_account uuid;
  v_user_id uuid := auth.uid();
begin
  if p_amount <= 0 then raise exception 'Transfer amount must be positive'; end if;

  select account_id into v_to_account
  from public.accounts
  where account_number = p_to_account_number and status = 'active';
  if v_to_account is null then raise exception 'Destination account is invalid or inactive'; end if;
  if p_from_account = v_to_account then raise exception 'Source and destination accounts must differ'; end if;

  update public.accounts
  set balance = balance - p_amount
  where account_id = p_from_account
    and user_id = v_user_id
    and status = 'active'
    and balance >= p_amount;
  if not found then raise exception 'Source account is invalid or has insufficient balance'; end if;

  update public.accounts
  set balance = balance + p_amount
  where account_id = v_to_account and status = 'active';
  if not found then raise exception 'Destination account is invalid or inactive'; end if;

  insert into public.transactions(from_account_id, to_account_id, amount, transaction_type, status, description, initiated_by)
  values (p_from_account, v_to_account, p_amount, 'transfer', 'completed', p_description, v_user_id)
  returning transaction_id into v_transaction_id;
  return v_transaction_id;
end;
$$;
