-- 004_default_privileges_for_future_objects.sql
-- Set default privileges so that objects created by lex_migrator are manageable,
-- and lex_app only receives limited privileges via explicit grants.

-- Should be executed by lex_migrator (or superuser) BEFORE running migrations in CI:
ALTER DEFAULT PRIVILEGES FOR ROLE lex_migrator IN SCHEMA app GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO lex_app;
ALTER DEFAULT PRIVILEGES FOR ROLE lex_migrator IN SCHEMA app GRANT USAGE, SELECT ON SEQUENCES TO lex_app;
