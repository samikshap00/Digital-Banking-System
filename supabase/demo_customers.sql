-- Create 12 customer profiles, accounts in all supported states, beneficiaries,
-- and sample ledger history. Before running, create 12 matching Auth users in
-- Supabase and replace each CUSTOMER-UUID-XX with its user's UUID.
-- Email values must match the emails used for the Auth users.

insert into public.profiles (user_id, full_name, email, phone, role, branch_id) values
('CUSTOMER-UUID-01','Aarav Kulkarni','customer01@example.com','9100000001','customer',(select branch_id from public.branches where branch_code='MUM001')),
('CUSTOMER-UUID-02','Ishika Prajapati','customer02@example.com','9100000002','customer',(select branch_id from public.branches where branch_code='MUM001')),
('CUSTOMER-UUID-03','Rohan Mehta','customer03@example.com','9100000003','customer',(select branch_id from public.branches where branch_code='PUN001')),
('CUSTOMER-UUID-04','Ananya Desai','customer04@example.com','9100000004','customer',(select branch_id from public.branches where branch_code='MUM001')),
('CUSTOMER-UUID-05','Vivaan Shah','customer05@example.com','9100000005','customer',(select branch_id from public.branches where branch_code='PUN001')),
('CUSTOMER-UUID-06','Diya Nair','customer06@example.com','9100000006','customer',(select branch_id from public.branches where branch_code='MUM001')),
('CUSTOMER-UUID-07','Kabir Joshi','customer07@example.com','9100000007','customer',(select branch_id from public.branches where branch_code='PUN001')),
('CUSTOMER-UUID-08','Meera Iyer','customer08@example.com','9100000008','customer',(select branch_id from public.branches where branch_code='MUM001')),
('CUSTOMER-UUID-09','Arjun Patil','customer09@example.com','9100000009','customer',(select branch_id from public.branches where branch_code='PUN001')),
('CUSTOMER-UUID-10','Sara Khan','customer10@example.com','9100000010','customer',(select branch_id from public.branches where branch_code='MUM001')),
('CUSTOMER-UUID-11','Neil Fernandes','customer11@example.com','9100000011','customer',(select branch_id from public.branches where branch_code='PUN001')),
('CUSTOMER-UUID-12','Tara Menon','customer12@example.com','9100000012','customer',(select branch_id from public.branches where branch_code='MUM001'))
on conflict (email) do update set full_name=excluded.full_name, phone=excluded.phone, branch_id=excluded.branch_id;

insert into public.accounts (account_number,user_id,branch_id,account_type,balance,status)
select d.account_number,p.user_id,b.branch_id,d.account_type::public.account_type,d.balance,d.status::public.account_status
from (values
 ('DBS200001','customer01@example.com','MUM001','savings',48500.00,'active'),
 ('DBS200002','customer02@example.com','MUM001','savings',36200.00,'active'),
 ('DBS200003','customer03@example.com','PUN001','current',94250.00,'active'),
 ('DBS200004','customer04@example.com','MUM001','savings',15800.00,'active'),
 ('DBS200005','customer05@example.com','PUN001','current',78100.00,'active'),
 ('DBS200006','customer06@example.com','MUM001','savings',22100.00,'active'),
 ('DBS200007','customer07@example.com','PUN001','savings',67900.00,'active'),
 ('DBS200008','customer08@example.com','MUM001','current',51400.00,'active'),
 ('DBS200009','customer09@example.com','PUN001','savings',19300.00,'active'),
 ('DBS200010','customer10@example.com','MUM001','savings',0.00,'frozen'),
 ('DBS200011','customer11@example.com','PUN001','current',0.00,'frozen'),
 ('DBS200012','customer12@example.com','MUM001','savings',0.00,'closed')
) as d(account_number,email,branch_code,account_type,balance,status)
join public.profiles p on p.email=d.email
join public.branches b on b.branch_code=d.branch_code
on conflict (account_number) do nothing;

insert into public.beneficiaries(user_id,nickname,beneficiary_name,beneficiary_account_number,bank_name,ifsc_code)
select p.user_id,'Project Demo Contact',q.full_name,a.account_number,'Digital Banking Demo','DBS0002001'
from (values
 ('customer01@example.com','customer02@example.com'),('customer02@example.com','customer03@example.com'),
 ('customer03@example.com','customer04@example.com'),('customer04@example.com','customer05@example.com'),
 ('customer05@example.com','customer06@example.com'),('customer06@example.com','customer07@example.com'),
 ('customer07@example.com','customer08@example.com'),('customer08@example.com','customer09@example.com'),
 ('customer09@example.com','customer10@example.com'),('customer10@example.com','customer11@example.com'),
 ('customer11@example.com','customer12@example.com'),('customer12@example.com','customer01@example.com')
) as x(owner_email,target_email)
join public.profiles p on p.email=x.owner_email
join public.profiles q on q.email=x.target_email
join public.accounts a on a.user_id=q.user_id
on conflict (user_id,beneficiary_account_number) do nothing;

-- Historical activity examples for the account list. These rows demonstrate
-- deposits and transfers; the account balances above are the current snapshot.
insert into public.transactions(from_account_id,to_account_id,amount,transaction_type,status,description,initiated_by)
select src.account_id,dst.account_id,x.amount,x.kind::public.transaction_type,x.state::public.transaction_status,x.note,src.user_id
from (values
 ('DBS200001','DBS200002',1500.00,'transfer','completed','Shared rent'),
 ('DBS200002','DBS200003',2200.00,'transfer','completed','Course materials'),
 ('DBS200003','DBS200004',5000.00,'transfer','completed','Vendor payment'),
 ('DBS200004','DBS200005',850.00,'transfer','completed','Utilities'),
 ('DBS200005','DBS200006',3200.00,'transfer','completed','Travel booking'),
 ('DBS200006','DBS200007',1100.00,'transfer','completed','Dinner settlement'),
 ('DBS200007','DBS200008',4500.00,'transfer','completed','Laptop contribution'),
 ('DBS200008','DBS200009',750.00,'transfer','completed','Subscription'),
 ('DBS200009','DBS200001',1800.00,'transfer','completed','Reimbursement'),
 ('DBS200001','DBS200003',12500.00,'transfer','completed','Semester fees'),
 ('DBS200003','DBS200005',2900.00,'transfer','completed','Project supplies'),
 ('DBS200005','DBS200007',610.00,'transfer','completed','Transport'),
 ('DBS200002','DBS200004',400.00,'transfer','failed','Demo failed transfer'),
 ('DBS200006','DBS200008',950.00,'transfer','reversed','Demo reversed transfer')
) as x(from_number,to_number,amount,kind,state,note)
join public.accounts src on src.account_number=x.from_number
join public.accounts dst on dst.account_number=x.to_number
where not exists (select 1 from public.transactions t where t.description=x.note);

insert into public.transactions(to_account_id,amount,transaction_type,status,description,initiated_by)
select a.account_id,x.amount,'deposit','completed',x.note,p.user_id
from (values
 ('DBS200001',5000.00,'Monthly salary credit'),('DBS200002',3200.00,'Scholarship credit'),
 ('DBS200003',12500.00,'Business deposit'),('DBS200004',2800.00,'Savings deposit'),
 ('DBS200005',7500.00,'Invoice settlement'),('DBS200006',2100.00,'Monthly deposit'),
 ('DBS200007',4800.00,'Part-time income'),('DBS200008',6400.00,'Client payment'),
 ('DBS200009',1700.00,'Cash deposit')
) as x(account_number,amount,note)
join public.accounts a on a.account_number=x.account_number
join public.profiles p on p.user_id=a.user_id
where not exists (select 1 from public.transactions t where t.description=x.note);
