# Digital Banking System Database

A DBMS micro-project that demonstrates a role-aware digital banking workflow using Supabase Auth, PostgreSQL, Row Level Security (RLS), and a browser frontend.

## Project contents

- `supabase/schema.sql` — tables, constraints, indexes, views, and database functions.
- `supabase/seed.sql` — sample branch data.
- `supabase/demo_customers.sql` — additional customer, account, beneficiary, and transaction data. Replace the Auth UUID placeholders before running it.
- `supabase/policies.sql` — RLS policies and role-aware database permissions.
- `supabase/demo_queries.sql` — SQL examples for exploring the schema and demonstrating DBMS operations.
- `frontend/` — the Supabase-connected browser application.
- `report/build_report.py` — builds the project report and regenerates the ER and relational schema diagrams.
- `report/schema_diagrams.py` — source for the diagrams.

## Setup and run

1. In Supabase, create or select the project and apply the SQL files in this order: `schema.sql`, `seed.sql`, then `policies.sql`.
2. Create the required users in Supabase Auth and link their UUIDs to the matching profiles. For the extra demo customers, replace the placeholders in `demo_customers.sql` with real Auth UUIDs before running it.
3. Set the Supabase project URL and publishable key in the frontend configuration if they are not already set for your project. Never put a service-role key in browser code.
4. Start a local static server from the project directory and open `frontend/index.html` through that server.
5. Sign in with a user created in Supabase Auth to see the workspace for that profile’s role.

## Role boundaries

- **Customer:** views their own accounts, beneficiaries, and activity; transfers funds from eligible accounts.
- **Staff:** reviews masked account records and can freeze an active account or reactivate a frozen account. Staff cannot change balances, close accounts, or change roles.
- **Admin:** views system-wide metrics, manages account states, provisions accounts for existing customers, and reviews or removes beneficiary records.

RLS remains the database-level access control. The frontend uses the publishable key and cannot grant itself permissions that the database policies do not allow.

## Demonstrations

- Run a valid transfer and inspect the resulting balances and transaction row.
- Run the interrupted-transfer demo and confirm that the financial changes roll back while a separate recovery event appears in activity history.
- Sign in as customer, staff, and admin to compare each role’s permitted views and actions.
- Use `demo_queries.sql` to inspect tables, joins, aggregates, and access behavior.

## Report and diagrams

Run `report/build_report.py` with Python and the `python-docx` and Pillow packages installed. The report build creates the diagrams under `report/assets/` and places them on separate landscape pages so their labels remain readable. Primary keys are underlined in both diagrams. In the relational schema, each foreign-key field uses `→` followed by the referenced table and key.
