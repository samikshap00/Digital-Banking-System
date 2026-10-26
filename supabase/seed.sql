-- Demonstration data. Replace the placeholder auth user IDs with IDs from Supabase Auth.
-- The insert blocks are intentionally commented until real Auth users exist.

insert into public.branches (branch_code, branch_name, address, city)
values
  ('MUM001', 'Vesit Main Branch', '123 University Road', 'Mumbai'),
  ('PUN001', 'Pune Central Branch', '45 Banking Street', 'Pune')
on conflict (branch_code) do nothing;

-- After creating Auth users, run the following pattern with their UUIDs:
-- insert into public.profiles (user_id, full_name, email, phone, role, branch_id)
-- values ('AUTH-USER-UUID', 'Aarav Kulkarni', 'aarav@example.com', '9000000001', 'customer', (select branch_id from public.branches where branch_code='MUM001'));
-- insert into public.profiles (user_id, full_name, email, phone, role, branch_id)
-- values ('STAFF-USER-UUID', 'Neha Sharma', 'neha.staff@example.com', '9000000002', 'staff', (select branch_id from public.branches where branch_code='MUM001'));
-- insert into public.profiles (user_id, full_name, email, phone, role, branch_id)
-- values ('ADMIN-USER-UUID', 'System Administrator', 'admin@example.com', '9000000003', 'admin', (select branch_id from public.branches where branch_code='MUM001'));

-- Accounts and transactions should be inserted after profiles exist so that foreign keys remain valid.
