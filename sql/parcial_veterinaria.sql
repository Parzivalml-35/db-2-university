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
--   propietarios 1 ── N mascotas N ── 1 especies
--   mascotas     1 ── N consultas_medicas N ── 1 veterinarios
--   consultas_medicas ──(trigger UPDATE)──► historial_diagnosticos
--
--   * consultas_medicas resuelve la relación N:M entre mascotas y
--     veterinarios (una mascota la atienden varios veterinarios y un
--     veterinario atiende muchas mascotas).
--   * 1FN: todos los atributos son atómicos (nombre y apellido separados,
--     un teléfono por propietario).
--   * 2FN: todas las claves primarias son simples (AUTO_INCREMENT), así
--     que no hay dependencias parciales.
--   * 3FN: la especie va en su propia tabla (no se repite "Perro" en cada
--     mascota) y no se guarda la edad, porque es un dato derivado de
--     fecha_nacimiento que se desactualiza con el tiempo.
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

CREATE TABLE mascotas (
    mascota_id       INT         NOT NULL AUTO_INCREMENT,
    nombre           VARCHAR(50) NOT NULL,
    especie_id       INT         NOT NULL,
    raza             VARCHAR(50) NULL,
    sexo             CHAR(1)     NOT NULL,
    fecha_nacimiento DATE        NULL,     -- NULL = se desconoce (ej. rescatada)
    propietario_id   INT         NOT NULL,
    PRIMARY KEY (mascota_id),
    CONSTRAINT ck_mascotas_sexo CHECK (sexo IN ('M', 'H')),
    CONSTRAINT fk_mascotas_especie
        FOREIGN KEY (especie_id) REFERENCES especies (especie_id),
    CONSTRAINT fk_mascotas_propietario
        FOREIGN KEY (propietario_id) REFERENCES propietarios (propietario_id)
) ENGINE = InnoDB;

CREATE TABLE veterinarios (
    veterinario_id      INT         NOT NULL AUTO_INCREMENT,
    tarjeta_profesional VARCHAR(20) NOT NULL,
    nombre              VARCHAR(50) NOT NULL,
    apellido            VARCHAR(50) NOT NULL,
    especialidad        VARCHAR(60) NOT NULL,
    PRIMARY KEY (veterinario_id),
    UNIQUE KEY uq_veterinarios_tarjeta (tarjeta_profesional)
) ENGINE = InnoDB;

CREATE TABLE consultas_medicas (
    consulta_id    INT           NOT NULL AUTO_INCREMENT,
    mascota_id     INT           NOT NULL,
    veterinario_id INT           NOT NULL,
    fecha_consulta DATETIME      NOT NULL,
    motivo         VARCHAR(150)  NOT NULL,
    diagnostico    VARCHAR(255)  NULL,     -- NULL = aún sin diagnóstico
    costo          DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (consulta_id),
    CONSTRAINT ck_consultas_costo CHECK (costo >= 0),
    CONSTRAINT fk_consultas_mascota
        FOREIGN KEY (mascota_id) REFERENCES mascotas (mascota_id),
    CONSTRAINT fk_consultas_veterinario
        FOREIGN KEY (veterinario_id) REFERENCES veterinarios (veterinario_id)
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
    ('Perro'), ('Gato'), ('Ave'), ('Conejo'), ('Hámster');

-- Las fechas de nacimiento son relativas a hoy para que la etapa de vida
-- (función de la sección 6) dé siempre el mismo resultado.
INSERT INTO mascotas (nombre, especie_id, raza, sexo, fecha_nacimiento, propietario_id) VALUES
    ('Max',   1, 'Labrador',        'M', DATE_SUB(CURDATE(), INTERVAL 5 YEAR),   1), -- Adulto
    ('Luna',  2, 'Siamés',          'H', DATE_SUB(CURDATE(), INTERVAL 6 MONTH),  1), -- Cachorro
    ('Rocky', 1, 'Pastor Alemán',   'M', DATE_SUB(CURDATE(), INTERVAL 10 YEAR),  2), -- Senior
    ('Kiwi',  3, 'Periquito',       'H', DATE_SUB(CURDATE(), INTERVAL 2 YEAR),   3), -- Adulto
    ('Nieve', 4, 'Cabeza de León',  'H', DATE_SUB(CURDATE(), INTERVAL 8 YEAR),   4), -- Senior
    ('Toby',  1, 'Criollo',         'M', NULL,                                   5); -- Desconocido (rescatado)

INSERT INTO veterinarios (tarjeta_profesional, nombre, apellido, especialidad) VALUES
    ('TP-1001', 'Sofía',   'Martínez', 'Medicina general'),
    ('TP-1002', 'Carlos',  'Pérez',    'Cirugía'),
    ('TP-1003', 'Natalia', 'Vargas',   'Dermatología'),
    ('TP-1004', 'Felipe',  'Castro',   'Animales exóticos'),
    ('TP-1005', 'Mariana', 'López',    'Odontología');   -- sin consultas: prueba del LEFT JOIN

INSERT INTO consultas_medicas (mascota_id, veterinario_id, fecha_consulta, motivo, diagnostico, costo) VALUES
    (1, 1, '2026-09-02 09:00:00', 'Vacunación anual',          'Sano',                   60000),
    (2, 1, '2026-09-10 10:30:00', 'Diarrea',                   'Gastroenteritis leve',   85000),
    (3, 2, '2026-09-15 15:00:00', 'Cojera en pata trasera',    'Artrosis de cadera',    150000),
    (4, 4, '2026-10-01 11:00:00', 'Pérdida de plumas',         'Pendiente de exámenes',  70000),
    (5, 3, '2026-10-05 16:00:00', 'Picazón constante',         'Dermatitis alérgica',    90000),
    (1, 1, '2026-10-20 08:30:00', 'Herida en la pata',         'Laceración superficial',120000),
    (3, 1, '2026-11-02 14:00:00', 'Control de artrosis',       NULL,                     50000),
    (6, 1, '2026-11-10 09:30:00', 'Revisión de ingreso',       'Sano',                   55000);

SELECT 'propietarios' AS tabla, COUNT(*) AS filas FROM propietarios
UNION ALL SELECT 'especies',          COUNT(*) FROM especies
UNION ALL SELECT 'mascotas',          COUNT(*) FROM mascotas
UNION ALL SELECT 'veterinarios',      COUNT(*) FROM veterinarios
UNION ALL SELECT 'consultas_medicas', COUNT(*) FROM consultas_medicas;
-- Esperado: 5, 5, 6, 5, 8


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
UPDATE consultas_medicas SET costo = 65000                                       WHERE consulta_id = 1; -- no cambia diagnóstico

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
-- Recibe el ID del veterinario y devuelve por OUT: su nombre, cuántas
-- consultas atendió, cuántas mascotas distintas trató y sus nombres.
-- * LEFT JOIN: un veterinario sin consultas devuelve 0, no NULL.
-- * Sin GROUP BY, una consulta de agregación devuelve siempre 1 fila,
--   así que el SELECT ... INTO nunca falla. Si el ID no existe, el nombre
--   queda en NULL (así se distingue de "existe pero no tiene consultas").
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_estadisticas_veterinario;

DELIMITER $$
CREATE PROCEDURE sp_estadisticas_veterinario(
    IN  p_veterinario_id    INT,
    OUT p_veterinario       VARCHAR(101),
    OUT p_total_consultas   INT,
    OUT p_mascotas_tratadas INT,
    OUT p_lista_mascotas    VARCHAR(500)
)
BEGIN
    SELECT
        MAX(CONCAT(v.nombre, ' ', v.apellido)),
        COUNT(c.consulta_id),
        COUNT(DISTINCT c.mascota_id),
        GROUP_CONCAT(DISTINCT m.nombre ORDER BY m.nombre SEPARATOR ', ')
    INTO
        p_veterinario,
        p_total_consultas,
        p_mascotas_tratadas,
        p_lista_mascotas
    FROM veterinarios v
    LEFT JOIN consultas_medicas c ON c.veterinario_id = v.veterinario_id
    LEFT JOIN mascotas m          ON m.mascota_id     = c.mascota_id
    WHERE v.veterinario_id = p_veterinario_id;
END$$
DELIMITER ;

-- Pruebas
CALL sp_estadisticas_veterinario(1, @vet, @consultas, @mascotas, @lista);
SELECT @vet AS veterinario, @consultas AS consultas, @mascotas AS mascotas_tratadas, @lista AS lista;
-- Esperado: Sofía Martínez, 5, 4, 'Luna, Max, Rocky, Toby' (Max fue 2 veces)

CALL sp_estadisticas_veterinario(5, @vet, @consultas, @mascotas, @lista);
SELECT @vet AS veterinario, @consultas AS consultas, @mascotas AS mascotas_tratadas, @lista AS lista;
-- Esperado: Mariana López, 0, 0, NULL

CALL sp_estadisticas_veterinario(999, @vet, @consultas, @mascotas, @lista);
SELECT @vet AS veterinario, @consultas AS consultas, @mascotas AS mascotas_tratadas, @lista AS lista;
-- Esperado: NULL, 0, 0, NULL (el veterinario no existe)


-- =====================================================================
-- 8. CONSULTA COMPLEJA (REPORTE)
-- Consultas atendidas e ingresos por veterinario, del que más factura
-- al que menos. LEFT JOIN + COALESCE para incluir a quien no tiene.
-- =====================================================================
SELECT
    CONCAT(v.nombre, ' ', v.apellido) AS veterinario,
    v.especialidad,
    COUNT(c.consulta_id)              AS total_consultas,
    COALESCE(SUM(c.costo), 0)         AS ingresos
FROM veterinarios v
LEFT JOIN consultas_medicas c ON c.veterinario_id = v.veterinario_id
GROUP BY v.veterinario_id, v.nombre, v.apellido, v.especialidad
ORDER BY ingresos DESC, total_consultas DESC;
-- Esperado: Sofía Martínez 5 / 375000 · Carlos Pérez 1 / 150000 ·
--           Natalia Vargas 1 / 90000 · Felipe Castro 1 / 70000 ·
--           Mariana López 0 / 0


-- =====================================================================
-- 9. VISTA
-- Historia clínica legible: une las 5 tablas y usa la función de la
-- sección 6 para mostrar la etapa de vida.
-- =====================================================================
CREATE OR REPLACE VIEW vw_historia_clinica AS
SELECT
    c.consulta_id,
    c.fecha_consulta,
    m.nombre                                                          AS mascota,
    e.nombre                                                          AS especie,
    fn_etapa_vida(TIMESTAMPDIFF(YEAR, m.fecha_nacimiento, CURDATE())) AS etapa_vida,
    CONCAT(p.nombre, ' ', p.apellido)                                 AS propietario,
    p.telefono                                                        AS telefono_propietario,
    CONCAT(v.nombre, ' ', v.apellido)                                 AS veterinario,
    c.motivo,
    c.diagnostico,
    c.costo
FROM consultas_medicas c
INNER JOIN mascotas     m ON m.mascota_id     = c.mascota_id
INNER JOIN especies     e ON e.especie_id     = m.especie_id
INNER JOIN propietarios p ON p.propietario_id = m.propietario_id
INNER JOIN veterinarios v ON v.veterinario_id = c.veterinario_id;

-- Pruebas
SELECT * FROM vw_historia_clinica ORDER BY fecha_consulta;
-- Esperado: 8 filas

SELECT * FROM vw_historia_clinica WHERE mascota = 'Rocky';
-- Esperado: 2 consultas (Carlos Pérez y Sofía Martínez), etapa Senior
