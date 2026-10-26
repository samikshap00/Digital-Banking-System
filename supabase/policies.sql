-- Run after schema.sql. RLS is the access-control layer used by the frontend.

alter table public.branches enable row level security;
alter table public.profiles enable row level security;
alter table public.accounts enable row level security;
alter table public.beneficiaries enable row level security;
alter table public.transactions enable row level security;

create policy "authenticated users can view branches"
on public.branches for select to authenticated using (true);

create policy "users view their own profile"
on public.profiles for select to authenticated
using (user_id = auth.uid() or public.current_user_role() in ('staff', 'admin'));

create policy "users update their own profile"
on public.profiles for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "customers view own accounts staff view all"
on public.accounts for select to authenticated
using (user_id = auth.uid() or public.current_user_role() in ('staff', 'admin'));

create policy "admins insert accounts"
on public.accounts for insert to authenticated
with check (public.current_user_role() = 'admin');

create policy "staff update account status"
on public.accounts for update to authenticated
using (public.current_user_role() in ('staff', 'admin'))
with check (public.current_user_role() in ('staff', 'admin'));

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

create policy "users insert their own transactions"
on public.transactions for insert to authenticated
with check (initiated_by = auth.uid());

grant execute on function public.transfer_money(uuid, text, numeric, text) to authenticated;
