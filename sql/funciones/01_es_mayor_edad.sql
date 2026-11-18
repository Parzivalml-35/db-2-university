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
