-- Queries to demonstrate DBMS concepts in the report and viva.

-- 1. Read the account summary. RLS filters rows for the signed-in user.
select * from public.account_summary order by opened_on desc;

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

-- 3. Atomic transfer through the authenticated frontend RPC.
-- Run the transfer from the customer UI so auth.uid() comes from the customer session.
-- Do not call this as a plain SQL Editor query because the SQL Editor has no customer JWT:
-- select public.transfer_money('SOURCE-ACCOUNT-UUID', 'DESTINATION-ACCOUNT-NUMBER', 500.00, 'College fee payment');

-- 4. Aggregation: total transfer value by day.
select date(created_at) as transaction_day, sum(amount) as total_value, count(*) as transaction_count
from public.transactions
where transaction_type = 'transfer' and status = 'completed'
group by date(created_at) order by transaction_day desc;

-- 5. Join: staff view of branch-wise balances.
select b.branch_name, count(a.account_id) as accounts, sum(a.balance) as total_balance
from public.branches b left join public.accounts a on a.branch_id = b.branch_id
group by b.branch_id, b.branch_name order by total_balance desc nulls last;

-- 6. Customer profile update. Replace the UUID with a real user ID when running as
-- a trusted SQL Editor administrator. The browser customer can update only its
-- own full_name and phone columns under RLS.
update public.profiles set phone = '9100000099' where user_id = 'CUSTOMER-UUID';

-- 7. Recovery demo evidence. Record these values, run the recovery demo in the
-- customer UI, then run the query again. Balances and financial ledger rows remain
-- unchanged; the separate recovery event is recorded for customer activity history.
select a.account_number, a.balance, a.status
from public.accounts a
where a.account_number in ('SOURCE-ACCOUNT-NUMBER','DESTINATION-ACCOUNT-NUMBER')
order by a.account_number;

select count(*) as interrupted_demo_rows
from public.transactions
where description = 'RECOVERY DEMO - intentionally interrupted';

select event_id, amount, to_account_masked, status, detail, created_at
from public.recovery_demo_events
where user_id = auth.uid()
order by created_at desc limit 5;

-- 8. Role and masked account view. Run while signed in as staff/admin in the app.
select masked_account_number, account_type, balance, status, branch_name
from public.account_summary order by status, masked_account_number;
