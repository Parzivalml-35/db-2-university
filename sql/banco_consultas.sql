-- =====================================================================
-- BANCO DE CONSULTAS · Parcial Final, Caso 2 Veterinaria "Huellas"
--
-- Todo lo que el profesor podría pedir en vivo durante la exposición,
-- con un CONCEPTO breve por sección para repasar.
--
-- Requisito: haber ejecutado antes sql/parcial_veterinaria.sql tal cual
-- (los "Esperado:" asumen esos datos, incluidos sus UPDATE de prueba).
--
-- Se puede ejecutar completo sin dañar la BD del parcial:
--   * los cambios de datos van en START TRANSACTION … ROLLBACK;
--   * los objetos de práctica (prefijo ej_) se borran en la sección Z.
-- Las líneas "-- DEMO ERROR:" están comentadas a propósito: provocan un
-- error y detendrían la ejecución. Se seleccionan sin el "-- " y se
-- ejecutan con Ctrl+Enter para mostrar el error.
--
-- Workbench: Ctrl+Enter = sentencia actual · Ctrl+Shift+Enter = selección
-- =====================================================================
SET NAMES utf8mb4;
USE veterinaria_huellas;


-- =====================================================================
-- A. EXPLORAR LA BASE DE DATOS
-- CONCEPTO: SHOW y DESCRIBE leen el catálogo del servidor. Lo mismo, con
-- más detalle y filtrable con WHERE, está en information_schema: una BD
-- de solo lectura con la "metadata" (tablas, columnas, FK, rutinas…).
-- =====================================================================

-- A1. "¿En qué servidor y base de datos estás?"
SELECT VERSION() AS version_mysql, DATABASE() AS bd_actual, CURRENT_USER() AS usuario;

-- A2. "Muestra las bases de datos y las tablas"
SHOW DATABASES;
SHOW TABLES;                                   -- incluye la vista
SHOW FULL TABLES;                              -- Table_type: BASE TABLE o VIEW
SHOW FULL TABLES WHERE Table_type = 'VIEW';    -- solo vistas

-- A3. "Describe la estructura de una tabla"
DESCRIBE mascotas;                 -- columnas, tipos, NULL, claves (PRI, MUL, UNI)
SHOW COLUMNS FROM consultas_medicas;
SHOW CREATE TABLE consultas_medicas;   -- el DDL completo con FK y CHECK

-- A4. "¿Qué llaves foráneas tiene la BD?"
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME,
       REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'veterinaria_huellas'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;
-- Esperado: 4 FK (consultas → mascotas y veterinarios; mascotas → especies y propietarios)

-- A5. "¿Cuántos registros tiene cada tabla?"
-- TABLE_ROWS de information_schema es aproximado en InnoDB; el exacto es COUNT(*).
SELECT 'propietarios' AS tabla, COUNT(*) AS filas FROM propietarios
UNION ALL SELECT 'especies',               COUNT(*) FROM especies
UNION ALL SELECT 'mascotas',               COUNT(*) FROM mascotas
UNION ALL SELECT 'veterinarios',           COUNT(*) FROM veterinarios
UNION ALL SELECT 'consultas_medicas',      COUNT(*) FROM consultas_medicas
UNION ALL SELECT 'historial_diagnosticos', COUNT(*) FROM historial_diagnosticos;
-- Esperado: 5, 5, 6, 5, 8, 5

-- A6. "Muestra las funciones, procedimientos, triggers y vistas"
SHOW FUNCTION STATUS  WHERE Db = 'veterinaria_huellas';
SHOW PROCEDURE STATUS WHERE Db = 'veterinaria_huellas';
SHOW TRIGGERS;
SELECT ROUTINE_NAME, ROUTINE_TYPE, IS_DETERMINISTIC, SQL_DATA_ACCESS
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'veterinaria_huellas';
-- Esperado: fn_etapa_vida FUNCTION YES NO SQL · sp_estadisticas_veterinario PROCEDURE NO CONTAINS SQL
-- (CONTAINS SQL es el valor por defecto cuando no se declara la característica)

-- A7. "Muéstrame el código de tu función / procedimiento / trigger / vista"
SHOW CREATE FUNCTION  fn_etapa_vida;
SHOW CREATE PROCEDURE sp_estadisticas_veterinario;
SHOW CREATE TRIGGER   tg_respaldo_diagnostico;
SHOW CREATE VIEW      vw_historia_clinica;


-- =====================================================================
-- B. USUARIOS, PRIVILEGIOS Y ROLES
-- CONCEPTO:
-- * Una cuenta es 'usuario'@'host': el mismo nombre desde otro host es
--   otra cuenta. '%' = cualquier host.
-- * Privilegio = permiso (SELECT, INSERT, EXECUTE…) en un nivel:
--   global (*.*), BD (bd.*), tabla (bd.tabla), columna o rutina.
-- * Rol = paquete de privilegios con nombre. Se da a varios usuarios y
--   se cambia en un solo lugar. Un rol asignado NO está activo hasta
--   SET ROLE o SET DEFAULT ROLE.
-- * FLUSH PRIVILEGES solo hace falta si se editan las tablas mysql.* a
--   mano; GRANT, REVOKE, CREATE USER y ALTER USER ya aplican al instante.
-- =====================================================================

-- B1. "Muestra los usuarios del servidor"
SELECT user, host, account_locked FROM mysql.user ORDER BY user;
-- Los roles también aparecen aquí (son cuentas bloqueadas, sin contraseña).

-- B2. "¿Qué roles tiene cada usuario y cuáles se activan por defecto?"
SELECT FROM_USER AS rol, TO_USER AS usuario, TO_HOST AS host FROM mysql.role_edges;
SELECT USER AS usuario, DEFAULT_ROLE_USER AS rol_por_defecto FROM mysql.default_roles;

-- B3. "Muestra los permisos de un usuario / rol"
SHOW GRANTS;                                         -- los míos
SHOW GRANTS FOR 'rol_empleado';
SHOW GRANTS FOR 'admin_huellas'@'localhost';                         -- solo dice qué rol tiene
SHOW GRANTS FOR 'admin_huellas'@'localhost' USING 'rol_admin';       -- expande el rol

-- B4. "Crea un usuario en vivo y dale permisos limitados"
DROP USER IF EXISTS 'practica_huellas'@'localhost';
CREATE USER 'practica_huellas'@'localhost' IDENTIFIED BY 'Pract1ca.Huellas#26';

GRANT SELECT ON veterinaria_huellas.vw_historia_clinica TO 'practica_huellas'@'localhost';  -- solo la vista
GRANT SELECT (nombre, apellido, especialidad)
      ON veterinaria_huellas.veterinarios TO 'practica_huellas'@'localhost';                -- solo 3 columnas
GRANT EXECUTE ON PROCEDURE veterinaria_huellas.sp_estadisticas_veterinario
      TO 'practica_huellas'@'localhost';                                                     -- una rutina
SHOW GRANTS FOR 'practica_huellas'@'localhost';

-- B5. "Quítale un permiso"
REVOKE EXECUTE ON PROCEDURE veterinaria_huellas.sp_estadisticas_veterinario
       FROM 'practica_huellas'@'localhost';

-- B6. "Asígnale un rol y que se active solo"
GRANT 'rol_empleado' TO 'practica_huellas'@'localhost';
SET DEFAULT ROLE ALL TO 'practica_huellas'@'localhost';
SHOW GRANTS FOR 'practica_huellas'@'localhost' USING 'rol_empleado';
REVOKE 'rol_empleado' FROM 'practica_huellas'@'localhost';

-- B7. "Cámbiale la contraseña / bloquéalo"
ALTER USER 'practica_huellas'@'localhost' IDENTIFIED BY 'Nuev0.Clave#Huellas26';
ALTER USER 'practica_huellas'@'localhost' ACCOUNT LOCK;     -- no puede iniciar sesión
ALTER USER 'practica_huellas'@'localhost' ACCOUNT UNLOCK;

-- B8. "Borra el usuario"
DROP USER 'practica_huellas'@'localhost';

-- B9. Dentro de una sesión de un usuario con roles (no como root):
--   SELECT CURRENT_ROLE();       -- roles activos ahora
--   SET ROLE NONE;               -- desactiva todos → pierde los permisos
--   SET ROLE 'rol_empleado';     -- activa uno
--   SET ROLE ALL;                -- activa todos los asignados

-- DEMO ERROR 1142 (sesión como recepcion_huellas, que solo tiene SELECT e INSERT):
-- DELETE FROM veterinaria_huellas.especies WHERE especie_id = 5;


-- =====================================================================
-- C. CONSULTAS BÁSICAS (SELECT)
-- CONCEPTO: orden lógico de evaluación:
--   FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT.
-- Por eso un alias del SELECT sirve en ORDER BY pero no en WHERE.
-- NULL no es igual a nada (ni a otro NULL): se pregunta con IS NULL.
-- =====================================================================

-- C1. "Lista todas las mascotas ordenadas por nombre"
SELECT mascota_id, nombre, raza, sexo, fecha_nacimiento FROM mascotas ORDER BY nombre;

-- C2. "Solo los perros" (filtrando por la FK)
SELECT nombre, raza FROM mascotas WHERE especie_id = 1;
-- Esperado: Max, Rocky, Toby

-- C3. "Mascotas cuyo nombre empiece por L"  (% = cualquier texto, _ = un carácter)
SELECT nombre FROM mascotas WHERE nombre LIKE 'L%';
-- Esperado: Luna

-- C4. "Consultas de octubre"
-- Con DATETIME es más seguro >= inicio y < día siguiente que BETWEEN:
-- BETWEEN '2026-10-01' AND '2026-10-31' deja fuera el 31 después de las 00:00.
SELECT consulta_id, fecha_consulta, motivo
FROM consultas_medicas
WHERE fecha_consulta >= '2026-10-01' AND fecha_consulta < '2026-11-01';
-- Esperado: consultas 4, 5, 6

-- C5. "Veterinarios de cirugía o dermatología"
SELECT nombre, apellido, especialidad
FROM veterinarios
WHERE especialidad IN ('Cirugía', 'Dermatología');

-- C6. "¿Quién no tiene email? ¿Qué mascota no tiene fecha de nacimiento?"
SELECT nombre, apellido FROM propietarios WHERE email IS NULL;           -- Julián Moreno
SELECT nombre FROM mascotas WHERE fecha_nacimiento IS NULL;              -- Toby

-- C7. "¿Cuántos veterinarios distintos han atendido consultas?"
SELECT DISTINCT veterinario_id FROM consultas_medicas;                   -- 1, 2, 3, 4
SELECT COUNT(DISTINCT veterinario_id) AS veterinarios_activos FROM consultas_medicas;  -- 4

-- C8. "Las 3 consultas más caras"
SELECT consulta_id, motivo, costo FROM consultas_medicas ORDER BY costo DESC LIMIT 3;
-- Esperado: 3 (150000), 6 (120000), 5 (90000)

-- C9. "Directorio de propietarios con nombre completo"  (alias, CONCAT, COALESCE)
SELECT CONCAT(nombre, ' ', apellido)  AS propietario,
       telefono,
       COALESCE(email, 'Sin correo')  AS email
FROM propietarios
ORDER BY propietario;

-- C10. "Clasifica las consultas por costo" (CASE dentro de un SELECT, sin función)
SELECT consulta_id, costo,
       CASE
           WHEN costo < 60000  THEN 'Económica'
           WHEN costo < 100000 THEN 'Estándar'
           ELSE                     'Especializada'
       END AS categoria
FROM consultas_medicas;

-- C11. Funciones de fecha
SELECT nombre,
       TIMESTAMPDIFF(YEAR,  fecha_nacimiento, CURDATE()) AS edad_anios,
       TIMESTAMPDIFF(MONTH, fecha_nacimiento, CURDATE()) AS edad_meses
FROM mascotas;
SELECT consulta_id, DATEDIFF(CURDATE(), fecha_consulta) AS dias_desde_consulta,
       DATE_FORMAT(fecha_consulta, '%d/%m/%Y %H:%i')   AS fecha_legible
FROM consultas_medicas;


-- =====================================================================
-- D. JOINS
-- CONCEPTO:
-- * INNER JOIN: solo las filas que tienen pareja en ambas tablas.
-- * LEFT JOIN: todas las de la izquierda; si no hay pareja, las columnas
--   de la derecha salen NULL. RIGHT JOIN es lo mismo al revés.
-- * La condición de unión (ON) casi siempre es FK = PK.
-- * Anti-join: LEFT JOIN + WHERE derecha.pk IS NULL = "los que NO tienen".
-- * Una condición sobre la tabla derecha puesta en WHERE convierte el
--   LEFT JOIN en INNER; para conservar las filas sin pareja va en el ON.
-- =====================================================================

-- D1. "Cada mascota con su dueño" (INNER, 2 tablas)
SELECT m.nombre AS mascota, CONCAT(p.nombre, ' ', p.apellido) AS propietario, p.telefono
FROM mascotas m
INNER JOIN propietarios p ON p.propietario_id = m.propietario_id;
-- Esperado: 6 filas (Laura tiene a Max y a Luna)

-- D2. "Mascota, especie y dueño" (INNER, 3 tablas)
SELECT m.nombre AS mascota, e.nombre AS especie, m.raza,
       CONCAT(p.nombre, ' ', p.apellido) AS propietario
FROM mascotas m
INNER JOIN especies     e ON e.especie_id     = m.especie_id
INNER JOIN propietarios p ON p.propietario_id = m.propietario_id
ORDER BY especie, mascota;

-- D3. "Todas las consultas con mascota, veterinario y dueño" (4 tablas)
SELECT c.consulta_id, c.fecha_consulta, m.nombre AS mascota,
       CONCAT(v.nombre, ' ', v.apellido) AS veterinario,
       CONCAT(p.nombre, ' ', p.apellido) AS propietario,
       c.diagnostico, c.costo
FROM consultas_medicas c
INNER JOIN mascotas     m ON m.mascota_id     = c.mascota_id
INNER JOIN veterinarios v ON v.veterinario_id = c.veterinario_id
INNER JOIN propietarios p ON p.propietario_id = m.propietario_id
ORDER BY c.fecha_consulta;
-- Esperado: 8 filas (es lo mismo que hace la vista vw_historia_clinica)

-- D4. "Todos los veterinarios, tengan o no consultas" (LEFT)
SELECT CONCAT(v.nombre, ' ', v.apellido) AS veterinario, c.consulta_id, c.fecha_consulta
FROM veterinarios v
LEFT JOIN consultas_medicas c ON c.veterinario_id = v.veterinario_id
ORDER BY v.veterinario_id;
-- Esperado: 9 filas; Mariana López aparece con consulta_id NULL

-- D5. "¿Qué veterinarios NO han atendido?" (anti-join)
SELECT v.nombre, v.apellido
FROM veterinarios v
LEFT JOIN consultas_medicas c ON c.veterinario_id = v.veterinario_id
WHERE c.consulta_id IS NULL;
-- Esperado: Mariana López

-- D6. "¿Qué especies no tienen mascotas registradas?"
SELECT e.nombre AS especie
FROM especies e
LEFT JOIN mascotas m ON m.especie_id = e.especie_id
WHERE m.mascota_id IS NULL;
-- Esperado: Hámster

-- D7. RIGHT JOIN: el D4 escrito al revés (mismo resultado)
SELECT CONCAT(v.nombre, ' ', v.apellido) AS veterinario, c.consulta_id
FROM consultas_medicas c
RIGHT JOIN veterinarios v ON v.veterinario_id = c.veterinario_id;

-- D8. "Mascotas que comparten dueño" (self join: la tabla consigo misma)
SELECT m1.nombre AS mascota_1, m2.nombre AS mascota_2, m1.propietario_id
FROM mascotas m1
INNER JOIN mascotas m2
        ON m2.propietario_id = m1.propietario_id
       AND m2.mascota_id > m1.mascota_id;     -- evita (Max, Max) y el par repetido
-- Esperado: Max – Luna

-- D9. "Consultas de los perros" (JOIN + filtro)
SELECT m.nombre, c.fecha_consulta, c.motivo
FROM consultas_medicas c
INNER JOIN mascotas m ON m.mascota_id = c.mascota_id
INNER JOIN especies e ON e.especie_id = m.especie_id
WHERE e.nombre = 'Perro'
ORDER BY c.fecha_consulta;
-- Esperado: 5 consultas (Max ×2, Rocky ×2, Toby)


-- =====================================================================
-- E. FUNCIONES DE AGREGACIÓN, GROUP BY Y HAVING
-- CONCEPTO:
-- * COUNT(*) cuenta filas; COUNT(columna) ignora los NULL.
-- * GROUP BY arma un grupo por cada valor distinto; las columnas del
--   SELECT que no estén agregadas deben ir en el GROUP BY
--   (ONLY_FULL_GROUP_BY, activo por defecto en MySQL 8).
-- * WHERE filtra filas ANTES de agrupar; HAVING filtra grupos DESPUÉS
--   (por eso solo HAVING puede usar COUNT, SUM…).
-- =====================================================================

-- E1. COUNT(*) vs COUNT(columna)
SELECT COUNT(*) AS propietarios, COUNT(email) AS con_email FROM propietarios;
-- Esperado: 5 y 4

-- E2. "Totales de facturación"
SELECT COUNT(*) AS consultas, SUM(costo) AS total, AVG(costo) AS promedio,
       MIN(costo) AS minimo, MAX(costo) AS maximo
FROM consultas_medicas;
-- Esperado: 8 · 685000 · 85625 · 50000 · 150000

-- E3. "Consultas e ingresos por especie" (incluye especies sin mascotas)
SELECT e.nombre AS especie,
       COUNT(c.consulta_id)       AS consultas,
       COALESCE(SUM(c.costo), 0)  AS ingresos
FROM especies e
LEFT JOIN mascotas m          ON m.especie_id = e.especie_id
LEFT JOIN consultas_medicas c ON c.mascota_id = m.mascota_id
GROUP BY e.especie_id, e.nombre
ORDER BY ingresos DESC;
-- Esperado: Perro 5/440000 · Conejo 1/90000 · Gato 1/85000 · Ave 1/70000 · Hámster 0/0

-- E4. "¿Qué mascotas han venido más de una vez?" (HAVING)
SELECT m.nombre, COUNT(*) AS visitas
FROM consultas_medicas c
INNER JOIN mascotas m ON m.mascota_id = c.mascota_id
GROUP BY m.mascota_id, m.nombre
HAVING COUNT(*) > 1;
-- Esperado: Max 2, Rocky 2

-- E5. "Cuántas mascotas tiene cada propietario y cuáles son"
SELECT CONCAT(p.nombre, ' ', p.apellido) AS propietario,
       COUNT(m.mascota_id)                                     AS mascotas,
       GROUP_CONCAT(m.nombre ORDER BY m.nombre SEPARATOR ', ') AS nombres
FROM propietarios p
LEFT JOIN mascotas m ON m.propietario_id = p.propietario_id
GROUP BY p.propietario_id, p.nombre, p.apellido
ORDER BY mascotas DESC;
-- Esperado: Laura Gómez 2 (Luna, Max); el resto 1

-- E6. "Ingresos por mes"
SELECT DATE_FORMAT(fecha_consulta, '%Y-%m') AS mes,
       COUNT(*) AS consultas, SUM(costo) AS ingresos
FROM consultas_medicas
GROUP BY mes
ORDER BY mes;
-- Esperado: 2026-09 3/300000 · 2026-10 3/280000 · 2026-11 2/105000

-- E7. "Lo mismo con una fila de total general" (WITH ROLLUP)
SELECT DATE_FORMAT(fecha_consulta, '%Y-%m') AS mes, SUM(costo) AS ingresos
FROM consultas_medicas
GROUP BY mes WITH ROLLUP;
-- Esperado: la última fila tiene mes NULL e ingresos 685000

-- E8. "Ingresos por veterinario solo si superan 80.000" (WHERE + HAVING juntos)
SELECT CONCAT(v.nombre, ' ', v.apellido) AS veterinario, SUM(c.costo) AS ingresos
FROM consultas_medicas c
INNER JOIN veterinarios v ON v.veterinario_id = c.veterinario_id
WHERE c.fecha_consulta >= '2026-09-01'     -- filtra filas
GROUP BY v.veterinario_id, v.nombre, v.apellido
HAVING SUM(c.costo) > 80000                -- filtra grupos
ORDER BY ingresos DESC;
-- Esperado: Sofía Martínez 375000, Carlos Pérez 150000, Natalia Vargas 90000


-- =====================================================================
-- F. SUBCONSULTAS Y UNION
-- CONCEPTO: una subconsulta es un SELECT dentro de otro.
-- * Escalar: devuelve 1 valor (se compara con =, >, <).
-- * De lista: devuelve 1 columna (se usa con IN / NOT IN).
-- * EXISTS: solo pregunta si hay al menos una fila.
-- * Tabla derivada: un SELECT en el FROM; necesita alias.
-- * Cuidado: NOT IN con un NULL en la lista no devuelve nada; con
--   NOT EXISTS no pasa.
-- UNION junta resultados con las mismas columnas (UNION quita
-- duplicados; UNION ALL no, y es más rápido).
-- =====================================================================

-- F1. "Consultas más caras que el promedio" (escalar)
SELECT consulta_id, motivo, costo
FROM consultas_medicas
WHERE costo > (SELECT AVG(costo) FROM consultas_medicas);
-- Esperado: 3, 5, 6

-- F2. "Propietarios que tienen perros" (IN)
SELECT nombre, apellido
FROM propietarios
WHERE propietario_id IN (
    SELECT propietario_id FROM mascotas
    WHERE especie_id = (SELECT especie_id FROM especies WHERE nombre = 'Perro')
);
-- Esperado: Laura, Andrés, Valentina

-- F3. "Veterinarios sin consultas" (NOT EXISTS; mismo resultado que D5)
SELECT v.nombre, v.apellido
FROM veterinarios v
WHERE NOT EXISTS (SELECT 1 FROM consultas_medicas c WHERE c.veterinario_id = v.veterinario_id);
-- Esperado: Mariana López

-- F4. "Promedio de consultas por veterinario activo" (tabla derivada)
SELECT AVG(t.total) AS promedio_consultas
FROM (SELECT veterinario_id, COUNT(*) AS total
      FROM consultas_medicas
      GROUP BY veterinario_id) AS t;
-- Esperado: 2.0000  ((5+1+1+1) / 4)

-- F5. "Directorio de contactos de la clínica" (UNION)
SELECT CONCAT(nombre, ' ', apellido) AS persona, 'Propietario' AS tipo FROM propietarios
UNION ALL
SELECT CONCAT(nombre, ' ', apellido), 'Veterinario' FROM veterinarios
ORDER BY tipo, persona;
-- Esperado: 10 filas


-- =====================================================================
-- G. MODIFICAR DATOS EN VIVO (DML) Y TRANSACCIONES
-- CONCEPTO:
-- * INSERT agrega, UPDATE modifica, DELETE borra filas. UPDATE y DELETE
--   sin WHERE afectan TODA la tabla (Workbench lo bloquea con el modo
--   "safe updates", error 1175).
-- * Transacción: grupo de cambios que se guarda todo (COMMIT) o nada
--   (ROLLBACK). Garantiza ACID: Atomicidad, Consistencia, Aislamiento y
--   Durabilidad. Lo que hace un trigger forma parte de la misma
--   transacción.
-- * El DDL (CREATE, ALTER, DROP) hace COMMIT implícito: no se deshace
--   con ROLLBACK.
-- * ROLLBACK no devuelve el AUTO_INCREMENT: quedan "huecos" en los IDs.
-- * Integridad referencial: la FK impide borrar un padre con hijos
--   (1451) e insertar un hijo con un padre inexistente (1452).
-- =====================================================================
START TRANSACTION;

-- G1. "Registra una mascota nueva y su primera consulta"
INSERT INTO mascotas (nombre, especie_id, raza, sexo, fecha_nacimiento, propietario_id)
VALUES ('Copito', 5, 'Sirio', 'M', DATE_SUB(CURDATE(), INTERVAL 3 MONTH), 3);
SET @nueva_mascota = LAST_INSERT_ID();       -- ID que acaba de generar AUTO_INCREMENT

INSERT INTO consultas_medicas (mascota_id, veterinario_id, fecha_consulta, motivo, diagnostico, costo)
VALUES (@nueva_mascota, 4, NOW(), 'Revisión inicial', NULL, 45000);
SET @nueva_consulta = LAST_INSERT_ID();

SELECT mascota, especie, etapa_vida, propietario, veterinario
FROM vw_historia_clinica WHERE consulta_id = @nueva_consulta;
-- Esperado: Copito · Hámster · Cachorro · Camila Torres · Felipe Castro

-- G2. "Actualiza el diagnóstico" → dispara el trigger
UPDATE consultas_medicas SET diagnostico = 'Sano' WHERE consulta_id = @nueva_consulta;
SELECT consulta_id, diagnostico_anterior, diagnostico_nuevo
FROM historial_diagnosticos WHERE consulta_id = @nueva_consulta;
-- Esperado: 1 fila (NULL → Sano)

-- G3. "Sube 10 % las tarifas de cirugía" (UPDATE de varias filas)
UPDATE consultas_medicas SET costo = costo * 1.10 WHERE veterinario_id = 2;
SELECT consulta_id, costo FROM consultas_medicas WHERE veterinario_id = 2;
-- Esperado: consulta 3 → 165000.00

-- G4. "Borra la mascota nueva": primero los hijos (consultas), luego el padre
DELETE FROM consultas_medicas WHERE consulta_id = @nueva_consulta;
DELETE FROM mascotas          WHERE mascota_id  = @nueva_mascota;

ROLLBACK;   -- deshace G1 a G4, incluido lo que escribió el trigger

SELECT COUNT(*) AS mascotas FROM mascotas;                              -- 6 otra vez
SELECT costo FROM consultas_medicas WHERE consulta_id = 3;              -- 150000.00 otra vez

-- DEMO ERROR 1451: no se puede borrar un propietario que tiene mascotas
-- DELETE FROM propietarios WHERE propietario_id = 1;
-- DEMO ERROR 1452: no existe el propietario 99
-- INSERT INTO mascotas (nombre, especie_id, sexo, propietario_id) VALUES ('Fantasma', 1, 'M', 99);
-- DEMO ERROR 1062: valor duplicado en una columna UNIQUE
-- INSERT INTO especies (nombre) VALUES ('Perro');
-- DEMO ERROR 3819: viola el CHECK (costo >= 0)
-- INSERT INTO consultas_medicas (mascota_id, veterinario_id, fecha_consulta, motivo, costo) VALUES (1, 1, NOW(), 'Prueba', -5);


-- =====================================================================
-- H. MODIFICAR LA ESTRUCTURA EN VIVO (DDL) E ÍNDICES
-- CONCEPTO:
-- * ALTER TABLE cambia una tabla existente: ADD/DROP/MODIFY/RENAME COLUMN,
--   ADD CONSTRAINT…
-- * DELETE borra filas (con WHERE, dispara triggers, se puede deshacer);
--   TRUNCATE vacía la tabla entera y reinicia el AUTO_INCREMENT (es DDL);
--   DROP elimina la tabla completa.
-- * Índice: estructura (árbol B) que permite encontrar filas sin leer
--   toda la tabla. Acelera WHERE, JOIN y ORDER BY, pero ocupa espacio y
--   hace más lentos INSERT y UPDATE. PK, UNIQUE y FK ya crean el suyo.
-- * EXPLAIN muestra el plan: type=ALL es un recorrido completo; key dice
--   qué índice se usó.
-- =====================================================================

-- H1. "Agrega una columna color a mascotas" (y quítala)
ALTER TABLE mascotas ADD COLUMN color VARCHAR(30) NULL AFTER raza;
DESCRIBE mascotas;
ALTER TABLE mascotas DROP COLUMN color;

-- H2. "Crea una tabla nueva relacionada": vacunas aplicadas (1:N con mascotas)
DROP TABLE IF EXISTS ej_vacunas;
CREATE TABLE ej_vacunas (
    vacuna_id        INT         NOT NULL AUTO_INCREMENT,
    mascota_id       INT         NOT NULL,
    nombre_vacuna    VARCHAR(60) NOT NULL,
    fecha_aplicacion DATE        NOT NULL,
    proxima_dosis    DATE        NULL,
    PRIMARY KEY (vacuna_id),
    CONSTRAINT fk_ej_vacunas_mascota FOREIGN KEY (mascota_id) REFERENCES mascotas (mascota_id)
) ENGINE = InnoDB;

INSERT INTO ej_vacunas (mascota_id, nombre_vacuna, fecha_aplicacion, proxima_dosis) VALUES
    (1, 'Rabia',          '2026-09-02', '2027-09-02'),
    (1, 'Parvovirus',     '2026-09-02', '2027-09-02'),
    (2, 'Triple felina',  '2026-09-10', '2026-12-10'),
    (3, 'Rabia',          '2026-09-15', '2027-09-15'),
    (6, 'Moquillo',       '2026-11-10', '2027-11-10');

SELECT m.nombre AS mascota, v.nombre_vacuna, v.proxima_dosis
FROM ej_vacunas v
INNER JOIN mascotas m ON m.mascota_id = v.mascota_id
ORDER BY v.proxima_dosis;
-- Esperado: 5 filas; la primera es Luna (2026-12-10)

-- H3. Renombrar y modificar columnas
ALTER TABLE ej_vacunas RENAME COLUMN proxima_dosis TO fecha_refuerzo;
ALTER TABLE ej_vacunas MODIFY nombre_vacuna VARCHAR(100) NOT NULL;
DESCRIBE ej_vacunas;

-- H4. "Crea un índice y muestra la diferencia con EXPLAIN"
EXPLAIN SELECT * FROM consultas_medicas WHERE fecha_consulta >= '2026-10-01';
-- Esperado: type ALL, key NULL (no hay índice sobre la fecha)
CREATE INDEX ix_consultas_fecha ON consultas_medicas (fecha_consulta);
EXPLAIN SELECT * FROM consultas_medicas WHERE fecha_consulta >= '2026-10-01';
-- Esperado: type range, key ix_consultas_fecha, rows 5 (antes leía las 8).
-- El optimizador decide según el costo: en tablas muy pequeñas a veces
-- prefiere ALL aunque exista el índice.
SHOW INDEX FROM consultas_medicas;
DROP INDEX ix_consultas_fecha ON consultas_medicas;


-- =====================================================================
-- I. FUNCIONES Y PROCEDIMIENTOS NUEVOS (estilo taller y apuntes)
-- CONCEPTO:
-- * FUNCIÓN: devuelve 1 valor con RETURN y se usa dentro de un SELECT.
--   Solo tiene parámetros de entrada.
-- * PROCEDIMIENTO: se ejecuta con CALL. Puede devolver resultados (un
--   SELECT) y valores por parámetros OUT/INOUT, y puede modificar datos.
-- * IN = entra · OUT = sale (empieza en NULL) · INOUT = entra y sale.
-- * DELIMITER $$: el cuerpo tiene varios ';'; sin cambiar el delimitador
--   el cliente cortaría el CREATE en el primer ';'.
-- * Características: DETERMINISTIC (misma entrada → misma salida),
--   NO SQL (no toca tablas), READS SQL DATA (lee tablas),
--   MODIFIES SQL DATA (escribe). Con el binlog activo, una función sin
--   DETERMINISTIC, NO SQL ni READS SQL DATA da el error 1418.
-- * No existe ALTER para cambiar el cuerpo: se hace DROP + CREATE.
-- * DECLARE crea variables locales (solo al inicio del BEGIN);
--   @variable es una variable de sesión.
-- =====================================================================

-- I1. Función con IF / ELSEIF (como el ejemplo 2 de los apuntes)
DROP FUNCTION IF EXISTS ej_categoria_costo;
DELIMITER $$
CREATE FUNCTION ej_categoria_costo(p_costo DECIMAL(10,2))
RETURNS VARCHAR(20)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_categoria VARCHAR(20);
    IF p_costo IS NULL THEN
        SET v_categoria = 'Sin costo';
    ELSEIF p_costo < 60000 THEN
        SET v_categoria = 'Económica';
    ELSEIF p_costo < 100000 THEN
        SET v_categoria = 'Estándar';
    ELSE
        SET v_categoria = 'Especializada';
    END IF;
    RETURN v_categoria;
END$$
DELIMITER ;

SELECT consulta_id, costo, ej_categoria_costo(costo) AS categoria FROM consultas_medicas;
-- Esperado: 7 (50000) Económica · 2 (85000) Estándar · 3 (150000) Especializada

-- I2. Función que transforma texto (como formato_correo del taller)
DROP FUNCTION IF EXISTS ej_correo_veterinario;
DELIMITER $$
CREATE FUNCTION ej_correo_veterinario(p_nombre VARCHAR(50), p_apellido VARCHAR(50))
RETURNS VARCHAR(120)
DETERMINISTIC
NO SQL
BEGIN
    RETURN LOWER(CONCAT(p_nombre, '.', p_apellido, '@huellas.com'));
END$$
DELIMITER ;

SELECT nombre, apellido, ej_correo_veterinario(nombre, apellido) AS correo FROM veterinarios;
-- Esperado: sofía.martínez@huellas.com … (conserva las tildes; un correo real
-- las quitaría con REPLACE)

-- I3. Función que LEE tablas → READS SQL DATA (comparar con I1 e I2)
DROP FUNCTION IF EXISTS ej_total_consultas_mascota;
DELIMITER $$
CREATE FUNCTION ej_total_consultas_mascota(p_mascota_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COUNT(*) INTO v_total FROM consultas_medicas WHERE mascota_id = p_mascota_id;
    RETURN v_total;
END$$
DELIMITER ;

SELECT nombre, ej_total_consultas_mascota(mascota_id) AS consultas FROM mascotas;
-- Esperado: Max 2, Luna 1, Rocky 2, Kiwi 1, Nieve 1, Toby 1

-- I4. Procedimiento sin parámetros que devuelve un resultado
DROP PROCEDURE IF EXISTS ej_listar_mascotas;
DELIMITER $$
CREATE PROCEDURE ej_listar_mascotas()
BEGIN
    SELECT m.nombre AS mascota, e.nombre AS especie, CONCAT(p.nombre, ' ', p.apellido) AS propietario
    FROM mascotas m
    INNER JOIN especies     e ON e.especie_id     = m.especie_id
    INNER JOIN propietarios p ON p.propietario_id = m.propietario_id
    ORDER BY m.nombre;
END$$
DELIMITER ;

CALL ej_listar_mascotas();

-- I5. Procedimiento con IN que filtra
DROP PROCEDURE IF EXISTS ej_consultas_por_mascota;
DELIMITER $$
CREATE PROCEDURE ej_consultas_por_mascota(IN p_nombre_mascota VARCHAR(50))
BEGIN
    SELECT c.fecha_consulta, c.motivo, c.diagnostico,
           CONCAT(v.nombre, ' ', v.apellido) AS veterinario
    FROM consultas_medicas c
    INNER JOIN mascotas     m ON m.mascota_id     = c.mascota_id
    INNER JOIN veterinarios v ON v.veterinario_id = c.veterinario_id
    WHERE m.nombre = p_nombre_mascota
    ORDER BY c.fecha_consulta;
END$$
DELIMITER ;

CALL ej_consultas_por_mascota('Rocky');
-- Esperado: 2 consultas (Carlos Pérez y Sofía Martínez)

-- I6. IN + OUT (como count_by_surname del taller)
DROP PROCEDURE IF EXISTS ej_contar_por_especie;
DELIMITER $$
CREATE PROCEDURE ej_contar_por_especie(IN p_especie VARCHAR(40), OUT p_total INT)
BEGIN
    SELECT COUNT(m.mascota_id) INTO p_total
    FROM especies e
    LEFT JOIN mascotas m ON m.especie_id = e.especie_id
    WHERE e.nombre = p_especie;
END$$
DELIMITER ;

CALL ej_contar_por_especie('Perro', @total);
SELECT @total AS perros;        -- Esperado: 3

-- I7. OUT con mensaje condicional (como check_email_status del taller)
DROP PROCEDURE IF EXISTS ej_estado_email_propietario;
DELIMITER $$
CREATE PROCEDURE ej_estado_email_propietario(IN p_propietario_id INT, OUT p_status VARCHAR(20))
BEGIN
    SELECT IF(email IS NULL, 'Pendiente', 'Completo') INTO p_status
    FROM propietarios
    WHERE propietario_id = p_propietario_id;
END$$
DELIMITER ;

CALL ej_estado_email_propietario(1, @estado);  SELECT @estado AS laura;    -- Completo
CALL ej_estado_email_propietario(4, @estado);  SELECT @estado AS julian;   -- Pendiente

-- I8. INOUT: el mismo parámetro entra con un valor y sale modificado
DROP PROCEDURE IF EXISTS ej_aplicar_descuento;
DELIMITER $$
CREATE PROCEDURE ej_aplicar_descuento(INOUT p_valor DECIMAL(10,2), IN p_porcentaje INT)
BEGIN
    SET p_valor = p_valor - (p_valor * p_porcentaje / 100);
END$$
DELIMITER ;

SET @valor = 100000;
CALL ej_aplicar_descuento(@valor, 10);
SELECT @valor AS con_descuento;     -- Esperado: 90000.00

-- I9. Procedimiento que INSERTA y devuelve el ID nuevo por OUT
DROP PROCEDURE IF EXISTS ej_registrar_consulta;
DELIMITER $$
CREATE PROCEDURE ej_registrar_consulta(
    IN  p_mascota_id     INT,
    IN  p_veterinario_id INT,
    IN  p_motivo         VARCHAR(150),
    IN  p_costo          DECIMAL(10,2),
    OUT p_consulta_id    INT
)
BEGIN
    INSERT INTO consultas_medicas (mascota_id, veterinario_id, fecha_consulta, motivo, costo)
    VALUES (p_mascota_id, p_veterinario_id, NOW(), p_motivo, p_costo);
    SET p_consulta_id = LAST_INSERT_ID();
END$$
DELIMITER ;

START TRANSACTION;
CALL ej_registrar_consulta(4, 4, 'Control de plumaje', 40000, @id_nueva);
SELECT @id_nueva AS consulta_creada, mascota, veterinario
FROM vw_historia_clinica WHERE consulta_id = @id_nueva;     -- Kiwi · Felipe Castro
ROLLBACK;


-- =====================================================================
-- J. TRIGGERS ADICIONALES
-- CONCEPTO:
-- * Momento: BEFORE (antes; puede modificar NEW o cancelar con SIGNAL) o
--   AFTER (después; sirve para auditar lo que ya se guardó).
-- * Evento: INSERT (solo NEW) · UPDATE (OLD y NEW) · DELETE (solo OLD).
-- * SIGNAL SQLSTATE '45000' lanza un error propio y cancela la operación.
-- * Un trigger no puede modificar la misma tabla que lo disparó (error
--   1442) ni usar START TRANSACTION, COMMIT o ROLLBACK.
-- =====================================================================

-- J1. BEFORE INSERT: valida y normaliza el email del propietario
DROP TRIGGER IF EXISTS tg_ej_email_propietario;
DELIMITER $$
CREATE TRIGGER tg_ej_email_propietario
BEFORE INSERT ON propietarios
FOR EACH ROW
BEGIN
    IF NEW.email IS NOT NULL AND NEW.email NOT LIKE '%_@_%._%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email con formato inválido';
    END IF;
    SET NEW.email = LOWER(TRIM(NEW.email));   -- modificar NEW solo es posible en BEFORE
END$$
DELIMITER ;

START TRANSACTION;
INSERT INTO propietarios (documento, nombre, apellido, telefono, email)
VALUES ('1060606060', 'Pedro', 'Díaz', '3056789012', '  Pedro.DIAZ@Mail.com ');
SELECT nombre, email FROM propietarios WHERE documento = '1060606060';
-- Esperado: pedro.diaz@mail.com (sin espacios y en minúsculas)
ROLLBACK;

-- DEMO ERROR 1644 (el SIGNAL del trigger; ejecútalo antes de la sección Z,
-- que borra el trigger: sin él, la fila SÍ se inserta):
-- INSERT INTO propietarios (documento, nombre, apellido, telefono, email) VALUES ('1070707070', 'Ana', 'Ruiz', '3000000000', 'correo-sin-arroba');

-- J2. AFTER DELETE: guarda la mascota borrada (como los casos 1 y 3 del parcial)
DROP TABLE IF EXISTS ej_mascotas_eliminadas;
CREATE TABLE ej_mascotas_eliminadas (
    id               INT          NOT NULL AUTO_INCREMENT,
    mascota_id       INT          NOT NULL,
    nombre           VARCHAR(50)  NOT NULL,
    propietario_id   INT          NOT NULL,
    eliminado_por    VARCHAR(100) NOT NULL,
    fecha_eliminacion TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB;

DROP TRIGGER IF EXISTS tg_ej_mascota_eliminada;
DELIMITER $$
CREATE TRIGGER tg_ej_mascota_eliminada
AFTER DELETE ON mascotas
FOR EACH ROW
BEGIN
    INSERT INTO ej_mascotas_eliminadas (mascota_id, nombre, propietario_id, eliminado_por)
    VALUES (OLD.mascota_id, OLD.nombre, OLD.propietario_id, USER());
END$$
DELIMITER ;

START TRANSACTION;
INSERT INTO mascotas (nombre, especie_id, sexo, propietario_id) VALUES ('Temporal', 5, 'H', 2);
DELETE FROM mascotas WHERE mascota_id = LAST_INSERT_ID();
SELECT mascota_id, nombre, eliminado_por FROM ej_mascotas_eliminadas;
-- Esperado: 1 fila (Temporal)
ROLLBACK;


-- =====================================================================
-- K. VISTAS
-- CONCEPTO: una vista es un SELECT guardado con nombre; se consulta como
-- una tabla pero no guarda datos (se recalcula cada vez). Sirve para
-- simplificar consultas repetidas y para dar acceso a ciertas columnas
-- sin exponer la tabla (GRANT SELECT sobre la vista, ver B4). Una vista
-- con GROUP BY, DISTINCT o agregaciones no se puede actualizar.
-- =====================================================================

-- K1. "Consulta la vista con un filtro"
SELECT mascota, etapa_vida, veterinario, diagnostico
FROM vw_historia_clinica
WHERE etapa_vida = 'Senior';
-- Esperado: 3 filas (Rocky ×2, Nieve)

-- K2. "Crea una vista de resumen por propietario"
CREATE OR REPLACE VIEW ej_vw_resumen_propietario AS
SELECT CONCAT(p.nombre, ' ', p.apellido) AS propietario,
       COUNT(DISTINCT m.mascota_id)      AS mascotas,
       COUNT(c.consulta_id)              AS consultas,
       COALESCE(SUM(c.costo), 0)         AS total_gastado
FROM propietarios p
LEFT JOIN mascotas m          ON m.propietario_id = p.propietario_id
LEFT JOIN consultas_medicas c ON c.mascota_id     = m.mascota_id
GROUP BY p.propietario_id, p.nombre, p.apellido;

SELECT * FROM ej_vw_resumen_propietario ORDER BY total_gastado DESC;
-- Esperado: Laura 2/3/270000 · Andrés 1/2/200000 · Julián 1/1/90000 ·
--           Camila 1/1/70000 · Valentina 1/1/55000

-- K3. Ver, listar y borrar vistas
SHOW CREATE VIEW ej_vw_resumen_propietario;
SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA = 'veterinaria_huellas';
DROP VIEW IF EXISTS ej_vw_resumen_propietario;


-- =====================================================================
-- L. RESPALDO Y RESTAURACIÓN (se ejecuta en la terminal, no en Workbench)
-- CONCEPTO: mysqldump genera un .sql con el CREATE y los INSERT necesarios
-- para reconstruir la BD. Las rutinas y los triggers solo se incluyen si
-- se piden. En Workbench: Server → Data Export / Data Import.
-- =====================================================================
-- Respaldo completo con rutinas y triggers:
--   mysqldump -u root -p --routines --triggers veterinaria_huellas > respaldo_huellas.sql
-- Solo estructura (sin datos):
--   mysqldump -u root -p --no-data veterinaria_huellas > estructura_huellas.sql
-- Una sola tabla:
--   mysqldump -u root -p veterinaria_huellas mascotas > mascotas.sql
-- Restaurar (la BD debe existir, o el dump debe traer CREATE DATABASE):
--   mysql -u root -p veterinaria_huellas < respaldo_huellas.sql
-- Desde el cliente mysql:
--   SOURCE C:/ruta/respaldo_huellas.sql;


-- =====================================================================
-- Z. LIMPIEZA: deja la BD como la entrega el script del parcial
-- =====================================================================
DROP TRIGGER   IF EXISTS tg_ej_email_propietario;
DROP TRIGGER   IF EXISTS tg_ej_mascota_eliminada;
DROP TABLE     IF EXISTS ej_mascotas_eliminadas;
DROP TABLE     IF EXISTS ej_vacunas;
DROP VIEW      IF EXISTS ej_vw_resumen_propietario;
DROP FUNCTION  IF EXISTS ej_categoria_costo;
DROP FUNCTION  IF EXISTS ej_correo_veterinario;
DROP FUNCTION  IF EXISTS ej_total_consultas_mascota;
DROP PROCEDURE IF EXISTS ej_listar_mascotas;
DROP PROCEDURE IF EXISTS ej_consultas_por_mascota;
DROP PROCEDURE IF EXISTS ej_contar_por_especie;
DROP PROCEDURE IF EXISTS ej_estado_email_propietario;
DROP PROCEDURE IF EXISTS ej_aplicar_descuento;
DROP PROCEDURE IF EXISTS ej_registrar_consulta;
DROP USER      IF EXISTS 'practica_huellas'@'localhost';

SHOW FULL TABLES;    -- Esperado: las 6 tablas del parcial + vw_historia_clinica
