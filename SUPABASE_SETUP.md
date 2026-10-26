# Supabase Setup and Demonstration Guide

## 1. Create the project

The connected project is `Digital Banking System` (`qzxsozkisgpzflgzovyz`). The schema, RLS policies, and a starter dataset are already installed. The frontend is configured with this project's URL and public publishable key. Never place the service-role key in the frontend.

## 2. Run the SQL files in order

Open the Supabase SQL Editor and run these files in order:

1. `supabase/schema.sql`
2. `supabase/policies.sql`
3. `supabase/seed.sql`

The schema creates branches, profiles, accounts, beneficiaries, transactions, a recovery-demo event table, a masked account summary view, and role-guarded functions. The interrupted-transfer function rolls financial changes back and stores a separate event for the customer's activity history. The policy script enables RLS and applies distinct customer, staff, and admin permissions.

## 3. Create demo users

In Authentication > Users, create three email/password users:

- Customer: `customer@example.com`
- Staff: `staff@example.com`
- Admin: `admin@example.com`

Copy each generated user UUID. Use those IDs in the profile inserts in `supabase/seed.sql` or the profile insert examples below. To create the full dataset, create 12 Auth customers using `customer01@example.com` through `customer12@example.com`, replace the matching UUID placeholders in `supabase/demo_customers.sql`, and run that script. It creates 12 accounts across active, frozen, and closed states, 12 beneficiaries, and sample transactions. Staff and admin users should have their own matching profiles with the corresponding roles.

## 4. Connect the frontend

The frontend is already connected to this project. If switching projects, replace the constants at the top of `frontend/app.js`:

```js
const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR-PUBLISHABLE-ANON-KEY';
```

The frontend is connected to the project's URL and publishable key. The application requires Supabase Auth sign-in and has no demo preview.

## 5. Run the frontend

Use any local static server in the project folder, then open the `frontend` directory. For example, a simple editor extension or local web server can serve `frontend/index.html`. Do not open the service-role key in the browser.

## 6. Demonstration sequence

1. Sign in as a customer and show personal accounts, beneficiaries, and transactions.
2. Use an active account and click **Run interrupted-transfer demo** with a valid destination and amount. Show the rolled-back event in recent activity while confirming the balance and financial ledger remain unchanged.
4. Make a regular transfer and show the updated balance and transaction history.
5. Sign in as staff. Show masked account numbers and freeze/reactivate actions; closed accounts have no staff action.
6. Sign in as admin. Show system metrics, beneficiary review/removal, account status management, and account provisioning.
7. In the SQL Editor, show the masked account summary and branch-wise aggregation.
