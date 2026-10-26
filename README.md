# Digital Banking System Database

DBMS micro-project for a Digital Banking System built on Supabase (PostgreSQL), with a lightweight browser frontend.

## Project structure

- `supabase/schema.sql` - relational schema, constraints, indexes, views, and helper functions
- `supabase/seed.sql` - safe demonstration data for branches, customers, accounts, beneficiaries, and transactions
- `supabase/policies.sql` - Supabase Auth and Row Level Security policies for customer, staff, and admin access
- `supabase/demo_queries.sql` - SQL commands for the report and live demonstration
- `frontend/` - static frontend using the Supabase JavaScript client from a CDN
- `report/` - report source and generated report deliverables

## Quick start

1. Follow `SUPABASE_SETUP.md` to create the project and test users.
2. Run `schema.sql`, `policies.sql`, and `seed.sql` in the Supabase SQL Editor.
3. Replace the two placeholders at the top of `frontend/app.js` with the project URL and publishable/anon key.
4. Open `frontend/index.html` through a local static server.

The browser UI supports dashboard viewing, balance lookup, money transfer, beneficiary creation, transaction history, and staff account review. For a production system, never expose the service-role key in the browser; use only the publishable/anon key with RLS enabled.

## Demo roles

- Customer: sees only their own profile, accounts, beneficiaries, and transactions.
- Staff: can review customer and account information, and update account status through controlled policies.
- Admin: can manage operational records and access all project tables.

## Report status

The report follows the supplied college format: 15-20 pages, Times New Roman, justified body text, 1.5 spacing, diagrams, database operations, screenshots, conclusion, and future scope.
