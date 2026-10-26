# Digital Banking System Database

## Report plan

This report will follow the supplied DBMS Micro Project format and target 15-20 pages. The report will document a working Supabase PostgreSQL database, the application frontend, role-based access, SQL operations, and observed results.

## Evidence to capture after Supabase setup

- Supabase table editor showing the five main tables
- SQL Editor showing schema creation and demonstration queries
- Auth user list with customer, staff, and admin accounts
- RLS policies enabled on tables
- Customer dashboard and transfer form
- Staff review screen
- Successful transaction row and updated account balances

## Important implementation note

The frontend transfer handler should pass the destination account UUID to `p_to_account` after the beneficiary/account lookup UI is completed. The current demo UI is intentionally scaffolded for the report workflow and should be connected to the live project before final screenshots.
