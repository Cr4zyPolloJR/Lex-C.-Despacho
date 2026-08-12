-- 001_create_migration_and_app_roles.sql
-- Run AS SUPERUSER (postgres). This creates:
--  - lex_migrator: role to run migrations (owner of schema / can create objects)
--  - lex_app: runtime role with minimal privileges
-- Adjust passwords/secrets offline; DO NOT store secrets in repo.

CREATE ROLE lex_migrator LOGIN PASSWORD '<<MIGRATOR_STRONG_PASSWORD_PLACEHOLDER>>' NOINHERIT;
CREATE ROLE lex_app LOGIN PASSWORD '<<APP_STRONG_PASSWORD_PLACEHOLDER>>' NOINHERIT;

-- If schema exists, make lex_migrator owner (safe to run after migrations)
ALTER SCHEMA IF EXISTS app OWNER TO lex_migrator;

REVOKE ALL ON SCHEMA app FROM PUBLIC;
GRANT USAGE ON SCHEMA app TO lex_app;
GRANT USAGE ON SCHEMA app TO lex_migrator;

GRANT CREATE ON SCHEMA app TO lex_migrator;

-- Runtime privileges (explicit grants)
GRANT SELECT, INSERT, UPDATE, DELETE ON app.clients TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.cases TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.actions TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.deadlines TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.tasks TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.documents TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.document_versions TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.communications TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.fees TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.payments TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.expenses TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.case_strategy TO lex_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.case_evidence TO lex_app;

GRANT SELECT ON app.roles TO lex_app;
GRANT SELECT ON app.permissions TO lex_app;

REVOKE INSERT, UPDATE, DELETE ON app.roles FROM lex_app;
REVOKE INSERT, UPDATE, DELETE ON app.role_permissions FROM lex_app;
REVOKE INSERT, UPDATE, DELETE ON app.user_roles FROM lex_app;
REVOKE INSERT, UPDATE, DELETE ON app.tenants FROM lex_app;

GRANT ALL ON SCHEMA app TO lex_migrator;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO lex_migrator;
