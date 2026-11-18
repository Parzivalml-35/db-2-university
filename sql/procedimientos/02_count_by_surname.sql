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
