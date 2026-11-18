# Taller: Funciones y Procedimientos Almacenados en MySQL

Solución del taller de **Bases de Datos II** sobre la base de datos `university` y la tabla `users`:
3 funciones (cálculos que se usan dentro de un `SELECT`) y 3 procedimientos (se llaman con `CALL` y devuelven datos por parámetros `OUT`).

Probado en **MySQL 8.4** y **MariaDB 11**.

## Contenido

```
apuntes/                         Enunciado del taller y apuntes de clase
sql/
  00_esquema_y_datos.sql         Crea la BD university, la tabla users y 10 filas de prueba
  funciones/
    01_es_mayor_edad.sql
    02_antiguedad_usuario.sql
    03_formato_correo.sql
  procedimientos/
    01_get_user_stats.sql
    02_count_by_surname.sql
    03_check_email_status.sql
  todo_en_uno.sql                Todo lo anterior en un solo archivo (generado)
docker-compose.yml               Plan B si el PC no tiene MySQL
generar_todo_en_uno.sh           Regenera todo_en_uno.sql (Linux / Git Bash)
```

Cada script se puede ejecutar por separado (después del `00`). Contiene el enunciado, el `DROP ... IF EXISTS`, la rutina y las pruebas, con el resultado esperado en comentarios.

## Montarlo en el PC de la universidad (Windows)

> ⚠ `00_esquema_y_datos.sql` **borra y recrea** la tabla `users` de `university`. Si el PC ya tiene esa BD con datos de otra persona, revísalo antes con `SHOW DATABASES;`.

### 1. Descargar el proyecto
- **Con git:** `git clone <URL-del-repo>`
- **Sin git:** en GitHub, botón **Code → Download ZIP** y descomprimir.

### 2a. Con MySQL Workbench (opción principal)
1. Abrir Workbench y conectarse a la instancia local (normalmente `root@localhost:3306`).
2. **File → Open SQL Script…** → `sql/todo_en_uno.sql`.
3. Ejecutar todo con el rayo ⚡ (**Ctrl+Shift+Enter**). Cada `SELECT` abre una pestaña de resultados.
4. Para exponer ejercicio por ejercicio, abrir el script individual y ejecutar cada sentencia con **Ctrl+Enter**.

Workbench entiende `DELIMITER $$` sin configurar nada.

### 2b. Con XAMPP / phpMyAdmin
Pestaña **SQL** → pegar el contenido del script → **Continuar**. Si se queja del delimitador, escribir `$$` en el campo *Delimitador* y quitar las líneas `DELIMITER`.

### 2c. Con Docker Desktop (plan B)
```powershell
docker compose up -d
docker compose exec mysql mysql -uroot -proot university
```
Al primer arranque carga `todo_en_uno.sql` automáticamente. Desde Workbench también se puede conectar a `127.0.0.1:3307` con usuario `root` y contraseña `root` (credenciales de demostración, solo locales).
Para reiniciar desde cero: `docker compose down` y luego `docker compose up -d`. El contenedor no guarda volumen propio, así que se recrea limpio.

## Guion de exposición

### Modelo de datos
El enunciado no trae el `CREATE TABLE`, así que se reconstruyó con las columnas que usan los apuntes: `user_id, name, surname, age, init_date, email, company_id`. Los datos se diseñaron para mostrar todos los casos de cada ejercicio: Marcela Hernandez es el ID 1, hay 3 'Fernandez', alguien con `age` NULL, un menor, alguien con exactamente 18 años y usuarios sin email, sin apellido o sin fecha de inicio.

### Funciones
| Función | Idea clave | Características |
|---|---|---|
| `es_mayor_edad(p_age)` | `IF / ELSEIF / ELSE`. El NULL se revisa **primero**, porque `NULL >= 18` no es verdadero ni falso y caería en `'NO'`. | `DETERMINISTIC NO SQL` |
| `antiguedad_usuario(p_init_date)` | `TIMESTAMPDIFF(YEAR, fecha, NOW())` cuenta **años completos**. | `NOT DETERMINISTIC NO SQL` |
| `formato_correo(p_name, p_surname)` | `LOWER(CONCAT(CONCAT_WS('.', nombre, apellido), '@universidad.edu.co'))`. `CONCAT_WS` salta los NULL; con `CONCAT` un apellido NULL daría NULL. | `DETERMINISTIC NO SQL` |

**¿Por qué no `READS SQL DATA` en todas, como dice el tip del taller?** Esa característica le dice a MySQL que la función *lee tablas*, y ninguna de estas lo hace: solo trabajan con sus parámetros. Lo correcto es `NO SQL`. Con el binary log activo (opción por defecto en MySQL 8), basta con declarar `DETERMINISTIC`, `NO SQL` o `READS SQL DATA` para evitar el **error 1418**. Por eso `antiguedad_usuario` puede ser honestamente `NOT DETERMINISTIC`: depende de `NOW()` y la misma fecha da otro resultado el año siguiente.

### Procedimientos
| Procedimiento | Prueba | Resultado |
|---|---|---|
| `get_user_stats(IN p_user_id, OUT p_age, OUT p_email)` | `CALL get_user_stats(1, @edad, @correo);` | `25`, `marcela.hernandez@gmail.com` |
| `count_by_surname(IN p_surname, OUT p_total)` | `CALL count_by_surname('Fernandez', @total);` | `3` |
| `check_email_status(IN p_user_id, OUT p_status)` | `CALL check_email_status(3, @estado);` | `Pendiente` |

Los tres usan `SELECT ... INTO`, que exige que la consulta devuelva **como máximo una fila**:
- Filtrar por `user_id` (PRIMARY KEY) lo garantiza.
- `COUNT(*)` siempre devuelve exactamente una fila, aunque sea `0`.
- Si el ID no existe, las variables `OUT` quedan en `NULL` y MySQL emite el warning 1329 (*No data*). El script de `get_user_stats` lo demuestra con el ID 999.

### Erratas del enunciado
- `REES SQL DATA` → debe ser `READS SQL DATA`.
- El tip "usar `DETERMINISTIC` y `READS SQL DATA`" no aplica a estas funciones (ver arriba).

## Mantenimiento
Si modificas un script individual, regenera el archivo combinado:
```bash
./generar_todo_en_uno.sh
```
