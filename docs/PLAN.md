# Plan: Taller de Funciones y Procedimientos (MySQL) listo para exponer en Windows

## Contexto
Hay que resolver `taller.md` (3 funciones + 3 procedimientos sobre `university.users`) y exponerlo en un PC Windows de la universidad (probablemente con MySQL + Workbench; plan B: instalar MySQL o Docker Desktop). El repo debe ser autocontenido: que en cualquier PC se pueda crear la BD, cargar las rutinas y mostrar las pruebas. Los apuntes (`bases_de_datos_ii_sentencias_avanzadas.md`, `gesti_n_de_usuarios_y_permisos_en_mysql.md`) son la referencia de estilo: `DELIMITER $$`, `DROP ... IF EXISTS` antes de crear, prefijo `p_` en parámetros, `SELECT ... INTO`, `CALL` + `@variables`.

**Problema clave:** ningún archivo trae el `CREATE TABLE users` ni los datos. Se reconstruye a partir de lo que usan los apuntes: `user_id, name, surname, age, init_date, email, company_id`; Marcela Hernandez = ID 1, Claudia = ID 3, y debe haber varios 'Fernandez'.

## Estructura del repo (carpeta actual `db-class/`)
```
README.md                      ← guía de exposición + cómo montarlo en Windows
.gitignore / .gitattributes    ← `* text=auto` para que Windows no rompa finales de línea
apuntes/                       ← los 3 .md existentes (git mv, no se modifican)
sql/
  00_esquema_y_datos.sql       ← CREATE DATABASE IF NOT EXISTS university; tabla users + INSERTs
  funciones/
    01_es_mayor_edad.sql
    02_antiguedad_usuario.sql
    03_formato_correo.sql
  procedimientos/
    01_get_user_stats.sql
    02_count_by_surname.sql
    03_check_email_status.sql
  todo_en_uno.sql              ← todo lo anterior concatenado (plan de rescate en vivo)
docker-compose.yml             ← plan B: MySQL 8 que carga todo_en_uno.sql al arrancar
```
Cada script de ejercicio: encabezado con el enunciado → `USE university;` → `DROP ... IF EXISTS` → `DELIMITER $$ … END$$ DELIMITER ;` → bloque de pruebas con resultado esperado en comentarios. Se pueden ejecutar solos y en cualquier orden (tras el 00).

## Datos de prueba (diseñados para que cada ejercicio muestre todos sus casos)
~10 filas: ID 1 Marcela Hernandez (con email), ID 3 Claudia, 3 personas 'Fernandez', alguien con `age` NULL, un menor de 17, alguien con exactamente 18, uno con `email` NULL, uno con `surname` NULL, fechas `init_date` variadas.

## Soluciones y decisiones a explicar en la exposición
| Ejercicio | Implementación | Punto de discusión |
|---|---|---|
| `es_mayor_edad(p_age INT)` → VARCHAR | `IF p_age IS NULL … ELSEIF p_age >= 18 'SÍ' ELSE 'NO'` | `DETERMINISTIC NO SQL`: no lee tablas, así que `READS SQL DATA` sería incorrecto |
| `antiguedad_usuario(p_init_date DATE)` → INT | `TIMESTAMPDIFF(YEAR, p_init_date, NOW())` | Usa `NOW()` → técnicamente `NOT DETERMINISTIC`; con `NO SQL` evita el error 1418 igualmente |
| `formato_correo(p_name, p_surname)` → VARCHAR | `LOWER(CONCAT(p_name,'.',p_surname,'@universidad.edu.co'))` | Mencionar tildes/espacios y surname NULL (CONCAT con NULL devuelve NULL) |
| `get_user_stats(IN p_user_id, OUT p_age, OUT p_email)` | `SELECT age, email INTO …` | Prueba con ID 1; qué pasa con un ID inexistente (OUT queda NULL + warning 1329) |
| `count_by_surname(IN p_surname, OUT p_total)` | `SELECT COUNT(*) INTO …` | Prueba 'Fernandez'; COUNT siempre devuelve 1 fila, nunca falla el INTO |
| `check_email_status(IN p_user_id, OUT p_status)` | `IF(email IS NULL,'Pendiente','Completo')` vía `SELECT … INTO` | Nombre `p_status` exigido por el enunciado |

Erratas del enunciado que se anotan en el README: `REES SQL DATA` → `READS SQL DATA`; el tip de "siempre DETERMINISTIC + READS SQL DATA" no aplica a todas las funciones (se explica por qué).

## Seguridad / riesgo en el PC de la universidad
`00_esquema_y_datos.sql` hace `DROP TABLE IF EXISTS users` dentro de `university`. Si ese PC ya tiene una `university` de clase, la tabla se pierde. El README y el encabezado del script lo advierten; se recomienda revisar `SHOW DATABASES;` antes.

## Autoría
Claude escribe los 6 scripts completos. Después de cada uno explica línea por línea las decisiones (características de la función, `SELECT … INTO`, manejo de NULL) para que el usuario pueda defenderlos al exponer. El esquema reconstruido es un supuesto: si aparece el `CREATE TABLE` original, se reemplaza.

## Pasos de implementación (por capas, con confirmación en cada punto marcado)
1. `git init` y `.gitignore`/`.gitattributes`; mover apuntes a `apuntes/` con `git mv`.
2. `sql/00_esquema_y_datos.sql`.
3. Las 3 funciones, luego los 3 procedimientos.
4. Generar `todo_en_uno.sql` (concatenación de 00 + 6 scripts).
5. `docker-compose.yml` (imagen `mysql:8.4`, monta `todo_en_uno.sql` en `/docker-entrypoint-initdb.d/`).
6. `README.md`: requisitos, montaje en Windows (Workbench: *File → Open SQL Script → ⚡ ejecutar*; descargar ZIP desde GitHub si no hay git), guion de exposición por ejercicio, plan B Docker, erratas.
7. **Commit(s)** (con tu confirmación) — sugerencia: 1) estructura + apuntes, 2) esquema y datos, 3) funciones, 4) procedimientos, 5) README + docker.
8. Tú creas el repo vacío en GitHub y me pasas la URL → `git remote add origin` + `git push` (con tu confirmación).

## Verificación
- Local con Docker (está instalado aquí): `docker compose up -d` y ejecutar `todo_en_uno.sql` y cada script suelto con el cliente `mysql` del contenedor; comprobar que las salidas coinciden con los "resultados esperados" comentados. Ejecutarlo dos veces para confirmar que es re-ejecutable. Luego `docker compose down` (sin `-v` salvo que confirmes).
- Lo que debes probar tú en Windows antes de exponer: abrir `todo_en_uno.sql` en Workbench y ejecutarlo completo; ejecutar un script individual; si no hay MySQL, `docker compose up` en Docker Desktop.
- No verificable desde aquí: la versión exacta de MySQL/Workbench del PC de la universidad.

---

## Estado (actualizado 2026-11-17)

### Hecho
- Pasos 1 a 8 completos: estructura, esquema y datos, 3 funciones, 3 procedimientos, `todo_en_uno.sql`, `docker-compose.yml`, README, commits y primer push a GitHub.
- Verificado en contenedores temporales con **MySQL 8.4.11** y **MariaDB 11**: todas las salidas coinciden con los resultados esperados y el script se puede re-ejecutar. Binlog activo (`@@log_bin = 1`) sin error 1418.

### Pendiente
- [ ] Probar en el PC Windows de la universidad: abrir `sql/todo_en_uno.sql` en Workbench y ejecutarlo completo; luego un script individual con Ctrl+Enter.
- [ ] Si no hay MySQL: `docker compose up -d` en Docker Desktop (no se probó con compose, solo con `docker run`).
- [ ] phpMyAdmin/XAMPP: instrucción del README sin probar.
- [ ] Decidir si los `apuntes/` deben quedar en un repo público (contienen contraseñas de ejemplo de clase).

### Decisiones tomadas (para defender en la exposición)
- Las 3 funciones usan `NO SQL` (no leen tablas), no `READS SQL DATA` como sugiere el tip del taller.
- `antiguedad_usuario` es `NOT DETERMINISTIC` porque depende de `NOW()`.
- `formato_correo` usa `CONCAT_WS` para que un apellido NULL no anule el correo (el enunciado no lo especifica).
- El esquema de `users` es reconstruido: si aparece el `CREATE TABLE` original de clase, reemplazar `sql/00_esquema_y_datos.sql` y ejecutar `./generar_todo_en_uno.sh`.

### Hallazgos fuera de alcance (en los apuntes, sin corregir)
- `GRANT USAGE … IDENTIFIED BY` no funciona en MySQL 8 (usar `ALTER USER`).
- `GRANT FILE ON wordpress_db.*` falla: `FILE` solo es global (`*.*`).
- Trigger `tg_email`: `OLD.email <> NEW.email` no detecta cambios desde/hacia NULL; usar `NOT (OLD.email <=> NEW.email)`.
