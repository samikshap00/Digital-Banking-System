-- Run after schema.sql. RLS is the access-control layer used by the frontend.

alter table public.branches enable row level security;
alter table public.profiles enable row level security;
alter table public.accounts enable row level security;
alter table public.beneficiaries enable row level security;
alter table public.transactions enable row level security;
alter table public.recovery_demo_events enable row level security;

drop policy if exists "authenticated users can view branches" on public.branches;
drop policy if exists "users view their own profile" on public.profiles;
drop policy if exists "users update their own profile" on public.profiles;
drop policy if exists "users and admins update profiles" on public.profiles;
drop policy if exists "customers view own accounts staff view all" on public.accounts;
drop policy if exists "admins insert accounts" on public.accounts;
drop policy if exists "staff update account status" on public.accounts;
drop policy if exists "customers manage own beneficiaries" on public.beneficiaries;
drop policy if exists "users view related transactions staff view all" on public.transactions;
drop policy if exists "users insert their own transactions" on public.transactions;
drop policy if exists "customers view own recovery demo events" on public.recovery_demo_events;

create policy "authenticated users can view branches"
on public.branches for select to authenticated using (true);

create policy "users view their own profile"
on public.profiles for select to authenticated
using (user_id = auth.uid() or public.current_user_role() = 'admin');

create policy "users and admins update profiles"
on public.profiles for update to authenticated
using (user_id = auth.uid() or public.current_user_role() = 'admin')
with check (user_id = auth.uid() or public.current_user_role() = 'admin');

create policy "customers view own accounts staff view all"
on public.accounts for select to authenticated
using (user_id = auth.uid() or public.current_user_role() in ('staff', 'admin'));

create policy "admins insert accounts"
on public.accounts for insert to authenticated
with check (public.current_user_role() = 'admin');

create policy "customers manage own beneficiaries"
on public.beneficiaries for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "users view related transactions staff view all"
on public.transactions for select to authenticated
using (
  initiated_by = auth.uid()
  or exists (select 1 from public.accounts a where a.account_id in (from_account_id, to_account_id) and a.user_id = auth.uid())
  or public.current_user_role() in ('staff', 'admin')
);

create policy "customers view own recovery demo events"
on public.recovery_demo_events for select to authenticated
using (user_id = auth.uid());

revoke all on public.transactions from anon, authenticated;
revoke all on public.recovery_demo_events from anon, authenticated;
revoke all on public.accounts from anon, authenticated;
revoke all on public.profiles from anon, authenticated;
revoke all on public.branches from anon, authenticated;
revoke all on public.beneficiaries from anon, authenticated;
grant select on public.transactions to authenticated;
grant select on public.recovery_demo_events to authenticated;
grant select on public.accounts to authenticated;
grant select on public.account_summary to authenticated;
grant select on public.branches to authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, phone) on public.profiles to authenticated;
grant select, insert, update, delete on public.beneficiaries to authenticated;

revoke all on function public.transfer_money(uuid, text, numeric, text) from public, anon;
revoke all on function public.demo_interrupted_transfer(uuid, text, numeric) from public, anon;
revoke all on function public.staff_set_account_status(uuid, public.account_status) from public, anon;
revoke all on function public.admin_set_account_status(uuid, public.account_status) from public, anon;
revoke all on function public.admin_set_user_role(uuid, public.user_role) from public, anon;
revoke all on function public.admin_create_account(uuid, text, public.account_type, numeric, uuid) from public, anon;
revoke all on function public.admin_dashboard_metrics() from public, anon;
revoke all on function public.admin_list_beneficiaries() from public, anon;
revoke all on function public.admin_delete_beneficiary(uuid) from public, anon;
revoke all on function public.current_user_role() from public, anon;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.transfer_money(uuid, text, numeric, text) to authenticated;
grant execute on function public.demo_interrupted_transfer(uuid, text, numeric) to authenticated;
grant execute on function public.staff_set_account_status(uuid, public.account_status) to authenticated;
grant execute on function public.admin_set_account_status(uuid, public.account_status) to authenticated;
grant execute on function public.admin_set_user_role(uuid, public.user_role) to authenticated;
grant execute on function public.admin_create_account(uuid, text, public.account_type, numeric, uuid) to authenticated;
grant execute on function public.admin_dashboard_metrics() to authenticated;
grant execute on function public.admin_list_beneficiaries() to authenticated;
grant execute on function public.admin_delete_beneficiary(uuid) to authenticated;
