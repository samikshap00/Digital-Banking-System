-- Queries to demonstrate DBMS concepts in the report and viva.

-- 1. Read a customer's account summary.
select * from public.account_summary where user_id = auth.uid();

-- 2. Show the five latest transactions for the signed-in customer.
select t.transaction_id, t.amount, t.transaction_type, t.status, t.description, t.created_at
from public.transactions t
where t.initiated_by = auth.uid()
   or exists (
     select 1 from public.accounts a
     where a.account_id in (t.from_account_id, t.to_account_id)
       and a.user_id = auth.uid()
   )
order by t.created_at desc limit 5;

-- 3. Atomic transfer through a stored procedure.
select public.transfer_money('SOURCE-ACCOUNT-UUID', 'DESTINATION-ACCOUNT-NUMBER', 500.00, 'College fee payment');

-- 4. Aggregation: total transfer value by day.
select date(created_at) as transaction_day, sum(amount) as total_value, count(*) as transaction_count
from public.transactions
where transaction_type = 'transfer' and status = 'completed'
group by date(created_at) order by transaction_day desc;

-- 5. Join: staff view of branch-wise balances.
select b.branch_name, count(a.account_id) as accounts, sum(a.balance) as total_balance
from public.branches b left join public.accounts a on a.branch_id = b.branch_id
group by b.branch_id, b.branch_name order by total_balance desc nulls last;

-- 6. Update a user's own profile phone number.
update public.profiles set phone = '9000000010' where user_id = auth.uid();
