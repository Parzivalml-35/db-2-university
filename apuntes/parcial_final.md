# Evaluación Práctica Avanzada: Bases de Datos II

## Requerimientos Generales (Las "Preguntas" para todos los casos)

Para el caso asignado, se debe entregar un script SQL que cumpla secuencialmente con los siguientes puntos:

1. **Modelo lógico y normalización:** Entregar el modelo lógico y las bases de datos normalizadas.
2. **Estructura y Modelado (DDL):** Crea la base de datos y diseña al menos 4 tablas fuertemente relacionadas (relaciones 1:N o N:M con claves foráneas).
3. **Población de Datos (DML):** Inserta un mínimo de 5 registros significativos en cada tabla utilizando la sentencia `INSERT INTO`.
4. **Seguridad, Usuarios y Roles:**
   * Crea 2 roles (ej. `rol_admin` y `rol_empleado`) y asígnales privilegios específicos usando el comando `GRANT` (ej. operaciones DML completas para admin, y solo `SELECT` e `INSERT` para empleado).
   * Crea 2 usuarios (con contraseñas seguras) y asígnales los roles correspondientes.
   * Asegura que los roles se activen automáticamente configurándolos con `SET DEFAULT ROLE ALL`.
5. **Programación de Triggers (Auditoría/Control):** Crea un disparador (`TRIGGER`) que se active automáticamente ante un evento `UPDATE` o `DELETE`. El trigger debe utilizar las variables `OLD` o `NEW` (por ejemplo, para guardar los datos anteriores en una tabla de historial antes de ser modificados o borrados).
6. **Funciones con Lógica Condicional:** Crea una función (`FUNCTION`) que reciba un parámetro de entrada y devuelva un valor calculado. Debe incluir obligatoriamente la sentencia `CASE` para devolver una categoría (ej. rangos de precio, edad, o estados). Asegúrate de usar los delimitadores `$$`, la cláusula `RETURNS` y declarar si es `DETERMINISTIC` o `READS SQL DATA`.
7. **Procedimientos Almacenados y JOINS:** Crea un procedimiento almacenado (`PROCEDURE`) que integre un `INNER JOIN` o `LEFT JOIN` entre al menos 2 de tus tablas. El procedimiento debe recibir al menos un parámetro de entrada (`IN`) para filtrar la consulta, y devolver métricas mediante parámetros de salida (`OUT`).
8. **Consultas Complejas (Reportes):** Escribe una consulta `SELECT` que incluya funciones de agregación (como `COUNT` o `SUM`), la cláusula `GROUP BY`, y ordene los resultados con `ORDER BY`.
9. **Vistas:** Generar por lo menos una vista.

---

## Los 5 Casos de Estudio (Escenarios)

A continuación, los contextos que los estudiantes deberán usar para aplicar los requerimientos anteriores:

### Caso 1: Sistema de Lavadero de Carros
1. **Contexto:** Un negocio que gestiona el lavado, polichado y limpieza interna de vehículos.
2. **Tablas sugeridas:** `Clientes`, `Vehiculos`, `Servicios_Ofrecidos`, `Registro_Lavados`.
3. **Lógica esperada:**
   * **Función (`CASE`):** Categorizar el tipo de cliente según la cantidad de lavados (Nuevo, Frecuente, VIP).
   * **Procedimiento (`JOIN`):** Entregar el ID del vehículo y devolver el nombre del cliente, el servicio realizado y el total gastado.
   * **Trigger:** Auditar en una tabla `historial_cancelaciones` cuando un registro de lavado sea borrado.

### Caso 2: Clínica Veterinaria "Huellas"
1. **Contexto:** Un centro médico para el control de pacientes animales y sus dueños.
2. **Tablas sugeridas:** `Propietarios`, `Mascotas`, `Veterinarios`, `Consultas_Medicas`.
3. **Lógica esperada:**
   * **Función (`CASE`):** Clasificar la etapa de vida de la mascota basándose en su edad (Cachorro, Adulto, Senior).
   * **Procedimiento (`JOIN`):** Recibir el ID del veterinario y devolver mediante variables `OUT` la cantidad de consultas atendidas y las mascotas tratadas.
   * **Trigger:** Respaldar el diagnóstico anterior de una mascota cada vez que el veterinario actualice (`UPDATE`) el campo de la consulta médica.

### Caso 3: Gestión de Torneo Deportivo
1. **Contexto:** Un sistema para administrar los equipos, jugadores y resultados de un campeonato local.
2. **Tablas sugeridas:** `Equipos`, `Jugadores`, `Estadios`, `Partidos`.
3. **Lógica esperada:**
   * **Función (`CASE`):** Determinar el resultado de un equipo (Victoria, Empate, Derrota) comparando los goles a favor y en contra.
   * **Procedimiento (`JOIN`):** Ingresar el ID de un partido y retornar el estadio, el nombre de los equipos enfrentados y la cantidad total de jugadores convocados.
   * **Trigger:** Cuando se elimine (`DELETE`) a un jugador de la tabla, su nombre y equipo original deben ser registrados en una tabla de `jugadores_retirados`.

### Caso 4: Biblioteca Universitaria
1. **Contexto:** Control de préstamos de libros, fechas de entrega y devoluciones de estudiantes.
2. **Tablas sugeridas:** `Estudiantes`, `Libros`, `Autores`, `Prestamos`.
3. **Lógica esperada:**
   * **Función (`CASE`):** Calcular el estado de la multa (Sin Multa, Multa Leve, Multa Grave) dependiendo de la diferencia de días entre la fecha límite y la fecha de entrega.
   * **Procedimiento (`JOIN`):** Consultar los datos completos de un préstamo, uniendo los datos del libro, el autor y el estudiante que lo solicitó.
   * **Trigger:** Rastrear los cambios de estado en un préstamo (ej. cuando pasa de "Activo" a "Devuelto"), guardando el valor viejo (`OLD.estado`) y el nuevo (`NEW.estado`).

### Caso 5: Tienda de Componentes de Computador (Hardware)
1. **Contexto:** Un sistema de inventario y facturación para venta de tecnología.
2. **Tablas sugeridas:** `Categorias`, `Productos`, `Clientes`, `Ventas_Facturacion`.
3. **Lógica esperada:**
   * **Función (`CASE`):** Validar el nivel de inventario del producto (Agotado, Stock Bajo, Stock Óptimo) según las cantidades disponibles.
   * **Procedimiento (`JOIN`):** Recibir el ID de un cliente e identificar con un reporte todos los productos que ha comprado y el monto total.
   * **Trigger:** Evitar alteraciones malintencionadas auditando cualquier `UPDATE` en el precio de un producto, registrando el precio anterior, el nuevo precio y la fecha del cambio.