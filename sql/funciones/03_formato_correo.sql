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
