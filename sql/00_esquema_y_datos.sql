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
