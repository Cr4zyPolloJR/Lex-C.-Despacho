-- 003_restrict_set_config_usage.sql
-- Defensive pattern: we cannot fully prevent SET LOCAL being executed by a session that already has SQL injection,
-- but we can minimize privileges of the connection role (lex_app) so that even if a malicious SET is executed,
-- the role cannot perform privileged administrative changes.

-- Ensure lex_app is NOINHERIT (created above). NOINHERIT prevents it from automatically getting privileges from roles it might be a member of.
-- Already created as NOINHERIT above. Verify:
ALTER ROLE lex_app NOINHERIT;

-- Additionally: prevent lex_app from creating functions or executing certain commands by not granting CREATE or USAGE on pg_catalog objects.
-- (No direct GRANT to do here; the lack of superuser privileges suffices.)
