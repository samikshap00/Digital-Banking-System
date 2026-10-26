# Digital Banking System Setup Guide

This single guide covers Supabase setup, sample data, role permissions, the recovery demonstration, and starting the frontend.

## 1. Supabase project

The connected project is `Digital Banking System` (`qzxsozkisgpzflgzovyz`). Its schema and RLS policies have already been applied. The live database currently has 2 customer profiles, 6 accounts (4 active, 1 frozen, 1 closed), 2 beneficiaries, and 4 sample transactions. Do not rerun the schema or policies just to load more demo users.

## 2. Create the database

For a fresh project only, open **SQL Editor**. Choose **New query**, paste each complete file, and run in this order:

1. `supabase/schema.sql`
2. `supabase/policies.sql`
3. `supabase/seed.sql`

These updated scripts are written to be rerun for this project. The schema defines customer, staff, and admin functions; the policies restrict direct table access and protect role fields.

## 3. Create Supabase Auth users

Open **Authentication → Users → Add user → Create new user**.

Create 12 additional customer users with these emails. These bring the project to 14 customer profiles including the 2 that already exist:

```text
customer01@example.com
customer02@example.com
customer03@example.com
customer04@example.com
customer05@example.com
customer06@example.com
customer07@example.com
customer08@example.com
customer09@example.com
customer10@example.com
customer11@example.com
customer12@example.com
```

Also create one staff user and one admin user, such as `staff@example.com` and `admin@example.com`. Set demo passwords and copy each user's UUID from the Users table.

## 4. Link the 12 customers and load demonstration data

Open `supabase/demo_customers.sql`. Replace `CUSTOMER-UUID-01` through `CUSTOMER-UUID-12` with the corresponding UUIDs from Supabase Auth. Confirm that each email in the SQL matches the Auth user's email, then run the script in SQL Editor. It is safe to rerun after UUIDs are filled in; existing account numbers and beneficiary links are skipped.

The script creates 12 customer profiles and accounts: 9 active, 2 frozen, and 1 closed. It also creates beneficiaries and sample deposits, transfers, failed, and reversed transactions.

Create profiles for the staff and admin Auth users in SQL Editor. Replace the UUID and personal values in this example:

```sql
insert into public.profiles (user_id, full_name, email, phone, role, branch_id)
values
('STAFF-UUID','Demo Staff','staff@example.com','9200000001','staff',(select branch_id from public.branches where branch_code='MUM001')),
('ADMIN-UUID','Demo Administrator','admin@example.com','9200000002','admin',(select branch_id from public.branches where branch_code='MUM001'));
```

Use phone numbers not already present in `profiles`; the phone field is unique.

## 5. Connect the frontend

The frontend is already connected to this Supabase project using its public publishable key. The URL/key are in `frontend/app.js`. If you use a different project, open **Project Settings → API Keys** and replace those two values.

Open `frontend/app.js` and replace the first two constants:

```js
const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR-PUBLISHABLE-KEY';
```

Use the publishable key in browser code. Never put the database password, secret key, service-role key, or management token in the frontend.

## 6. Start the frontend with PowerShell

Open PowerShell and enter the project directory:

```powershell
cd "C:\C Drive\Coding\DBMSMicroProject\Digital Banking SYS\Digital-Banking-System"
```

Start a local static server:

```powershell
py -m http.server 5500 --directory frontend
```

Open `http://localhost:5500` in your browser. Keep PowerShell running while you use the site. Press `Ctrl+C` to stop the server.

Alternatively, in VS Code open `frontend/index.html`, right-click it, and choose **Open with Live Server**.

## 7. Demonstrate each role

### Customer

Sign in with a customer Auth user. The customer workspace shows only the signed-in customer's accounts, status, balances, beneficiaries, and transactions. Transfers are available only from active accounts.

### Staff

Sign in with the staff user. Staff see account records with masked account numbers. Staff may freeze an active account or reactivate a frozen account. They cannot change balances, assign roles, or close accounts.

### Admin

Sign in with the admin user. The administrator console shows system totals, account-state counts, masked account controls, beneficiary records with masked destination numbers, and an account-provisioning form. Admins can remove beneficiary records and set accounts active, frozen, or closed.

## 8. Demonstrate transaction recovery

Sign in as a customer with an active source account. Enter an active destination account number and a positive amount, then click **Run interrupted-transfer demo**.

The database function simulates a debit and pending ledger insert inside a nested transaction block, then raises a controlled interruption. PostgreSQL rolls back both financial changes. The outer function records a separate recovery event with the amount, masked destination, and rollback detail. The page confirms unchanged balances and displays the event as **Interrupted transfer · rolled back** in recent activity.

For SQL evidence, open `supabase/demo_queries.sql`. Run its recovery evidence queries before and after the UI demonstration. The account balances and interrupted financial-ledger row count should remain unchanged; the user's `recovery_demo_events` history should gain one event.

## 9. Capture project evidence

Capture screenshots of:

- Supabase tables and Auth users
- RLS policies and the SQL Editor
- Customer dashboard with account states and beneficiaries
- Recovery-demo message and unchanged balances
- Staff account review showing masked numbers and limited actions
- Admin metrics, role management, and account provisioning
- A successful transfer and resulting ledger row

## Troubleshooting

- **No accounts appear:** make sure the profile UUID is the same as the Auth UUID and that the customer seed script ran.
- **Duplicate phone error:** use a phone value not already in `public.profiles`.
- **No staff/admin panel:** confirm the profile role is exactly `staff` or `admin`, then sign out and back in.
- **Account summary permission error:** rerun the updated `schema.sql`, then `policies.sql`.
- **Transfer destination not found:** use an active account number exactly as stored.
- **Frontend connection error:** check the project URL and publishable key in `frontend/app.js`.
- **Page does not load when opened directly:** use the local server or Live Server rather than double-clicking the HTML file.
