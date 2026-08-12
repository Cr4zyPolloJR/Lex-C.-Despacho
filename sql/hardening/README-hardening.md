# Hardening & Separation of Responsibilities (Resumen operativo)

Objetivo
- Proveer scripts y pasos para separar roles y endurecer la base de datos local, minimizando el impacto de una potencial inyección SQL en la aplicación.

Principios clave
1. Separación de responsabilidades:
   - lex_migrator: usa para ejecutar migraciones y operaciones de mantenimiento (no usado por la app runtime).
   - lex_app: usado por la aplicación en producción; tiene permisos mínimos (NO puede modificar roles, tenants, ni user_roles).
2. No almacenar secretos en el repo. Reemplazar placeholders con valores seguros off-repo.
3. Las funciones SECURITY DEFINER deben pertenecer a un rol de confianza (postgres o migration owner) y fijar search_path internamente.
4. Seeds de cuentas administrativas se crean sin hashes; la contraseña se establece mediante un procedimiento seguro posterior.
5. RLS sigue siendo la última barrera para datos sensibles.

Instrucciones de ejecución (sugeridas)
1. Como superuser (postgres):
   - Ejecutar 001_create_migration_and_app_roles.sql
2. Ejecutar migraciones (ej. 001_create_schema.sql, 002_rls_policies.sql, 003_audit_triggers.sql) COMO lex_migrator (o como superuser una sola vez).
3. Ejecutar 004_default_privileges... para asegurar privilegios por defecto.
4. Ejecutar seeds MANUALMENTE (001_seed_initial_manual.sql) para crear tenants/usuarios sin hashes.
5. Con el usuario administrador, establecer hashes Argon2 fuera del repo con la CLI de administrador o script seguro.
6. Ejecutar scripts de prueba (sql/tests/attack_rls_and_injection_simulation.sql) conectándose como lex_app para validar que no sea posible escalar privilegios.

Recomendaciones operativas
- Nunca arranques la app runtime con superuser DB credentials.
- Mantén la cuenta lex_migrator fuera del pool de la app; usarla solo en la pipeline de migraciones.
- Habilita pg_hba.conf para permitir únicamente conexiones locales o de confianza.
- Revisa y bloquea endpoints del backend que construyan SQL dinámico; aplica parametrización.
- Ejecuta pruebas de RLS tras cada cambio en políticas y migraciones.
