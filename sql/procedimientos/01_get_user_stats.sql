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
