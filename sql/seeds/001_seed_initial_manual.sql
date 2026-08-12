-- 001_seed_initial_manual.sql
-- Manual-safe seeds: tenants, roles and users WITHOUT plaintext password hashes.

INSERT INTO app.tenants (id, name, slug, metadata) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Cr4zySolutions Platform', 'cr4zysolutions', '{"system": true}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO app.tenants (id, name, slug) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Lex Despacho', 'lex-despacho')
ON CONFLICT (id) DO NOTHING;

INSERT INTO app.roles (id, name, slug, description, is_system) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Super Admin', 'super_admin', 'Cr4zySolutions super admin role', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Administrador del Despacho', 'admin_despacho', 'Administrador del despacho', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Abogado', 'abogado', 'Abogado'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Auxiliar', 'auxiliar', 'Personal auxiliar'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Cliente', 'cliente', 'Acceso cliente')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO app.users (id, tenant_id, username, email, full_name, password_hash, must_change_password, is_active) VALUES
  ('22222222-2222-2222-2222-222222222222', NULL, 'cr4zysolutions', 'ops@cr4zysolutions.local', 'Cr4zySolutions', NULL, true, true),
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'rebeca', 'rebeca@lex.local', 'Rebeca Cuevas', NULL, true, true)
ON CONFLICT (username) DO NOTHING;

INSERT INTO app.user_roles (id, user_id, role_id, tenant_id) VALUES
  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', NULL),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111')
ON CONFLICT DO NOTHING;
