# Supabase Setup and Demonstration Guide

## 1. Create the project

Create a new Supabase project and copy its project URL and publishable anon key from Project Settings > API. The publishable anon key is safe for the browser when Row Level Security is enabled. Never place the service-role key in the frontend.

## 2. Run the SQL files in order

Open the Supabase SQL Editor and run these files in order:

1. `supabase/schema.sql`
2. `supabase/policies.sql`
3. `supabase/seed.sql`

The schema creates branches, profiles, accounts, beneficiaries, transactions, the account summary view, and the transfer function. The policy script enables RLS and creates customer, staff, and admin access rules.

## 3. Create demo users

In Authentication > Users, create three email/password users:

- Customer: `customer@example.com`
- Staff: `staff@example.com`
- Admin: `admin@example.com`

Copy each generated user UUID. Use those UUIDs in the commented profile inserts in `supabase/seed.sql`, changing the names and emails if required. Then create at least two accounts for the customer and one account for a second customer. The account number should be unique, for example `DBS100001`.

## 4. Connect the frontend

At the top of `frontend/app.js`, replace:

```js
const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR-PUBLISHABLE-ANON-KEY';
```

Use the project URL and publishable anon key from Supabase. The demo preview remains available before live credentials are configured.

## 5. Run the frontend

Use any local static server in the project folder, then open the `frontend` directory. For example, a simple editor extension or local web server can serve `frontend/index.html`. Do not open the service-role key in the browser.

## 6. Demonstration sequence

1. Open the demo preview to explain the interface.
2. Sign in as the customer and show only that customer's accounts.
3. Enter a destination account number and transfer a small amount.
4. Refresh the dashboard and show the changed balance and transaction history.
5. Attempt a transfer larger than the available balance and show the database error.
6. Sign in as staff and show the staff review section.
7. In the SQL Editor, show the transaction row, the account summary view, and the branch-wise aggregation query.
