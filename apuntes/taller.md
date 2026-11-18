# Ejercicios Procedimiento y Funciones

Para todos los ejercicios:
- Para estos ejercicios, seguiremos usando tu base de datos `university` y la tabla `users`.
- Ejercicios de Funciones (Cálculos y Transformaciones)
- Las funciones deben devolver un valor único y usarse dentro de un `SELECT`.

## Ejercicios de Funciones (Cálculos y Transformaciones)

Las funciones deben devolver un valor único y usarse dentro de un SELECT.

### 1. Función `es_mayor_edad`
- **Objetivo:** Crear una función que reciba la edad (`age`) y devuelva un texto: `SÍ` si tiene 18 años o más, y `NO` si es menor.
- Si la edad es `NULL`, que devuelva `Desconocido`.

### 2. Función `antiguedad_usuario`
- **Objetivo:** Crear una función que reciba la fecha de inicio (`init_date`) y devuelva cuántos años han pasado desde esa fecha hasta hoy (puedes usar la función de MySQL `TIMESTAMPDIFF(YEAR, fecha_inicial, NOW())`).

### 3. Función `formato_correo`
- **Objetivo:** Crear una función que tome el nombre y el apellido, y devuelva una propuesta de correo institucional: `nombre.apellido@universidad.edu.co` (todo en minúsculas).

## Ejercicios de Procedimientos (Lógica y Salidas)

Los procedimientos deben usar `CALL` y, en estos casos, parámetros `OUT`.

### 1. Procedimiento `get_user_stats`
- **Objetivo:** Crear un procedimiento que reciba un `user_id` y devuelva mediante dos parámetros `OUT`: la edad del usuario y su correo electrónico.
- **Prueba:** Úsalo con el ID de Marcela Hernandez (ID 1).

### 2. Procedimiento `count_by_surname`
- **Objetivo:** Crear un procedimiento que reciba un apellido (`surname`) como entrada y devuelva en un parámetro `OUT` el total de personas que tienen ese mismo apellido en la tabla.
- **Prueba:** Ejecútalo buscando el apellido 'Fernandez'.

### 3. Procedimiento `check_email_status`
- **Objetivo:** Crear un procedimiento que reciba el `user_id`. Debe devolver en un parámetro `OUT` llamado `p_status` un mensaje que diga `Completo` si el email no es nulo, o `Pendiente` si el campo email está vacío (`NULL`).

## Tips para resolverlos

- No olvides iniciar con `DELIMITER $$` y terminar con `DELIMITER ;`.
- Para las funciones, recuerda usar `DETERMINISTIC` y `REES SQL DATA`.
- Para los procedimientos, usa la estructura `SELECT columna INTO variable_salida`.