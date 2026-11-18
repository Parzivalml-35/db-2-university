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
