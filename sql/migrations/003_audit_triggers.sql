-- Migración 003: funciones y triggers de auditoría

-- Function to insert audit log; runs with SECURITY DEFINER so it can write even if RLS would block
CREATE OR REPLACE FUNCTION app.audit_log_insert()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user uuid;
  v_tenant uuid;
BEGIN
  BEGIN
    v_user := app.current_user_id();
  EXCEPTION WHEN others THEN
    v_user := NULL;
  END;

  BEGIN
    v_tenant := app.current_tenant();
  EXCEPTION WHEN others THEN
    v_tenant := NULL;
  END;

  INSERT INTO app.audit_logs(tenant_id, user_id, action, object_type, object_id, summary, payload, ip_address, created_at)
  VALUES (
    v_tenant,
    v_user,
    TG_OP || ' on ' || TG_TABLE_NAME,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id)::uuid,
    substring(coalesce(NEW::text, OLD::text) for 1000),
    jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW)),
    null,
    now()
  );

  RETURN NULL;
END;
$$;

-- Attach trigger to key tables
CREATE TRIGGER audit_clients AFTER INSERT OR UPDATE OR DELETE ON app.clients
  FOR EACH ROW EXECUTE FUNCTION app.audit_log_insert();

CREATE TRIGGER audit_cases AFTER INSERT OR UPDATE OR DELETE ON app.cases
  FOR EACH ROW EXECUTE FUNCTION app.audit_log_insert();

CREATE TRIGGER audit_documents AFTER INSERT OR UPDATE OR DELETE ON app.documents
  FOR EACH ROW EXECUTE FUNCTION app.audit_log_insert();

CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON app.users
  FOR EACH ROW EXECUTE FUNCTION app.audit_log_insert();

-- Note: triggers defined with SECURITY DEFINER to allow audit insert despite RLS
