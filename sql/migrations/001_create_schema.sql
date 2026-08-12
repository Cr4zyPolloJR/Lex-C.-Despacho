-- Migración inicial: esquema, funciones de contexto, tablas, índices, y estructuras básicas.
-- Requiere: PostgreSQL >= 13 y extensión pgcrypto (gen_random_uuid()).

-- 0. Extensiones
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Schema
CREATE SCHEMA IF NOT EXISTS app;

-- 2. Funciones de contexto (leer variables de sesión)
CREATE OR REPLACE FUNCTION app.current_tenant() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT current_setting('app.current_tenant', true)::uuid;
$$;

CREATE OR REPLACE FUNCTION app.current_user_id() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT current_setting('app.current_user_id', true)::uuid;
$$;

CREATE OR REPLACE FUNCTION app.current_user_is_super() RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT (current_setting('app.current_user_is_super', true) = 'on')::boolean;
$$;

-- helper to check tenant match (NULL tenant_id means global)
CREATE OR REPLACE FUNCTION app.tenant_matches(tenant uuid) RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT (app.current_user_is_super()) OR (tenant IS NOT NULL AND tenant = app.current_tenant());
$$;

-- 3. Tenants, Roles, Permissions, Users
CREATE TABLE app.tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX ON app.tenants (slug);

CREATE TABLE app.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  description text,
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module text NOT NULL,
  action text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(module, action)
);

CREATE TABLE app.role_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id uuid NOT NULL REFERENCES app.roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES app.permissions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(role_id, permission_id)
);

CREATE TABLE app.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES app.tenants(id) ON DELETE SET NULL,
  username text NOT NULL,
  email text,
  full_name text,
  password_hash text,
  is_active boolean NOT NULL DEFAULT true,
  must_change_password boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_login timestamptz,
  deleted_at timestamptz,
  UNIQUE(username),
  UNIQUE(email)
);

CREATE TABLE app.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES app.roles(id) ON DELETE CASCADE,
  tenant_id uuid REFERENCES app.tenants(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, role_id, tenant_id)
);

-- 4. Business entities (initial set)
CREATE TABLE app.clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES app.tenants(id) ON DELETE CASCADE,
  name text NOT NULL,
  identifier text,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX ON app.clients (tenant_id);
CREATE INDEX ON app.clients (name);

CREATE TABLE app.cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES app.tenants(id) ON DELETE CASCADE,
  case_number text NOT NULL,
  title text,
  status text,
  priority text,
  opened_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX ON app.cases (tenant_id);
CREATE INDEX ON app.cases (case_number);

CREATE TABLE app.case_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES app.cases(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  role text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(case_id, user_id)
);

CREATE TABLE app.actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid REFERENCES app.cases(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES app.users(id) ON DELETE SET NULL,
  action_type text NOT NULL,
  summary text,
  details jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON app.actions (case_id);

CREATE TABLE app.deadlines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES app.cases(id) ON DELETE CASCADE,
  description text,
  due_date timestamptz NOT NULL,
  responsible_id uuid REFERENCES app.users(id) ON DELETE SET NULL,
  is_fatal boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'open',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON app.deadlines (due_date);

CREATE TABLE app.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid REFERENCES app.cases(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  assignee_id uuid REFERENCES app.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'todo',
  priority text,
  due_date timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 5. Documents and versions (metadata only)
CREATE TABLE app.documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES app.tenants(id) ON DELETE CASCADE,
  case_id uuid REFERENCES app.cases(id) ON DELETE SET NULL,
  uploaded_by uuid REFERENCES app.users(id) ON DELETE SET NULL,
  title text,
  mime_type text,
  size_bytes bigint,
  storage_path text NOT NULL,
  checksum text,
  current_version uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE app.document_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES app.documents(id) ON DELETE CASCADE,
  version_number int NOT NULL,
  storage_path text NOT NULL,
  mime_type text,
  size_bytes bigint,
  checksum text,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES app.users(id) ON DELETE SET NULL
);

CREATE INDEX ON app.document_versions (document_id);

-- 6. Communications, finances, evidence
CREATE TABLE app.communications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES app.tenants(id) ON DELETE CASCADE,
  case_id uuid REFERENCES app.cases(id) ON DELETE SET NULL,
  author_id uuid REFERENCES app.users(id) ON DELETE SET NULL,
  channel text,
  subject text,
  body text,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.fees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES app.tenants(id) ON DELETE CASCADE,
  case_id uuid REFERENCES app.cases(id) ON DELETE SET NULL,
  amount numeric(14,2) NOT NULL,
  currency text NOT NULL DEFAULT 'USD',
  description text,
  issued_at timestamptz NOT NULL DEFAULT now(),
  paid boolean NOT NULL DEFAULT false
);

CREATE TABLE app.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fee_id uuid REFERENCES app.fees(id) ON DELETE CASCADE,
  amount numeric(14,2) NOT NULL,
  paid_at timestamptz NOT NULL DEFAULT now(),
  method text
);

CREATE TABLE app.expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES app.tenants(id) ON DELETE CASCADE,
  case_id uuid REFERENCES app.cases(id) ON DELETE SET NULL,
  description text,
  amount numeric(14,2) NOT NULL,
  incurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.case_strategy (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES app.cases(id) ON DELETE CASCADE,
  strategy jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.case_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES app.cases(id) ON DELETE CASCADE,
  description text,
  document_id uuid REFERENCES app.documents(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 7. System settings and audit_logs
CREATE TABLE app.system_settings (
  key text PRIMARY KEY,
  value jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  user_id uuid,
  action text NOT NULL,
  object_type text,
  object_id uuid,
  summary text,
  payload jsonb,
  ip_address text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON app.audit_logs (tenant_id);
CREATE INDEX ON app.audit_logs (user_id);

-- 8. Triggers to maintain updated_at
CREATE OR REPLACE FUNCTION app.trigger_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Attach to tables that have updated_at
CREATE TRIGGER clients_set_updated_at BEFORE UPDATE ON app.clients FOR EACH ROW EXECUTE FUNCTION app.trigger_set_updated_at();
CREATE TRIGGER cases_set_updated_at BEFORE UPDATE ON app.cases FOR EACH ROW EXECUTE FUNCTION app.trigger_set_updated_at();
CREATE TRIGGER deadlines_set_updated_at BEFORE UPDATE ON app.deadlines FOR EACH ROW EXECUTE FUNCTION app.trigger_set_updated_at();
CREATE TRIGGER tasks_set_updated_at BEFORE UPDATE ON app.tasks FOR EACH ROW EXECUTE FUNCTION app.trigger_set_updated_at();
CREATE TRIGGER documents_set_updated_at BEFORE UPDATE ON app.documents FOR EACH ROW EXECUTE FUNCTION app.trigger_set_updated_at();
CREATE TRIGGER system_settings_set_updated_at BEFORE UPDATE ON app.system_settings FOR EACH ROW EXECUTE FUNCTION app.trigger_set_updated_at();

-- 9. Ensure tenant_id is present where required using CHECK constraints
ALTER TABLE app.clients ADD CONSTRAINT clients_tenant_not_null CHECK (tenant_id IS NOT NULL);
ALTER TABLE app.cases ADD CONSTRAINT cases_tenant_not_null CHECK (tenant_id IS NOT NULL);
ALTER TABLE app.documents ADD CONSTRAINT documents_tenant_not_null CHECK (tenant_id IS NOT NULL);
ALTER TABLE app.communications ADD CONSTRAINT communications_tenant_not_null CHECK (tenant_id IS NOT NULL);
ALTER TABLE app.fees ADD CONSTRAINT fees_tenant_not_null CHECK (tenant_id IS NOT NULL);
ALTER TABLE app.expenses ADD CONSTRAINT expenses_tenant_not_null CHECK (tenant_id IS NOT NULL);

-- End of migration 001
