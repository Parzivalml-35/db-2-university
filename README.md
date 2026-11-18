# Parcial Final · Bases de Datos II

**Caso 2: Clínica Veterinaria "Huellas"**. Un único script SQL que cumple los 9 requerimientos de [`apuntes/parcial_final.md`](apuntes/parcial_final.md).

Probado en **MySQL 8.4**. Requiere MySQL 8.0.16 o superior (roles y `CHECK`).

## Contenido

```
apuntes/
  parcial_final.md          Enunciado del parcial
  taller.md, *.md           Taller anterior y apuntes de clase
docs/
  MODELO.md                 Punto 1: diagrama ER (Mermaid) y normalización
  PLAN.md                   Plan de trabajo y estado
sql/
  parcial_veterinaria.sql   Script completo, secciones 1 a 9
docker-compose.yml          Plan B si el PC no tiene MySQL
```

## Cómo ejecutarlo

> ⚠ El script **borra y recrea** la BD `veterinaria_huellas` y los usuarios `admin_huellas` y `recepcion_huellas`. Se puede ejecutar varias veces. Hay que hacerlo con un usuario que pueda crear usuarios y roles (por ejemplo `root`).

### Con MySQL Workbench (opción principal)
1. Conectarse a la instancia local (`root@localhost:3306`).
2. **File → Open SQL Script…** → `sql/parcial_veterinaria.sql`.
3. Ejecutar todo con el rayo ⚡ (**Ctrl+Shift+Enter**). Cada `SELECT` abre una pestaña de resultados.
4. Para exponer por secciones: seleccionar el bloque y ejecutar con **Ctrl+Shift+Enter**, o una sentencia con **Ctrl+Enter**.

### Con Docker Desktop (plan B)
```powershell
docker compose up -d
docker compose exec mysql mysql -uroot -proot veterinaria_huellas
```
Al primer arranque carga el script. Desde Workbench también se puede conectar a `127.0.0.1:3307` con usuario `root` y contraseña `root`.
Para empezar de cero: `docker compose down` y luego `docker compose up -d`. El contenedor no tiene volumen, así que se recrea limpio.

Los usuarios del parcial se crean como `@'localhost'`. En Docker solo pueden entrar desde dentro del contenedor:
`docker compose exec mysql mysql -urecepcion_huellas -p veterinaria_huellas`.

### XAMPP / MariaDB: no recomendado
MariaDB maneja los roles distinto (`SET DEFAULT ROLE ALL TO …` no existe ahí), así que la sección 4 falla. Usa MySQL o el plan B.

## Guion de exposición

| # | Requerimiento | Solución | Qué destacar |
|---|---|---|---|
| 1 | Modelo y normalización | [`docs/MODELO.md`](docs/MODELO.md) | `consultas_medicas` resuelve la relación N:M mascotas↔veterinarios. `especies` es tabla propia (3FN). Se guarda `fecha_nacimiento` y no la edad, porque la edad es un dato derivado. |
| 2 | DDL, ≥4 tablas | 5 tablas + `historial_diagnosticos` | FK con nombre, `UNIQUE` en las claves candidatas, `CHECK` en `sexo` y `costo`. El historial no tiene FK a propósito. |
| 3 | ≥5 registros por tabla | 5 / 5 / 6 / 5 / 8 filas | Datos pensados para cada caso: un cachorro, adultos, seniors, una mascota sin fecha, un veterinario sin consultas. El historial lo llena el trigger con 5 cambios. |
| 4 | Roles y usuarios | `rol_admin` (SELECT, INSERT, UPDATE, DELETE), `rol_empleado` (SELECT, INSERT) | Sin `SET DEFAULT ROLE ALL` el rol queda asignado pero **inactivo** al iniciar sesión. |
| 5 | Trigger | `tg_respaldo_diagnostico`, `AFTER UPDATE` | `NOT (OLD.diagnostico <=> NEW.diagnostico)`: con `<>`, un cambio desde NULL no se auditaría. `USER()` y no `CURRENT_USER()`, que en un trigger devuelve el creador. |
| 6 | Función con `CASE` | `fn_etapa_vida(p_edad)` | `DETERMINISTIC NO SQL`. El NULL se evalúa primero y devuelve `Desconocido`. |
| 7 | Procedimiento con JOIN | `sp_estadisticas_veterinario(IN id, OUT nombre, OUT consultas, OUT mascotas, OUT lista)` | Con `LEFT JOIN`, un veterinario sin consultas da 0. `COUNT(DISTINCT)` cuenta mascotas distintas. Si el ID no existe, el nombre queda NULL. |
| 8 | Reporte | Consultas e ingresos por veterinario | `COUNT`, `SUM`, `GROUP BY`, `ORDER BY` y `COALESCE` para quien no tiene consultas. |
| 9 | Vista | `vw_historia_clinica` | Une las 5 tablas y reutiliza la función del punto 6. |

### Resultados esperados (clave para la demo)
- `CALL sp_estadisticas_veterinario(1, …)` → Sofía Martínez, **5** consultas, **4** mascotas (Max fue 2 veces).
- `CALL sp_estadisticas_veterinario(5, …)` → Mariana López, 0, 0, NULL.
- Historial: 5 filas. El `UPDATE` que solo cambia `costo` **no** genera fila.
- Como `recepcion_huellas`, `INSERT` funciona; `UPDATE` y `DELETE` dan `ERROR 1142`.

### Probar los roles en Workbench
Crear una conexión nueva con usuario `recepcion_huellas` y contraseña `Recep.Huellas#2026` (en el host `localhost`), y ejecutar:
```sql
SELECT CURRENT_ROLE();                                  -- `rol_empleado`@`%`
INSERT INTO veterinaria_huellas.especies (nombre) VALUES ('Tortuga');  -- OK
DELETE FROM veterinaria_huellas.especies WHERE nombre = 'Tortuga';     -- ERROR 1142
```
Las contraseñas del script son **de demostración**. Cumplen la política `validate_password`, pero al estar en el repositorio ya no son secretas.
