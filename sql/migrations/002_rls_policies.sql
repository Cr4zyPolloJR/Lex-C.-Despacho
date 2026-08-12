-- Migración 002: activar RLS y crear políticas por tabla sensibles

-- Default: ensure RLS is turned on where needed

-- CLIENTS
ALTER TABLE app.clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY clients_select_policy ON app.clients
  FOR SELECT USING (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY clients_insert_policy ON app.clients
  FOR INSERT WITH CHECK (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY clients_update_policy ON app.clients
  FOR UPDATE USING (
    app.tenant_matches(tenant_id)
  ) WITH CHECK (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY clients_delete_policy ON app.clients
  FOR DELETE USING (
    app.tenant_matches(tenant_id)
  );

-- CASES
ALTER TABLE app.cases ENABLE ROW LEVEL SECURITY;

CREATE POLICY cases_select_policy ON app.cases
  FOR SELECT USING (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY cases_insert_policy ON app.cases
  FOR INSERT WITH CHECK (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY cases_update_policy ON app.cases
  FOR UPDATE USING (
    app.tenant_matches(tenant_id)
  ) WITH CHECK (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY cases_delete_policy ON app.cases
  FOR DELETE USING (
    app.tenant_matches(tenant_id)
  );

-- DOCUMENTS
ALTER TABLE app.documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY documents_select_policy ON app.documents
  FOR SELECT USING (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY documents_insert_policy ON app.documents
  FOR INSERT WITH CHECK (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY documents_update_policy ON app.documents
  FOR UPDATE USING (
    app.tenant_matches(tenant_id)
  ) WITH CHECK (
    app.tenant_matches(tenant_id)
  );

CREATE POLICY documents_delete_policy ON app.documents
  FOR DELETE USING (
    app.tenant_matches(tenant_id)
  );

-- DEADLINES, TASKS, COMMUNICATIONS, FEES, EXPENSES: enable RLS similarly
ALTER TABLE app.deadlines ENABLE ROW LEVEL SECURITY;
CREATE POLICY deadlines_policy ON app.deadlines FOR ALL USING (app.tenant_matches((SELECT tenant_id FROM app.cases WHERE id = app.deadlines.case_id LIMIT 1)));

ALTER TABLE app.tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY tasks_policy ON app.tasks FOR ALL USING (
  (app.current_user_is_super()) OR
  (EXISTS (SELECT 1 FROM app.cases c WHERE c.id = app.tasks.case_id AND c.tenant_id = app.current_tenant()))
);

ALTER TABLE app.communications ENABLE ROW LEVEL SECURITY;
CREATE POLICY communications_policy ON app.communications FOR ALL USING (app.tenant_matches(tenant_id));

ALTER TABLE app.fees ENABLE ROW LEVEL SECURITY;
CREATE POLICY fees_policy ON app.fees FOR ALL USING (app.tenant_matches(tenant_id));

ALTER TABLE app.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY expenses_policy ON app.expenses FOR ALL USING (app.tenant_matches(tenant_id));

-- USERS: more nuanced (users can see themselves; tenant admins see users of their tenant; super admin sees all)
ALTER TABLE app.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_select_policy ON app.users
  FOR SELECT USING (
    (app.current_user_is_super())
    OR (id = app.current_user_id())
    OR (tenant_id = app.current_tenant())
  );

CREATE POLICY users_update_policy ON app.users
  FOR UPDATE USING (
    (app.current_user_is_super())
    OR (id = app.current_user_id())
    OR (tenant_id = app.current_tenant())
  ) WITH CHECK (
    (app.current_user_is_super())
    OR (id = app.current_user_id())
    OR (tenant_id = app.current_tenant())
  );

CREATE POLICY users_insert_policy ON app.users
  FOR INSERT WITH CHECK (
    (app.current_user_is_super()) OR (tenant_id = app.current_tenant())
  );

CREATE POLICY users_delete_policy ON app.users
  FOR DELETE USING (
    (app.current_user_is_super()) OR (tenant_id = app.current_tenant())
  );

-- ROLE and PERMISSION modifications must be controlled: At DB level, only super admins can modify system-level roles.
ALTER TABLE app.roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY roles_modify_policy ON app.roles FOR ALL USING (app.current_user_is_super());

ALTER TABLE app.role_permissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY role_permissions_policy ON app.role_permissions FOR ALL USING (app.current_user_is_super());
