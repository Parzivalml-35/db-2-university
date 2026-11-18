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
  GUIA_EXPOSICION.md        Qué repasar: conceptos, errores, simulacro de preguntas
  PLAN.md                   Plan de trabajo y estado
sql/
  parcial_veterinaria.sql   Script completo, secciones 1 a 9
  banco_consultas.sql       Consultas y código que el profesor podría pedir en vivo
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
| 1 | Modelo y normalización | [`docs/MODELO.md`](docs/MODELO.md) | Dos N:M: mascotas↔veterinarios (`consultas_medicas`) y consultas↔tratamientos (`detalle_consultas`, PK compuesta). La especie sale de la raza (3FN). No se guardan la edad ni el total de la consulta, porque son datos derivados. |
| 2 | DDL, ≥4 tablas | 9 tablas + `historial_diagnosticos` | FK con nombre, `UNIQUE` en las claves candidatas, `CHECK` en `sexo` y precios. El historial no tiene FK a propósito. |
| 3 | ≥5 registros por tabla | Entre 5 y 16 filas por tabla | Datos pensados para cada caso: cachorro, adultos, seniors, una mascota sin fecha, un veterinario sin consultas, un tratamiento nunca aplicado y una consulta cobrada a un precio anterior. El historial lo llena el trigger con 5 cambios. |
| 4 | Roles y usuarios | `rol_admin` (SELECT, INSERT, UPDATE, DELETE), `rol_empleado` (SELECT, INSERT) | Sin `SET DEFAULT ROLE ALL` el rol queda asignado pero **inactivo** al iniciar sesión. |
| 5 | Trigger | `tg_respaldo_diagnostico`, `AFTER UPDATE` | `NOT (OLD.diagnostico <=> NEW.diagnostico)`: con `<>`, un cambio desde NULL no se auditaría. `USER()` y no `CURRENT_USER()`, que en un trigger devuelve el creador. |
| 6 | Función con `CASE` | `fn_etapa_vida(p_edad)` | `DETERMINISTIC NO SQL`. El NULL se evalúa primero y devuelve `Desconocido`. |
| 7 | Procedimiento con JOIN | `sp_estadisticas_veterinario(IN id, OUT nombre, OUT especialidad, OUT consultas, OUT mascotas, OUT lista)` | `INNER JOIN` con especialidades y `LEFT JOIN` con consultas: un veterinario sin consultas da 0. `COUNT(DISTINCT)` cuenta mascotas distintas. Si el ID no existe, el nombre queda NULL. |
| 8 | Reportes | Ingresos por veterinario · tratamientos más aplicados | `COUNT(DISTINCT)` (el JOIN con el detalle repite cada consulta), `SUM`, `GROUP BY`, `ORDER BY` y `COALESCE` para quien no tiene datos. |
| 9 | Vista | `vw_historia_clinica` | Une 8 tablas, reutiliza la función del punto 6 y calcula el total de cada consulta con una tabla derivada. |

### Resultados esperados (clave para la demo)
- `CALL sp_estadisticas_veterinario(1, …)` → Sofía Martínez, Medicina general, **5** consultas, **4** mascotas (Max fue 2 veces).
- `CALL sp_estadisticas_veterinario(5, …)` → Mariana López, Odontología, 0, 0, NULL.
- Historial: 5 filas. El `UPDATE` que solo cambia `motivo` **no** genera fila.
- Reporte 8.1: Sofía Martínez, 455.000 de ingresos. Suma de todas las consultas: 785.000.
- Como `recepcion_huellas`, `INSERT` funciona; `UPDATE` y `DELETE` dan `ERROR 1142`.

### Probar los roles en Workbench
Crear una conexión nueva con usuario `recepcion_huellas` y contraseña `Recep.Huellas#2026` (en el host `localhost`), y ejecutar:
```sql
SELECT CURRENT_ROLE();                                  -- `rol_empleado`@`%`
INSERT INTO veterinaria_huellas.especies (nombre) VALUES ('Tortuga');  -- OK
DELETE FROM veterinaria_huellas.especies WHERE nombre = 'Tortuga';     -- ERROR 1142
```
Las contraseñas del script son **de demostración**. Cumplen la política `validate_password`, pero al estar en el repositorio ya no son secretas.
