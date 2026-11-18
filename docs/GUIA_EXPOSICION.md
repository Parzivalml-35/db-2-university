# Guía de exposición · Parcial Final, Veterinaria "Huellas"

Qué repasar para presentar la BD y responder lo que pida el profesor en vivo.
El código de cada tema está en [`sql/banco_consultas.sql`](../sql/banco_consultas.sql), señalado como **[A1]**, **[D4]**… y la solución del parcial en [`sql/parcial_veterinaria.sql`](../sql/parcial_veterinaria.sql).

---

## 1. Antes de salir a exponer (checklist)

- [ ] Ejecutar `sql/parcial_veterinaria.sql` completo en Workbench (⚡) y refrescar el panel *Schemas*.
- [ ] Abrir también `sql/banco_consultas.sql` en otra pestaña, **sin ejecutarlo completo**. Se usa por bloques.
- [ ] Tener una segunda conexión creada como `recepcion_huellas` para demostrar los permisos.
- [ ] Atajos:
  - **Ctrl+Enter**: ejecuta la sentencia donde está el cursor.
  - **Ctrl+Shift+Enter**: ejecuta la selección o todo el archivo.
  - **Ctrl+B**: formatea el SQL.
- [ ] Si algo sale mal, volver a ejecutar el script del parcial: deja todo como al inicio.

---

## 2. Guion (unos 5 minutos)

1. **El caso:** una clínica que registra propietarios, sus mascotas, los veterinarios, las consultas y los tratamientos aplicados en cada una.
2. **El modelo** ([`docs/MODELO.md`](MODELO.md)): 9 tablas.
   - Tres catálogos sencillos: `especies`, `especialidades` y `tratamientos`.
   - Dos cadenas: `especies → razas → mascotas` y `especialidades → veterinarios`.
   - **Dos N:M:**
     - mascotas↔veterinarios, a través de `consultas_medicas`;
     - consultas↔tratamientos, a través de `detalle_consultas`, con PK compuesta.
3. **Normalización:**
   - La especie sale de la raza, así que `mascotas` no guarda `especie_id`.
   - No se guardan la edad ni el total de la consulta: se calculan.
   - `precio_aplicado` conserva lo que se cobró aunque el precio cambie.
4. **Integridad:** PK `AUTO_INCREMENT`, FK con nombre, `UNIQUE` en documento, email, tarjeta y nombres, y `CHECK` en sexo y precios.
5. **Seguridad:** 2 roles y 2 usuarios. Demo: `recepcion_huellas` hace `INSERT` pero el `DELETE` le da **1142**.
6. **Trigger:** se hace un `UPDATE` del diagnóstico y se muestra `historial_diagnosticos`.
7. **Función:** `SELECT nombre, fn_etapa_vida(…) FROM mascotas`.
8. **Procedimiento:** `CALL sp_estadisticas_veterinario(1, @v, @e, @c, @m, @l)` y `SELECT @v, @e, @c, @m, @l`. Probar también con el 5 (sin consultas, devuelve 0) y el 999 (no existe, devuelve NULL).
9. **Reportes:** ingresos por veterinario y tratamientos más aplicados.
10. **Vista:** `SELECT * FROM vw_historia_clinica`. Une 8 tablas y calcula el total de cada consulta.

---

## 3. Conceptos que debes poder explicar

### Modelo y normalización
- **PK (clave primaria):** identifica cada fila; es única y no admite NULL.
- **PK compuesta:** la PK está formada por dos columnas, como `(consulta_id, tratamiento_id)`. Impide repetir el mismo par.
- **FK (clave foránea):** columna que apunta a la PK de otra tabla y garantiza que el padre exista (**integridad referencial**).
- **`UNIQUE`:** no se repite, pero puede ser NULL. Se usa para claves candidatas, como el documento.
- **Cardinalidad:**
  - 1:N se implementa con una FK en el lado N.
  - N:M necesita una tabla intermedia; aquí hay dos: `consultas_medicas` y `detalle_consultas`.
- **1FN:** valores atómicos y sin grupos repetidos. La lista de tratamientos de una consulta pasa a filas en `detalle_consultas`.
- **2FN:** sin dependencias parciales de una PK compuesta. `precio_aplicado` depende de la consulta **y** del tratamiento.
- **3FN:** sin dependencias transitivas. Por eso `mascota → raza → especie` guarda solo `raza_id`, y la especialidad es tabla propia.
- **Datos derivados:** no se guardan la edad ni el total de la consulta, porque se pueden calcular y guardarlos permite que queden inconsistentes.

### Lenguajes SQL
| Tipo | Para qué | Sentencias |
|---|---|---|
| **DDL** | Definir la estructura | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` |
| **DML** | Manipular datos | `SELECT`, `INSERT`, `UPDATE`, `DELETE` |
| **DCL** | Controlar permisos | `GRANT`, `REVOKE` |
| **TCL** | Controlar transacciones | `START TRANSACTION`, `COMMIT`, `ROLLBACK` |

### Usuarios, privilegios y roles [B]
- **Cuenta = `'usuario'@'host'`:** `'ana'@'localhost'` y `'ana'@'%'` son cuentas distintas.
- **Niveles de privilegio:** global `*.*` → BD `bd.*` → tabla → columna → rutina.
- **Rol:** conjunto de privilegios con nombre. Se asigna con `GRANT 'rol' TO usuario`, pero **no queda activo** hasta `SET DEFAULT ROLE ALL` (o hasta un `SET ROLE` dentro de la sesión).
- **Principio de mínimo privilegio:** cada usuario recibe solo lo que necesita (recepción puede consultar y registrar, pero no borrar).
- **`FLUSH PRIVILEGES`:** solo hace falta si se editan las tablas `mysql.*` a mano. `GRANT` y `CREATE USER` aplican al instante.
- **Ver permisos:** `SHOW GRANTS FOR usuario USING 'rol'` muestra los permisos que el usuario hereda del rol.

### Consultas [C–F]
- **Orden de evaluación:** `FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT`.
- **`WHERE` vs `HAVING`:** `WHERE` filtra filas antes de agrupar; `HAVING` filtra grupos y es el único que puede usar `COUNT` o `SUM`.
- **`COUNT(*)` vs `COUNT(col)` vs `COUNT(DISTINCT col)`:** cuenta filas, cuenta los no NULL y cuenta los valores distintos [E1].
- **La trampa del JOIN con el detalle:** al unir consultas con `detalle_consultas`, cada consulta aparece una vez por tratamiento. `COUNT(*)` da 16 y no 8. Para contar consultas se usa `COUNT(DISTINCT c.consulta_id)`; `SUM(precio_aplicado)` sí queda bien [E3].
- **NULL:** se pregunta con `IS NULL`, porque `= NULL` nunca es verdadero. `<=>` es la igualdad segura con NULL.
- **Tipos de JOIN:**
  - **`INNER`:** solo las filas con pareja en ambas tablas.
  - **`LEFT`:** todas las de la izquierda; las que no tienen pareja salen con NULL.
  - **Anti-join:** `LEFT … WHERE derecha.id IS NULL` [D6, D7].
- **Seguir las FK:** para llegar de mascota a especie hay que pasar por `razas` [D2, D11].
- **Subconsulta:** escalar (1 valor), de lista (`IN`), `EXISTS` o tabla derivada en el `FROM` [F2].
- **`UNION` vs `UNION ALL`:** `UNION` quita duplicados; `UNION ALL` no, y es más rápido.

### Funciones vs procedimientos [I]
| | Función | Procedimiento |
|---|---|---|
| Se invoca con | dentro de un `SELECT` | `CALL` |
| Devuelve | 1 valor con `RETURN` | resultados (`SELECT`) y/o parámetros `OUT`/`INOUT` |
| Parámetros | solo de entrada | `IN`, `OUT`, `INOUT` |
| Modifica datos | no debería | sí puede [I9] |

- **`DELIMITER $$`:** el cuerpo tiene varios `;`. Si no se cambia el delimitador, el cliente cortaría el `CREATE` en el primer `;`.
- **`DETERMINISTIC`:** la misma entrada produce siempre la misma salida. Una función que usa `NOW()` o `RAND()` no lo es.
- **Acceso a datos:** `NO SQL` (no toca tablas), `READS SQL DATA` (lee tablas), `MODIFIES SQL DATA` (escribe) y `CONTAINS SQL` (el valor por defecto).
- **Error 1418:** con el binlog activo, una función debe declarar `DETERMINISTIC`, `NO SQL` o `READS SQL DATA`.
- **Por qué `fn_etapa_vida` es `DETERMINISTIC NO SQL`:** solo usa su parámetro. Compárala con `ej_total_consulta` [I3], que suma el detalle y por eso es `READS SQL DATA`.
- **Variables:** `DECLARE v_x` es una variable local del bloque; `@x` es una variable de la sesión, y así se recogen los `OUT`.
- **Modificar una rutina:** no hay `ALTER` para el cuerpo; se hace `DROP … IF EXISTS` y luego `CREATE`.

### Triggers [J]
- **Momento:**
  - **`BEFORE`:** se ejecuta antes del cambio; puede modificar `NEW` o cancelar la operación con `SIGNAL` [J1].
  - **`AFTER`:** se ejecuta después; sirve para auditar lo que ya se guardó [J2, J3].
- **`OLD` y `NEW`:** `INSERT` solo tiene `NEW`, `UPDATE` tiene ambos y `DELETE` solo tiene `OLD`.
- **¿Por qué el nuestro usa `<=>`?** `diagnostico` admite NULL, y con `<>` un cambio desde NULL da NULL y no se audita. En [J2], `precio` es `NOT NULL`, así que ahí `<>` sí es seguro.
- **¿Por qué `USER()` y no `CURRENT_USER()`?** En un trigger, `CURRENT_USER()` devuelve el creador (DEFINER), no a quien hizo el cambio.
- **Restricciones:** un trigger no puede modificar su propia tabla (error 1442) ni hacer `COMMIT` o `ROLLBACK`.

### Vistas [K]
- **Qué es:** un `SELECT` guardado con nombre. No almacena datos; se recalcula cada vez que se consulta.
- **Para qué sirve:** simplificar consultas repetidas (nuestra vista evita escribir 8 JOIN) y **dar acceso sin exponer las tablas** (`GRANT SELECT` sobre la vista) [B4].
- **Limitación:** una vista con `GROUP BY`, `DISTINCT` o agregaciones no se puede actualizar.

### Transacciones e índices [G, H]
- **Transacción (ACID):** los cambios se guardan todos o ninguno.
  - `ROLLBACK` deshace también lo que escribió un trigger.
  - El DDL hace `COMMIT` implícito.
  - El `AUTO_INCREMENT` no se devuelve.
- **Orden por las FK:** se inserta del padre al hijo (raza → mascota → consulta → detalle) y se borra al revés [G1, G4].
- **`INSERT … SELECT`:** inserta filas a partir de una consulta. Con él se copia el precio actual como `precio_aplicado` [G1, I9].
- **`DELETE` vs `TRUNCATE` vs `DROP`:**
  - `DELETE` borra filas, admite `WHERE` y dispara triggers.
  - `TRUNCATE` vacía la tabla y reinicia el `AUTO_INCREMENT`.
  - `DROP` elimina la tabla completa.
- **Índice:** acelera `WHERE`, `JOIN` y `ORDER BY`, pero ocupa espacio y hace más lentas las escrituras. PK, `UNIQUE` y FK crean el suyo automáticamente.
- **`EXPLAIN`:** muestra el plan de ejecución. `type ALL` significa que recorre toda la tabla; `range`/`ref` significa que usa un índice.

---

## 4. Errores que pueden salir en vivo

| Código | Significado | Ejemplo / solución |
|---|---|---|
| **1064** | Error de sintaxis | Falta una coma, una palabra mal escrita, o falta `DELIMITER $$` antes de un `CREATE PROCEDURE` |
| **1142** | No tienes ese permiso | `recepcion_huellas` intentando `DELETE` [B9] |
| **1451** | No se puede borrar el padre: tiene hijos | Borrar un propietario con mascotas o una consulta con detalle; primero se borran los hijos [G4] |
| **1452** | El padre no existe | Insertar una mascota con `propietario_id = 99` |
| **1062** | Valor duplicado en PK o `UNIQUE` | `INSERT INTO especies VALUES ('Perro')`, o repetir un tratamiento en la misma consulta (PK compuesta) |
| **3819** | Viola un `CHECK` | Precio negativo |
| **1175** | *Safe update mode* de Workbench | `UPDATE`/`DELETE` sin `WHERE` por clave. Agregar `WHERE id = …` o `SET SQL_SAFE_UPDATES = 0` |
| **1418** | Función sin característica declarada (con binlog) | Agregar `DETERMINISTIC`, `NO SQL` o `READS SQL DATA` |
| **1329** | `SELECT … INTO` no encontró filas | Las variables `OUT` quedan en NULL |
| **1644** | Error propio lanzado con `SIGNAL` | El trigger de validación de email [J1] |
| **1046** | No hay BD seleccionada | Falta `USE veterinaria_huellas;` |

Todos los de la tabla, salvo 1064, 1175, 1418, 1329 y 1046, se pueden provocar a propósito con las líneas `-- DEMO ERROR` del banco.

---

## 5. Simulacro: pedidos probables del profesor

Intenta escribirlo sin mirar y luego compara con el bloque indicado.

| # | "Muéstrame / hazme…" | Bloque |
|---|---|---|
| 1 | …las tablas de la BD y la estructura de `mascotas` | A2, A3 |
| 2 | …qué llaves foráneas tiene la BD | A4 |
| 3 | …los usuarios del servidor y los permisos de cada rol | B1, B3 |
| 4 | …un usuario nuevo que solo pueda ver la vista | B4 |
| 5 | …quítale un permiso / cámbiale la contraseña | B5, B7 |
| 6 | …las mascotas que empiezan por L / los tratamientos entre dos precios | C3, C5 |
| 7 | …las consultas de octubre | C4 |
| 8 | …los 3 tratamientos más caros | C8 |
| 9 | …cada mascota con su dueño (INNER JOIN) | D1 |
| 10 | …mascota con raza, especie y dueño (4 tablas) | D2 |
| 11 | …qué tratamientos se aplicaron en una consulta | D4 |
| 12 | …todos los veterinarios, aunque no tengan consultas | D5 |
| 13 | …los veterinarios que no han atendido / los tratamientos nunca usados | D6, D7, F4 |
| 14 | …solo las consultas de los perros | D11 |
| 15 | …cuántas consultas e ingresos hay por especie | E4 |
| 16 | …las mascotas que han venido más de una vez (HAVING) | E5 |
| 17 | …los ingresos por mes con un total | E7, E8 |
| 18 | …las consultas cuyo total supera el promedio | F2 |
| 19 | …registra una mascota con su consulta y tratamientos, y luego deshazlo | G1, G4 |
| 20 | …intenta borrar un propietario con mascotas, y explícame el error | G (1451) |
| 21 | …agrega una columna o una tabla nueva | H1, H2 |
| 22 | …crea un índice y muéstrame `EXPLAIN` | H4 |
| 23 | …una función con `IF` / con `CASE` / que lea tablas | I1, I3, sección 6 del parcial |
| 24 | …un procedimiento con `IN` y `OUT` / con `INOUT` | I6, I8 |
| 25 | …un trigger que valide antes de insertar / que audite precios / que guarde lo borrado | J1, J2, J3 |
| 26 | …otra vista y cómo borrarla | K2, K3 |
| 27 | …cómo sacas un respaldo de la BD | L |

---

## 6. Preguntas "trampa" con respuesta corta

- **¿Por qué `mascotas` no tiene `especie_id`?** Porque la especie depende de la raza (dependencia transitiva). Si estuvieran las dos, una mascota podría quedar como raza "Siamés" y especie "Perro" a la vez.
- **¿No es redundante `precio_aplicado` si ya está `tratamientos.precio`?** No. Uno es el precio actual de lista y el otro es lo que se cobró ese día. La consulta 1 se cobró a 45.000 y hoy la consulta general vale 50.000 [D4, G3].
- **¿Por qué no guardas el total de la consulta?** Es un dato derivado: se calcula con `SUM(precio_aplicado)`. Guardarlo permitiría que no coincidiera con el detalle.
- **¿Por qué la PK de `detalle_consultas` es compuesta?** Porque cada fila es la combinación de una consulta y un tratamiento, y no tiene sentido repetir el mismo tratamiento en la misma consulta (error 1062).
- **¿Por qué tu función no es `READS SQL DATA`, como dice el enunciado?** El enunciado pide declarar `DETERMINISTIC` **o** `READS SQL DATA`. La nuestra es `DETERMINISTIC` y además `NO SQL`, porque no lee tablas.
- **¿Por qué `historial_diagnosticos` no tiene FK?** Para que la auditoría sobreviva aunque se borre la consulta.
- **¿Qué pasa si llamas al procedimiento con un veterinario que no existe?** Devuelve nombre y especialidad en NULL y contadores en 0. Una agregación sin `GROUP BY` siempre devuelve 1 fila.
- **¿Por qué el procedimiento combina `INNER` y `LEFT JOIN`?** `INNER` con especialidades, porque todo veterinario tiene una. `LEFT` con consultas, para que un veterinario sin consultas devuelva 0.
- **¿Por qué `AFTER` y no `BEFORE` en el trigger?** Porque solo audita lo que realmente se guardó, y no necesita modificar `NEW`.
- **¿Qué hace `SET DEFAULT ROLE ALL`?** Activa los roles asignados en cada inicio de sesión. Sin él, `CURRENT_ROLE()` devuelve `NONE` y el usuario no tiene permisos.
- **¿Por qué los usuarios son `@'localhost'`?** Solo pueden conectarse desde la misma máquina, que es lo más restrictivo. Para acceso remoto se usaría `'%'` o una IP.
- **¿Las contraseñas del script son seguras?** Cumplen la política (mayúscula, número, símbolo, 8 o más caracteres), pero al estar en un repositorio ya no son secretas. En producción se cambian.
