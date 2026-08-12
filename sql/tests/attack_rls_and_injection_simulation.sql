-- attack_rls_and_injection_simulation.sql
-- These tests simulate "attacker" actions to validate protections.
-- They are intended to be run as lex_app role (or in a session that simulates the runtime role).
-- Expected outcomes are commented: failures (permission denied) indicate protections are in place.

-- 0) Precondition: run as lex_app (or run "SET ROLE lex_app;" in a test connection where allowed)
-- Attempt 1: Try to elevate super flag via SET LOCAL (simulated injection) and read another tenant's clients
-- NOTE: If lex_app cannot modify roles/tenants, SET LOCAL alone does not grant new object privileges,
-- but it can influence RLS if policies rely solely on GUCs. We must verify both.

-- Simulate attacker setting the GUC (would require injection vulnerability)
SET LOCAL app.current_user_is_super = 'on';

-- Attempt to SELECT clients across tenants (should NOT return other tenant rows if role lacks permissions)
SELECT id, tenant_id, name FROM app.clients LIMIT 50;
-- EXPECTED: only rows matching current_tenant (or empty) — and no ability to read protected tenant data.

-- Attempt 2: Try to modify roles table (should be denied for lex_app)
UPDATE app.roles SET slug = 'compromised' WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
-- EXPECTED: permission denied (lex_app must not be able to update roles)

-- Attempt 3: Try to set user's tenant_id (escalation)
UPDATE app.users SET tenant_id = '11111111-1111-1111-1111-111111111111' WHERE username = 'attacker';
-- EXPECTED: permission denied or RLS check fails.

-- Attempt 4: Attempt to create a new role (should be denied)
CREATE ROLE evil_role LOGIN PASSWORD 'x';
-- EXPECTED: permission denied (must be superuser)

-- Attempt 5: Verify audit logs recorded attempts if any DML succeeded
SELECT * FROM app.audit_logs WHERE created_at > now() - interval '1 hour' ORDER BY created_at DESC LIMIT 20;
