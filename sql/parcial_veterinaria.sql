-- =====================================================================
-- PARCIAL FINAL · Bases de Datos II
-- Caso 2: Clínica Veterinaria "Huellas"
--
-- Script único que cumple, en orden, los 9 requerimientos del parcial.
-- El modelo lógico y la normalización (punto 1) están explicados en
-- docs/MODELO.md; aquí se resumen en la sección 1.
--
-- Motor: MySQL 8.0.16 o superior (usa roles y CHECK).
--        No es compatible con MariaDB/XAMPP en la sección de roles.
-- Ejecutar con un usuario que pueda crear usuarios y roles (ej. root).
--
-- ⚠ Borra y recrea la BD veterinaria_huellas y los usuarios/roles de
--   la sección 4. Se puede ejecutar varias veces.
-- =====================================================================


-- =====================================================================
-- 1. MODELO LÓGICO Y NORMALIZACIÓN (resumen; detalle en docs/MODELO.md)
-- ---------------------------------------------------------------------
--   especies 1──N razas 1──N mascotas N──1 propietarios
--   especialidades 1──N veterinarios
--   mascotas 1──N consultas_medicas N──1 veterinarios
--   consultas_medicas 1──N detalle_consultas N──1 tratamientos
--   consultas_medicas ──(trigger UPDATE)──► historial_diagnosticos
--
--   Relaciones N:M:
--   * mascotas ↔ veterinarios, a través de consultas_medicas.
--   * consultas ↔ tratamientos, a través de detalle_consultas
--     (PK compuesta: una consulta no repite un tratamiento).
--   1FN: atributos atómicos (nombre y apellido separados, sin "Dr."
--        dentro del nombre, un teléfono por propietario).
--   2FN: en detalle_consultas (PK compuesta) precio_aplicado depende de
--        la consulta Y del tratamiento, no de una sola parte.
--   3FN: la especie se deduce de la raza, así que mascotas solo guarda
--        raza_id; la especialidad es tabla propia; no se guarda la edad
--        (se deriva de fecha_nacimiento) ni el total de la consulta (se
--        calcula sumando su detalle).
-- =====================================================================


-- =====================================================================
-- 2. ESTRUCTURA Y MODELADO (DDL)
-- =====================================================================
-- El archivo está en UTF-8. Sin esto, un cliente configurado en latin1
-- (ej. el mysql de Docker) guarda "Sofía" doblemente codificado.
SET NAMES utf8mb4;

DROP DATABASE IF EXISTS veterinaria_huellas;
CREATE DATABASE veterinaria_huellas
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE veterinaria_huellas;

-- ---------- Catálogos (no dependen de nadie) ----------
CREATE TABLE propietarios (
    propietario_id INT          NOT NULL AUTO_INCREMENT,
    documento      VARCHAR(20)  NOT NULL,
    nombre         VARCHAR(50)  NOT NULL,
    apellido       VARCHAR(50)  NOT NULL,
    telefono       VARCHAR(20)  NOT NULL,
    email          VARCHAR(100) NULL,
    direccion      VARCHAR(120) NULL,
    PRIMARY KEY (propietario_id),
    UNIQUE KEY uq_propietarios_documento (documento),
    UNIQUE KEY uq_propietarios_email (email)
) ENGINE = InnoDB;

CREATE TABLE especies (
    especie_id INT         NOT NULL AUTO_INCREMENT,
    nombre     VARCHAR(40) NOT NULL,
    PRIMARY KEY (especie_id),
    UNIQUE KEY uq_especies_nombre (nombre)
) ENGINE = InnoDB;

CREATE TABLE especialidades (
    especialidad_id INT         NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(60) NOT NULL,
    PRIMARY KEY (especialidad_id),
    UNIQUE KEY uq_especialidades_nombre (nombre)
) ENGINE = InnoDB;

CREATE TABLE tratamientos (
    tratamiento_id INT           NOT NULL AUTO_INCREMENT,
    nombre         VARCHAR(80)   NOT NULL,
    precio         DECIMAL(10,2) NOT NULL,   -- precio ACTUAL de lista
    PRIMARY KEY (tratamiento_id),
    UNIQUE KEY uq_tratamientos_nombre (nombre),
    CONSTRAINT ck_tratamientos_precio CHECK (precio >= 0)
) ENGINE = InnoDB;

-- ---------- Tablas que dependen de un catálogo ----------
CREATE TABLE razas (
    raza_id    INT         NOT NULL AUTO_INCREMENT,
    nombre     VARCHAR(50) NOT NULL,
    especie_id INT         NOT NULL,
    PRIMARY KEY (raza_id),
    UNIQUE KEY uq_razas_especie_nombre (especie_id, nombre),  -- "Criollo" puede existir en varias especies
    CONSTRAINT fk_razas_especie
        FOREIGN KEY (especie_id) REFERENCES especies (especie_id)
) ENGINE = InnoDB;

CREATE TABLE veterinarios (
    veterinario_id      INT         NOT NULL AUTO_INCREMENT,
    tarjeta_profesional VARCHAR(20) NOT NULL,
    nombre              VARCHAR(50) NOT NULL,
    apellido            VARCHAR(50) NOT NULL,
    telefono            VARCHAR(20) NOT NULL,
    especialidad_id     INT         NOT NULL,
    PRIMARY KEY (veterinario_id),
    UNIQUE KEY uq_veterinarios_tarjeta (tarjeta_profesional),
    CONSTRAINT fk_veterinarios_especialidad
        FOREIGN KEY (especialidad_id) REFERENCES especialidades (especialidad_id)
) ENGINE = InnoDB;

CREATE TABLE mascotas (
    mascota_id       INT         NOT NULL AUTO_INCREMENT,
    nombre           VARCHAR(50) NOT NULL,
    raza_id          INT         NOT NULL,   -- la especie se obtiene a través de la raza
    sexo             CHAR(1)     NOT NULL,
    fecha_nacimiento DATE        NULL,       -- NULL = se desconoce (ej. rescatada)
    propietario_id   INT         NOT NULL,
    PRIMARY KEY (mascota_id),
    CONSTRAINT ck_mascotas_sexo CHECK (sexo IN ('M', 'H')),
    CONSTRAINT fk_mascotas_raza
        FOREIGN KEY (raza_id) REFERENCES razas (raza_id),
    CONSTRAINT fk_mascotas_propietario
        FOREIGN KEY (propietario_id) REFERENCES propietarios (propietario_id)
) ENGINE = InnoDB;

-- ---------- Movimientos ----------
CREATE TABLE consultas_medicas (
    consulta_id    INT          NOT NULL AUTO_INCREMENT,
    mascota_id     INT          NOT NULL,
    veterinario_id INT          NOT NULL,
    fecha_consulta DATETIME     NOT NULL,
    motivo         VARCHAR(150) NOT NULL,
    diagnostico    VARCHAR(255) NULL,     -- NULL = aún sin diagnóstico
    PRIMARY KEY (consulta_id),
    CONSTRAINT fk_consultas_mascota
        FOREIGN KEY (mascota_id) REFERENCES mascotas (mascota_id),
    CONSTRAINT fk_consultas_veterinario
        FOREIGN KEY (veterinario_id) REFERENCES veterinarios (veterinario_id)
) ENGINE = InnoDB;

-- N:M consultas ↔ tratamientos.
-- precio_aplicado NO es redundante con tratamientos.precio: es lo que se
-- cobró ese día. Si el precio de lista cambia, las consultas pasadas no
-- deben cambiar de valor.
CREATE TABLE detalle_consultas (
    consulta_id     INT           NOT NULL,
    tratamiento_id  INT           NOT NULL,
    precio_aplicado DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (consulta_id, tratamiento_id),
    CONSTRAINT ck_detalle_precio CHECK (precio_aplicado >= 0),
    CONSTRAINT fk_detalle_consulta
        FOREIGN KEY (consulta_id) REFERENCES consultas_medicas (consulta_id),
    CONSTRAINT fk_detalle_tratamiento
        FOREIGN KEY (tratamiento_id) REFERENCES tratamientos (tratamiento_id)
) ENGINE = InnoDB;

-- Tabla de auditoría que llena el trigger de la sección 5.
-- A propósito NO tiene FK hacia consultas_medicas: si una consulta se
-- borra, su historial debe conservarse.
CREATE TABLE historial_diagnosticos (
    historial_id         INT          NOT NULL AUTO_INCREMENT,
    consulta_id          INT          NOT NULL,
    mascota_id           INT          NOT NULL,
    diagnostico_anterior VARCHAR(255) NULL,
    diagnostico_nuevo    VARCHAR(255) NULL,
    modificado_por       VARCHAR(100) NOT NULL,
    fecha_cambio         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (historial_id),
    KEY ix_historial_consulta (consulta_id)
) ENGINE = InnoDB;


-- =====================================================================
-- 3. POBLACIÓN DE DATOS (DML)
-- Se insertan en orden de dependencia: primero los padres.
-- historial_diagnosticos no se llena a mano: la llena el trigger con los
-- 5 UPDATE de prueba de la sección 5.
-- =====================================================================
INSERT INTO propietarios (documento, nombre, apellido, telefono, email, direccion) VALUES
    ('1010101010', 'Laura',     'Gómez',  '3001234567', 'laura.gomez@mail.com',     'Cra 10 # 20-30'),
    ('1020202020', 'Andrés',    'Rojas',  '3012345678', 'andres.rojas@mail.com',    'Cl 45 # 12-08'),
    ('1030303030', 'Camila',    'Torres', '3023456789', 'camila.torres@mail.com',   'Av 6N # 23-50'),
    ('1040404040', 'Julián',    'Moreno', '3034567890', NULL,                       'Cl 5 # 66-14'),
    ('1050505050', 'Valentina', 'Ríos',   '3045678901', 'valentina.rios@mail.com',  'Cra 100 # 11-60');

INSERT INTO especies (nombre) VALUES
    ('Perro'), ('Gato'), ('Ave'), ('Conejo'), ('Hámster');   -- Hámster: sin razas ni mascotas

INSERT INTO especialidades (nombre) VALUES
    ('Medicina general'), ('Cirugía'), ('Dermatología'), ('Animales exóticos'), ('Odontología');

INSERT INTO tratamientos (nombre, precio) VALUES
    ('Consulta general',          50000),
    ('Vacuna antirrábica',        45000),
    ('Desparasitación',           25000),
    ('Curación de herida',        35000),
    ('Radiografía',               80000),
    ('Examen de sangre',          60000),
    ('Tratamiento dermatológico', 40000),
    ('Limpieza dental',           70000);   -- nunca aplicado: prueba de anti-join

INSERT INTO razas (nombre, especie_id) VALUES
    ('Labrador',       1),
    ('Pastor Alemán',  1),
    ('Criollo',        1),
    ('Siamés',         2),
    ('Periquito',      3),
    ('Cabeza de León', 4);

INSERT INTO veterinarios (tarjeta_profesional, nombre, apellido, telefono, especialidad_id) VALUES
    ('TP-1001', 'Sofía',   'Martínez', '3101112233', 1),
    ('TP-1002', 'Carlos',  'Pérez',    '3102223344', 2),
    ('TP-1003', 'Natalia', 'Vargas',   '3103334455', 3),
    ('TP-1004', 'Felipe',  'Castro',   '3104445566', 4),
    ('TP-1005', 'Mariana', 'López',    '3105556677', 5);   -- sin consultas: prueba del LEFT JOIN

-- Las fechas de nacimiento son relativas a hoy para que la etapa de vida
-- (función de la sección 6) dé siempre el mismo resultado.
INSERT INTO mascotas (nombre, raza_id, sexo, fecha_nacimiento, propietario_id) VALUES
    ('Max',   1, 'M', DATE_SUB(CURDATE(), INTERVAL 5 YEAR),  1), -- Labrador · Adulto
    ('Luna',  4, 'H', DATE_SUB(CURDATE(), INTERVAL 6 MONTH), 1), -- Siamés · Cachorro
    ('Rocky', 2, 'M', DATE_SUB(CURDATE(), INTERVAL 10 YEAR), 2), -- Pastor Alemán · Senior
    ('Kiwi',  5, 'H', DATE_SUB(CURDATE(), INTERVAL 2 YEAR),  3), -- Periquito · Adulto
    ('Nieve', 6, 'H', DATE_SUB(CURDATE(), INTERVAL 8 YEAR),  4), -- Cabeza de León · Senior
    ('Toby',  3, 'M', NULL,                                  5); -- Criollo · Desconocido (rescatado)

INSERT INTO consultas_medicas (mascota_id, veterinario_id, fecha_consulta, motivo, diagnostico) VALUES
    (1, 1, '2026-09-02 09:00:00', 'Vacunación anual',       'Sano'),
    (2, 1, '2026-09-10 10:30:00', 'Diarrea',                'Gastroenteritis leve'),
    (3, 2, '2026-09-15 15:00:00', 'Cojera en pata trasera', 'Artrosis de cadera'),
    (4, 4, '2026-10-01 11:00:00', 'Pérdida de plumas',      'Pendiente de exámenes'),
    (5, 3, '2026-10-05 16:00:00', 'Picazón constante',      'Dermatitis alérgica'),
    (1, 1, '2026-10-20 08:30:00', 'Herida en la pata',      'Laceración superficial'),
    (3, 1, '2026-11-02 14:00:00', 'Control de artrosis',    NULL),
    (6, 1, '2026-11-10 09:30:00', 'Revisión de ingreso',    'Sano');

-- La consulta 1 se cobró con el precio anterior de la consulta general
-- (45.000); desde entonces vale 50.000. Por eso se guarda precio_aplicado.
INSERT INTO detalle_consultas (consulta_id, tratamiento_id, precio_aplicado) VALUES
    (1, 1, 45000), (1, 2, 45000),                  -- total  90.000
    (2, 1, 50000), (2, 6, 60000),                  -- total 110.000
    (3, 1, 50000), (3, 5, 80000),                  -- total 130.000
    (4, 1, 50000), (4, 6, 60000),                  -- total 110.000
    (5, 1, 50000), (5, 7, 40000),                  -- total  90.000
    (6, 1, 50000), (6, 4, 35000),                  -- total  85.000
    (7, 1, 50000),                                 -- total  50.000
    (8, 1, 50000), (8, 3, 25000), (8, 2, 45000);   -- total 120.000

SELECT 'propietarios' AS tabla, COUNT(*) AS filas FROM propietarios
UNION ALL SELECT 'especies',          COUNT(*) FROM especies
UNION ALL SELECT 'especialidades',    COUNT(*) FROM especialidades
UNION ALL SELECT 'tratamientos',      COUNT(*) FROM tratamientos
UNION ALL SELECT 'razas',             COUNT(*) FROM razas
UNION ALL SELECT 'veterinarios',      COUNT(*) FROM veterinarios
UNION ALL SELECT 'mascotas',          COUNT(*) FROM mascotas
UNION ALL SELECT 'consultas_medicas', COUNT(*) FROM consultas_medicas
UNION ALL SELECT 'detalle_consultas', COUNT(*) FROM detalle_consultas;
-- Esperado: 5, 5, 5, 8, 6, 5, 6, 8, 16


-- =====================================================================
-- 4. SEGURIDAD, USUARIOS Y ROLES
-- Contraseñas de DEMOSTRACIÓN: cumplen la política validate_password
-- (mayúscula, minúscula, número, símbolo, 8+ caracteres), pero al estar
-- en un repositorio ya no son secretas. En un sistema real se cambian.
-- =====================================================================
DROP USER IF EXISTS 'admin_huellas'@'localhost', 'recepcion_huellas'@'localhost';
DROP ROLE IF EXISTS 'rol_admin', 'rol_empleado';

CREATE ROLE 'rol_admin', 'rol_empleado';

-- Admin: DML completo sobre la BD.  Empleado (recepción): consultar y registrar.
GRANT SELECT, INSERT, UPDATE, DELETE ON veterinaria_huellas.* TO 'rol_admin';
GRANT SELECT, INSERT                 ON veterinaria_huellas.* TO 'rol_empleado';

CREATE USER 'admin_huellas'@'localhost'     IDENTIFIED BY 'Adm1n.Huellas#2026';
CREATE USER 'recepcion_huellas'@'localhost' IDENTIFIED BY 'Recep.Huellas#2026';

GRANT 'rol_admin'    TO 'admin_huellas'@'localhost';
GRANT 'rol_empleado' TO 'recepcion_huellas'@'localhost';

-- Sin esto, el rol queda asignado pero inactivo al iniciar sesión.
SET DEFAULT ROLE ALL TO 'admin_huellas'@'localhost', 'recepcion_huellas'@'localhost';

SHOW GRANTS FOR 'rol_admin';
SHOW GRANTS FOR 'rol_empleado';
SHOW GRANTS FOR 'recepcion_huellas'@'localhost' USING 'rol_empleado';

-- Prueba manual (nueva conexión como recepcion_huellas):
--   SELECT CURRENT_ROLE();                          -- `rol_empleado`@`%`
--   INSERT INTO veterinaria_huellas.especies (nombre) VALUES ('Tortuga');  -- OK
--   DELETE FROM veterinaria_huellas.especies WHERE nombre = 'Tortuga';     -- ERROR 1142


-- =====================================================================
-- 5. TRIGGER DE AUDITORÍA
-- Respalda el diagnóstico anterior cada vez que se actualiza una consulta.
-- * AFTER UPDATE: solo audita cambios que realmente se guardaron.
-- * <=> (igualdad segura con NULL): con <> un cambio desde o hacia NULL
--   daría NULL y no se registraría.
-- * USER() y no CURRENT_USER(): dentro de un trigger CURRENT_USER()
--   devuelve el creador (DEFINER) del trigger, no quien hizo el UPDATE.
-- =====================================================================
DROP TRIGGER IF EXISTS tg_respaldo_diagnostico;

DELIMITER $$
CREATE TRIGGER tg_respaldo_diagnostico
AFTER UPDATE ON consultas_medicas
FOR EACH ROW
BEGIN
    IF NOT (OLD.diagnostico <=> NEW.diagnostico) THEN
        INSERT INTO historial_diagnosticos
            (consulta_id, mascota_id, diagnostico_anterior, diagnostico_nuevo, modificado_por)
        VALUES
            (OLD.consulta_id, OLD.mascota_id, OLD.diagnostico, NEW.diagnostico, USER());
    END IF;
END$$
DELIMITER ;

-- Pruebas: 5 cambios de diagnóstico + 1 cambio que NO debe auditarse
UPDATE consultas_medicas SET diagnostico = 'Deficiencia de vitamina A'           WHERE consulta_id = 4;
UPDATE consultas_medicas SET diagnostico = 'Artrosis controlada'                 WHERE consulta_id = 7; -- NULL → valor
UPDATE consultas_medicas SET diagnostico = 'Gastroenteritis por cambio de dieta' WHERE consulta_id = 2;
UPDATE consultas_medicas SET diagnostico = 'Dermatitis por pulgas'               WHERE consulta_id = 5;
UPDATE consultas_medicas SET diagnostico = 'Displasia de cadera'                 WHERE consulta_id = 3;
UPDATE consultas_medicas SET motivo = 'Vacunación anual y chequeo'               WHERE consulta_id = 1; -- no cambia diagnóstico

SELECT historial_id, consulta_id, diagnostico_anterior, diagnostico_nuevo, modificado_por
FROM historial_diagnosticos
ORDER BY historial_id;
-- Esperado: 5 filas (consultas 4, 7, 2, 5, 3). La 7 tiene diagnostico_anterior NULL.


-- =====================================================================
-- 6. FUNCIÓN CON LÓGICA CONDICIONAL (CASE)
-- Clasifica la etapa de vida de la mascota según su edad en años.
-- DETERMINISTIC: la misma edad da siempre la misma etapa.
-- NO SQL: solo usa su parámetro, no lee tablas.
-- =====================================================================
DROP FUNCTION IF EXISTS fn_etapa_vida;

DELIMITER $$
CREATE FUNCTION fn_etapa_vida(p_edad INT)
RETURNS VARCHAR(20)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CASE
        WHEN p_edad IS NULL THEN 'Desconocido'
        WHEN p_edad < 1     THEN 'Cachorro'
        WHEN p_edad < 7     THEN 'Adulto'
        ELSE                     'Senior'
    END;
END$$
DELIMITER ;

-- Pruebas
SELECT fn_etapa_vida(0) AS e0, fn_etapa_vida(3) AS e3, fn_etapa_vida(7) AS e7, fn_etapa_vida(NULL) AS e_null;
-- Esperado: Cachorro, Adulto, Senior, Desconocido

SELECT nombre,
       TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE())                AS edad,
       fn_etapa_vida(TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE())) AS etapa
FROM mascotas
ORDER BY mascota_id;
-- Esperado: Max Adulto, Luna Cachorro, Rocky Senior, Kiwi Adulto, Nieve Senior, Toby Desconocido


-- =====================================================================
-- 7. PROCEDIMIENTO ALMACENADO CON JOIN
-- Recibe el ID del veterinario y devuelve por OUT: su nombre, su
-- especialidad, cuántas consultas atendió, cuántas mascotas distintas
-- trató y sus nombres.
-- * INNER JOIN con especialidades (todo veterinario tiene una) y
--   LEFT JOIN con consultas: un veterinario sin consultas devuelve 0.
-- * Sin GROUP BY, una consulta de agregación devuelve siempre 1 fila,
--   así que el SELECT ... INTO nunca falla. Si el ID no existe, el nombre
--   queda en NULL (así se distingue de "existe pero no tiene consultas").
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_estadisticas_veterinario;

DELIMITER $$
CREATE PROCEDURE sp_estadisticas_veterinario(
    IN  p_veterinario_id    INT,
    OUT p_veterinario       VARCHAR(101),
    OUT p_especialidad      VARCHAR(60),
    OUT p_total_consultas   INT,
    OUT p_mascotas_tratadas INT,
    OUT p_lista_mascotas    VARCHAR(500)
)
BEGIN
    SELECT
        MAX(CONCAT(v.nombre, ' ', v.apellido)),
        MAX(e.nombre),
        COUNT(c.consulta_id),
        COUNT(DISTINCT c.mascota_id),
        GROUP_CONCAT(DISTINCT m.nombre ORDER BY m.nombre SEPARATOR ', ')
    INTO
        p_veterinario,
        p_especialidad,
        p_total_consultas,
        p_mascotas_tratadas,
        p_lista_mascotas
    FROM veterinarios v
    INNER JOIN especialidades e  ON e.especialidad_id = v.especialidad_id
    LEFT JOIN consultas_medicas c ON c.veterinario_id = v.veterinario_id
    LEFT JOIN mascotas m          ON m.mascota_id     = c.mascota_id
    WHERE v.veterinario_id = p_veterinario_id;
END$$
DELIMITER ;

-- Pruebas
CALL sp_estadisticas_veterinario(1, @vet, @esp, @consultas, @mascotas, @lista);
SELECT @vet AS veterinario, @esp AS especialidad, @consultas AS consultas,
       @mascotas AS mascotas_tratadas, @lista AS lista;
-- Esperado: Sofía Martínez, Medicina general, 5, 4, 'Luna, Max, Rocky, Toby' (Max fue 2 veces)

CALL sp_estadisticas_veterinario(5, @vet, @esp, @consultas, @mascotas, @lista);
SELECT @vet AS veterinario, @esp AS especialidad, @consultas AS consultas,
       @mascotas AS mascotas_tratadas, @lista AS lista;
-- Esperado: Mariana López, Odontología, 0, 0, NULL

CALL sp_estadisticas_veterinario(999, @vet, @esp, @consultas, @mascotas, @lista);
SELECT @vet AS veterinario, @esp AS especialidad, @consultas AS consultas,
       @mascotas AS mascotas_tratadas, @lista AS lista;
-- Esperado: NULL, NULL, 0, 0, NULL (el veterinario no existe)


-- =====================================================================
-- 8. CONSULTAS COMPLEJAS (REPORTES)
-- =====================================================================

-- 8.1 Consultas atendidas e ingresos por veterinario, del que más factura
-- al que menos. COUNT(DISTINCT): al unir con detalle_consultas cada
-- consulta aparece una vez por tratamiento, y COUNT(*) la contaría de más.
SELECT
    CONCAT(v.nombre, ' ', v.apellido)   AS veterinario,
    e.nombre                            AS especialidad,
    COUNT(DISTINCT c.consulta_id)       AS total_consultas,
    COALESCE(SUM(d.precio_aplicado), 0) AS ingresos
FROM veterinarios v
INNER JOIN especialidades e     ON e.especialidad_id = v.especialidad_id
LEFT JOIN consultas_medicas c   ON c.veterinario_id  = v.veterinario_id
LEFT JOIN detalle_consultas d   ON d.consulta_id     = c.consulta_id
GROUP BY v.veterinario_id, v.nombre, v.apellido, e.nombre
ORDER BY ingresos DESC, total_consultas DESC;
-- Esperado: Sofía Martínez 5 / 455000 · Carlos Pérez 1 / 130000 ·
--           Felipe Castro 1 / 110000 · Natalia Vargas 1 / 90000 ·
--           Mariana López 0 / 0

-- 8.2 Tratamientos más aplicados y lo que han facturado.
SELECT
    t.nombre                            AS tratamiento,
    t.precio                            AS precio_actual,
    COUNT(d.consulta_id)                AS veces_aplicado,
    COALESCE(SUM(d.precio_aplicado), 0) AS facturado
FROM tratamientos t
LEFT JOIN detalle_consultas d ON d.tratamiento_id = t.tratamiento_id
GROUP BY t.tratamiento_id, t.nombre, t.precio
ORDER BY veces_aplicado DESC, facturado DESC;
-- Esperado: Consulta general 8 / 395000 (una se cobró a 45000) ·
--           Examen de sangre 2 / 120000 · Vacuna antirrábica 2 / 90000 · … ·
--           Limpieza dental 0 / 0


-- =====================================================================
-- 9. VISTA
-- Historia clínica legible: une 8 tablas, usa la función de la sección 6
-- y calcula el total de cada consulta desde su detalle (tabla derivada).
-- =====================================================================
CREATE OR REPLACE VIEW vw_historia_clinica AS
SELECT
    c.consulta_id,
    c.fecha_consulta,
    m.nombre                                                          AS mascota,
    es.nombre                                                         AS especie,
    r.nombre                                                          AS raza,
    fn_etapa_vida(TIMESTAMPDIFF(YEAR, m.fecha_nacimiento, CURDATE())) AS etapa_vida,
    CONCAT(p.nombre, ' ', p.apellido)                                 AS propietario,
    p.telefono                                                        AS telefono_propietario,
    CONCAT(v.nombre, ' ', v.apellido)                                 AS veterinario,
    ep.nombre                                                         AS especialidad,
    c.motivo,
    c.diagnostico,
    d.tratamientos,
    COALESCE(d.total, 0)                                              AS total
FROM consultas_medicas c
INNER JOIN mascotas       m  ON m.mascota_id      = c.mascota_id
INNER JOIN razas          r  ON r.raza_id         = m.raza_id
INNER JOIN especies       es ON es.especie_id     = r.especie_id
INNER JOIN propietarios   p  ON p.propietario_id  = m.propietario_id
INNER JOIN veterinarios   v  ON v.veterinario_id  = c.veterinario_id
INNER JOIN especialidades ep ON ep.especialidad_id = v.especialidad_id
LEFT JOIN (
    SELECT dc.consulta_id,
           GROUP_CONCAT(t.nombre ORDER BY t.nombre SEPARATOR ', ') AS tratamientos,
           SUM(dc.precio_aplicado)                                 AS total
    FROM detalle_consultas dc
    INNER JOIN tratamientos t ON t.tratamiento_id = dc.tratamiento_id
    GROUP BY dc.consulta_id
) d ON d.consulta_id = c.consulta_id;

-- Pruebas
SELECT * FROM vw_historia_clinica ORDER BY fecha_consulta;
-- Esperado: 8 filas; la suma de la columna total es 785000

SELECT consulta_id, mascota, raza, veterinario, tratamientos, total
FROM vw_historia_clinica WHERE mascota = 'Rocky';
-- Esperado: 2 consultas (Carlos Pérez 130000 y Sofía Martínez 50000), etapa Senior
