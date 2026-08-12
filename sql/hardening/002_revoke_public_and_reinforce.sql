-- 002_revoke_public_and_reinforce.sql
REVOKE ALL ON ALL TABLES IN SCHEMA app FROM PUBLIC;
REVOKE ALL ON SCHEMA app FROM PUBLIC;

-- Secure audit function: re-create with safe search_path and set owner to postgres
-- (Replace function body if you already have one; ensure owner = postgres)
CREATE OR REPLACE FUNCTION app.audit_log_insert()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user uuid;
  v_tenant uuid;
BEGIN
  PERFORM set_config('search_path', 'app,pg_temp', true);
  BEGIN
    v_user := current_setting('app.current_user_id', true)::uuid;
  EXCEPTION WHEN others THEN
    v_user := NULL;
  END;
  BEGIN
    v_tenant := current_setting('app.current_tenant', true)::uuid;
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
    NULL,
    now()
  );
  RETURN NULL;
END;
$$;
ALTER FUNCTION app.audit_log_insert() OWNER TO postgres;
