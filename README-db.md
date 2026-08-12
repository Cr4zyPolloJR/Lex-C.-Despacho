# FASE 01 — Diseño e implementación de la base de datos (Lex Despacho)

Contenido
- sql/migrations/001_create_schema.sql
- sql/migrations/002_rls_policies.sql
- sql/migrations/003_audit_triggers.sql
- sql/seeds/001_seed_initial_manual.sql
- sql/hardening/*
- sql/tests/attack_rls_and_injection_simulation.sql
- docker-compose.yml

Cómo ejecutar localmente (desarrollo)
1. Crear un directorio de trabajo y clonar repo.
2. Editar docker-compose.yml para ajustar credenciales si las necesitas.
3. Ejecutar:
   docker compose up -d
   (El contenedor inicializará la DB y ejecutará los scripts en sql/ si están montados en /docker-entrypoint-initdb.d)

Ejecución manual de migraciones (recomendada)
- Con psql local:
  psql -h localhost -U postgres -d lexdb -f sql/migrations/001_create_schema.sql
  psql -h localhost -U postgres -d lexdb -f sql/migrations/002_rls_policies.sql
  psql -h localhost -U postgres -d lexdb -f sql/migrations/003_audit_triggers.sql

NOTA: Reemplaza los PLACEHOLDER_HASH_* con hashes Argon2 generados por el backend.

Notas de seguridad
- Reemplaza los PLACEHOLDER_PASSWORDS en sql/hardening con valores seguros fuera del repo.
- El backend debe fijar las siguientes variables de sesión antes de operar:
  SET LOCAL app.current_tenant = '<tenant_uuid>';
  SET LOCAL app.current_user_id = '<user_uuid>';
  SET LOCAL app.current_user_is_super = 'on'|'off';

Pruebas
- Se incluyen scripts de test SQL en sql/tests/ para validar aislamiento y RLS.

Siguientes pasos
- Integrar migrator (Flyway, Alembic o similar) en el pipeline local.
- Implementar el backend FastAPI que fija variables de sesión y aplica Argon2 y manejo seguro de documentos.
