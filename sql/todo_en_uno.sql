-- =====================================================================
-- TODO EN UNO · generado por generar_todo_en_uno.sh — NO editar a mano.
-- Crea la BD university, la tabla users, las 3 funciones, los
-- 3 procedimientos y ejecuta todas las pruebas.
-- =====================================================================

-- >>>>>>>>>>>>>>>>>>>> 00_esquema_y_datos.sql
-- =====================================================================
-- 00 · Esquema y datos de prueba: BD `university`, tabla `users`
-- =====================================================================
-- Esquema RECONSTRUIDO a partir de las columnas que usan los apuntes de
-- clase (user_id, name, surname, age, init_date, email, company_id).
-- Si tienes el CREATE TABLE original de clase, úsalo en su lugar.
--
-- ⚠ ADVERTENCIA: este script BORRA y recrea la tabla `users` dentro de
--   `university`. Si el PC ya tiene una BD `university` con datos que
--   quieras conservar, revisa antes con:  SHOW DATABASES;
-- =====================================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS university
    DEFAULT CHARACTER SET utf8mb4;   -- sin COLLATE fijo: así también corre en MariaDB/XAMPP

USE university;

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id     INT          NOT NULL AUTO_INCREMENT,
    name        VARCHAR(50)  NOT NULL,
    surname     VARCHAR(50)  NULL,
    age         INT          NULL,
    init_date   DATE         NULL,
    email       VARCHAR(100) NULL,
    company_id  INT          NULL,
    PRIMARY KEY (user_id)
);

-- Datos pensados para que cada ejercicio muestre todos sus casos:
--   * ID 1 Marcela Hernandez  -> prueba de get_user_stats
--   * ID 3 Claudia            -> coincide con el ejemplo de los apuntes
--   * 3 personas 'Fernandez'  -> prueba de count_by_surname
--   * age NULL / 17 / 18 / 16 -> los tres casos de es_mayor_edad
--   * email NULL              -> caso 'Pendiente' de check_email_status
--   * surname NULL            -> caso borde de formato_correo
--   * init_date NULL          -> caso borde de antiguedad_usuario
INSERT INTO users (user_id, name, surname, age, init_date, email, company_id) VALUES
    (1,  'Marcela',   'Hernandez', 25,   '2019-02-15', 'marcela.hernandez@gmail.com',  1),
    (2,  'Carlos',    'Fernandez', 32,   '2018-08-01', 'carlos.fernandez@gmail.com',   1),
    (3,  'Claudia',   'Fernandez', 17,   '2023-03-10', NULL,                           2),
    (4,  'Andres',    'Fernandez', 18,   '2024-01-20', 'andres.fernandez@hotmail.com', 2),
    (5,  'Laura',     'Gomez',     NULL, '2020-06-05', 'laura.gomez@gmail.com',        NULL),
    (6,  'Jorge',     'Martinez',  45,   '2015-11-30', NULL,                           3),
    (7,  'Valentina', NULL,        22,   '2022-09-12', 'valentina@gmail.com',          NULL),
    (8,  'Marcela',   'Rodriguez', 29,   '2021-04-18', 'marcela.rodriguez@gmail.com',  3),
    (9,  'Santiago',  'Lopez',     16,   NULL,         'santiago.lopez@gmail.com',     NULL),
    (10, 'Claudia',   'Torres',    35,   '2017-07-07', 'claudia.torres@gmail.com',     1);

-- Verificación rápida
SELECT * FROM users;

-- >>>>>>>>>>>>>>>>>>>> funciones/01_es_mayor_edad.sql
-- =====================================================================
-- Función 1 · es_mayor_edad
-- ---------------------------------------------------------------------
-- Recibe la edad (age) y devuelve:
--   'SÍ'          si age >= 18
--   'NO'          si age < 18
--   'Desconocido' si age es NULL
-- =====================================================================

USE university;

DROP FUNCTION IF EXISTS es_mayor_edad;

DELIMITER $$

CREATE FUNCTION es_mayor_edad(p_age INT)
RETURNS VARCHAR(15)
DETERMINISTIC   -- misma edad => siempre la misma respuesta
NO SQL          -- no consulta ninguna tabla, solo evalúa el parámetro
BEGIN
    DECLARE v_resultado VARCHAR(15);

    -- El NULL va primero: "NULL >= 18" no es ni TRUE ni FALSE (es NULL),
    -- así que caería en el ELSE y devolvería 'NO' por error.
    IF p_age IS NULL THEN
        SET v_resultado = 'Desconocido';
    ELSEIF p_age >= 18 THEN
        SET v_resultado = 'SÍ';
    ELSE
        SET v_resultado = 'NO';
    END IF;

    RETURN v_resultado;
END$$

DELIMITER ;

-- ------------------------------ Pruebas ------------------------------
-- Valores sueltos
SELECT es_mayor_edad(18) AS 'edad 18',    -- SÍ
       es_mayor_edad(17) AS 'edad 17',    -- NO
       es_mayor_edad(NULL) AS 'edad NULL'; -- Desconocido

-- Usada dentro de un SELECT sobre la tabla
SELECT user_id, name, surname, age, es_mayor_edad(age) AS mayor_de_edad
FROM users;
-- Esperado: Claudia(17) y Santiago(16) -> NO, Laura(NULL) -> Desconocido,
--           Andres(18) y el resto -> SÍ

-- >>>>>>>>>>>>>>>>>>>> funciones/02_antiguedad_usuario.sql
-- =====================================================================
-- Función 2 · antiguedad_usuario
-- ---------------------------------------------------------------------
-- Recibe la fecha de inicio (init_date) y devuelve cuántos años
-- COMPLETOS han pasado desde esa fecha hasta hoy.
-- =====================================================================

USE university;

DROP FUNCTION IF EXISTS antiguedad_usuario;

DELIMITER $$

CREATE FUNCTION antiguedad_usuario(p_init_date DATE)
RETURNS INT
NOT DETERMINISTIC   -- depende de NOW(): la misma fecha da otro resultado el año que viene
NO SQL              -- no lee tablas; con esto MySQL no lanza el error 1418
BEGIN
    -- TIMESTAMPDIFF cuenta años completos: de 2019-02-15 a 2026-02-14 son 6,
    -- y a partir del 2026-02-15 son 7.
    -- Si p_init_date es NULL, TIMESTAMPDIFF devuelve NULL.
    RETURN TIMESTAMPDIFF(YEAR, p_init_date, NOW());
END$$

DELIMITER ;

-- ------------------------------ Pruebas ------------------------------
SELECT antiguedad_usuario('2020-01-01') AS 'desde 2020-01-01';

SELECT user_id, name, init_date, antiguedad_usuario(init_date) AS anios_antiguedad
FROM users
ORDER BY anios_antiguedad DESC;
-- Esperado (calculado al 2026-11-17): Jorge 10, Claudia Torres 9, Carlos 8,
-- Marcela H. 7, Laura 6, Marcela R. 5, Valentina 4, Claudia F. 3, Andres 2,
-- Santiago NULL (no tiene init_date).

-- >>>>>>>>>>>>>>>>>>>> funciones/03_formato_correo.sql
-- =====================================================================
-- Función 3 · formato_correo
-- ---------------------------------------------------------------------
-- Recibe nombre y apellido y devuelve una propuesta de correo
-- institucional en minúsculas: nombre.apellido@universidad.edu.co
-- =====================================================================

USE university;

DROP FUNCTION IF EXISTS formato_correo;

DELIMITER $$

CREATE FUNCTION formato_correo(p_name VARCHAR(50), p_surname VARCHAR(50))
RETURNS VARCHAR(150)
DETERMINISTIC   -- mismos nombre y apellido => mismo correo
NO SQL          -- solo transforma texto, no lee tablas
BEGIN
    -- CONCAT_WS('.', a, b) une con '.' y SALTA los NULL.
    -- Con CONCAT normal, un apellido NULL haría que todo el resultado fuera NULL.
    RETURN LOWER(CONCAT(CONCAT_WS('.', p_name, p_surname), '@universidad.edu.co'));
END$$

DELIMITER ;

-- ------------------------------ Pruebas ------------------------------
SELECT formato_correo('Marcela', 'Hernandez') AS propuesta;
-- Esperado: marcela.hernandez@universidad.edu.co

SELECT user_id, name, surname, formato_correo(name, surname) AS correo_institucional
FROM users;
-- Caso borde: Valentina (surname NULL) -> valentina@universidad.edu.co

-- >>>>>>>>>>>>>>>>>>>> procedimientos/01_get_user_stats.sql
-- =====================================================================
-- Procedimiento 1 · get_user_stats
-- ---------------------------------------------------------------------
-- Recibe un user_id y devuelve, mediante dos parámetros OUT,
-- la edad y el correo electrónico del usuario.
-- =====================================================================

USE university;

DROP PROCEDURE IF EXISTS get_user_stats;

DELIMITER $$

CREATE PROCEDURE get_user_stats(
    IN  p_user_id INT,           -- Entrada: el ID que buscamos
    OUT p_age     INT,           -- Salida 1: edad
    OUT p_email   VARCHAR(100)   -- Salida 2: correo (mismo tipo que users.email)
)
BEGIN
    -- user_id es PRIMARY KEY: el SELECT devuelve como máximo 1 fila,
    -- que es lo que exige SELECT ... INTO.
    SELECT age, email
    INTO   p_age, p_email
    FROM   users
    WHERE  user_id = p_user_id;
END$$

DELIMITER ;

-- ------------------------------ Pruebas ------------------------------
-- Prueba pedida: Marcela Hernandez (ID 1)
CALL get_user_stats(1, @edad, @correo);
SELECT @edad AS edad, @correo AS correo;
-- Esperado: 25 | marcela.hernandez@gmail.com

-- Caso borde: un ID que no existe. El SELECT no encuentra filas,
-- las variables quedan en NULL y MySQL emite el warning 1329 (No data).
CALL get_user_stats(999, @edad, @correo);
SELECT @edad AS edad, @correo AS correo;
-- Esperado: NULL | NULL

-- >>>>>>>>>>>>>>>>>>>> procedimientos/02_count_by_surname.sql
-- =====================================================================
-- Procedimiento 2 · count_by_surname
-- ---------------------------------------------------------------------
-- Recibe un apellido (surname) y devuelve en un parámetro OUT cuántas
-- personas tienen ese mismo apellido.
-- =====================================================================

USE university;

DROP PROCEDURE IF EXISTS count_by_surname;

DELIMITER $$

CREATE PROCEDURE count_by_surname(
    IN  p_surname VARCHAR(50),   -- Entrada: apellido a buscar
    OUT p_total   INT            -- Salida: cantidad de personas
)
BEGIN
    -- COUNT(*) siempre devuelve exactamente 1 fila (aunque sea 0),
    -- así que este SELECT ... INTO nunca falla por "no data".
    SELECT COUNT(*)
    INTO   p_total
    FROM   users
    WHERE  surname = p_surname;
END$$

DELIMITER ;

-- ------------------------------ Pruebas ------------------------------
-- Prueba pedida: apellido 'Fernandez'
CALL count_by_surname('Fernandez', @total);
SELECT @total AS total_fernandez;
-- Esperado: 3 (Carlos, Claudia y Andres)

-- Apellido que no existe
CALL count_by_surname('Perez', @total);
SELECT @total AS total_perez;
-- Esperado: 0

-- >>>>>>>>>>>>>>>>>>>> procedimientos/03_check_email_status.sql
-- =====================================================================
-- Procedimiento 3 · check_email_status
-- ---------------------------------------------------------------------
-- Recibe un user_id y devuelve en el parámetro OUT `p_status`:
--   'Completo'  si el email NO es NULL
--   'Pendiente' si el email es NULL
-- =====================================================================

USE university;

DROP PROCEDURE IF EXISTS check_email_status;

DELIMITER $$

CREATE PROCEDURE check_email_status(
    IN  p_user_id INT,
    OUT p_status  VARCHAR(20)    -- nombre exigido por el enunciado
)
BEGIN
    -- IF(condición, si_verdadero, si_falso) se evalúa por cada fila;
    -- como filtramos por la PRIMARY KEY, hay como máximo 1 fila.
    SELECT IF(email IS NULL, 'Pendiente', 'Completo')
    INTO   p_status
    FROM   users
    WHERE  user_id = p_user_id;
END$$

DELIMITER ;

-- ------------------------------ Pruebas ------------------------------
CALL check_email_status(1, @estado);
SELECT @estado AS estado_marcela;    -- Esperado: Completo

CALL check_email_status(3, @estado);
SELECT @estado AS estado_claudia;    -- Esperado: Pendiente (email NULL)

-- Todos de una vez, para comparar con la tabla
SELECT user_id, name, email FROM users;
