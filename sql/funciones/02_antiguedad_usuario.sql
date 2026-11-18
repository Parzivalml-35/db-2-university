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
