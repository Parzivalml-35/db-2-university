# Bases de Datos II: Sentencias Avanzadas
*Autor: Carlos Eduardo Molina C. (redtauros.com / dominiosyhosts.com)*

---

## 1. Funciones y Procedimientos: DELIMITER

Para definir un procedimiento almacenado o función es necesario modificar temporalmente el carácter separador que se utiliza para delimitar las sentencias SQL.

El carácter separador que se utiliza por defecto en SQL es el punto y coma (`;`). En los ejemplos de esta unidad utilizaremos los caracteres `$$` para delimitar las instrucciones SQL, aunque es posible utilizar cualquier otro carácter.

```sql
-- Configurar $$ como separador
DELIMITER $$

-- Volver a configurar el punto y coma como separador
DELIMITER ;
```

### ¿Por qué es necesario `DELIMITER`?
Normalmente, el `;` le dice a MySQL: *"Terminé, ejecuta esto ahora"*. Cuando escribes un Procedimiento Almacenado o Función, este tiene varias líneas adentro y cada una termina con `;`. Si intentas crearlo normalmente, MySQL se detendría en el primer `;` que encuentre dentro del bloque, pensaría que la orden está incompleta y daría un error.

El comando `DELIMITER` le indica a MySQL que ignore el `;` y solo ejecute el bloque completo cuando encuentre el nuevo símbolo (por ejemplo `$$` o `//`).

### 1.1 Explicación con "Cajas"
Imagina que el procedimiento o función es una caja que estás armando:
* `DELIMITER $$`: Abres un contenedor especial. Le dices a MySQL: *"No cierres la caja hasta que veas `$$`"*.
* `CREATE PROCEDURE...`: Empiezas a meter las piezas (el código SQL) dentro de la caja.
* `;` (Punto y coma): Son las conexiones internas. MySQL los ignora y te deja seguir armando.
* `END$$`: MySQL ve el nuevo símbolo, cierra la caja y guarda el procedimiento completo.
* `DELIMITER ;`: Devuelves a MySQL su comportamiento normal.

**Ejemplo sencillo:**
```sql
-- 1. Cambiamos el delimitador de ';' a '$$'
DELIMITER $$

-- 2. Ejecutamos una consulta usando '$$' al final en lugar de ';'
SELECT 'Hola mundo desde MySQL' AS mensaje $$

-- 3. Creamos e insertamos usando el nuevo delimitador
CREATE TABLE IF NOT EXISTS pruebas (id INT, nombre VARCHAR(50)) $$
INSERT INTO pruebas VALUES (1, 'Ejemplo') $$

-- 4. Restauramos el delimitador habitual ';'
DELIMITER ;

-- 5. Volvemos a usar ';' normalmente
SELECT * FROM pruebas;
```

**Ejemplo de Procedimiento Almacenado:**
```sql
DELIMITER $$ -- 1. "Olvida el punto y coma por un momento"

CREATE PROCEDURE mi_ejemplo()
BEGIN
    SELECT 'Paso 1'; -- MySQL ve esto y NO lo ejecuta gracias al DELIMITER
    SELECT 'Paso 2'; -- MySQL sigue leyendo...
END$$ -- 2. "¡Ahora sí! Ejecuta todo este bloque"

DELIMITER ; -- 3. "Vuelve a la normalidad, usa el punto y coma otra vez"
```

---

## 2. Diferencias Iniciales entre Funciones y Procedimientos

Ambos términos representan el concepto de encapsular código dentro de un bloque reutilizable, pero tienen diferencias fundamentales:

* **2.1. El Valor de Retorno:**
  * **Funciones:** Siempre deben retornar un **único valor** (un número, un texto, una fecha). Se usan para realizar cálculos.
  * **Procedimientos:** No están obligados a retornar nada. Pueden devolver varias tablas de datos (varios `SELECT`) o simplemente realizar acciones.
* **2.2. Cómo se llaman (Invocación):**
  * **Funciones:** Se llaman directamente dentro de una sentencia SQL, como si fueran una columna más (`SELECT calcular_iva(precio) FROM facturas;`).
  * **Procedimientos:** Se llaman con la palabra clave `CALL` (`CALL list_users('Carlos');`).
* **2.3. Qué pueden hacer (Acciones):**
  * **Funciones:** Normalmente son de "solo lectura" para procesar datos y tienen restricciones para modificar tablas.
  * **Procedimientos:** Son "todoterreno". Pueden hacer inserciones, actualizaciones, borrar datos y ejecutar lógica compleja de negocio.

---

## 3. Procedimientos Almacenados

El propósito principal de crear procedimientos almacenados es tener código reutilizable, coherente, organizado y fácil de mantener.

### 3.1 Parámetros de entrada, salida y entrada/salida
* **Entrada (`IN`):** No pueden cambiar su valor dentro del procedimiento (paso por valor).
* **Salida (`OUT`):** Cambian su valor dentro del procedimiento para devolver un resultado al exterior (paso por referencia).
* **Entrada/Salida (`INOUT`):** Combinación de ambos; entran con un valor y pueden salir modificados.

### 3.2 Estructura Básica
```sql
CREATE PROCEDURE nombre_proc(IN entrada TIPO, OUT salida TIPO)
BEGIN
    -- Lógica
    SELECT columna INTO salida FROM tabla ...; -- ¡Opcional!
END;
```

### 3.3 Ejemplos de Procedimientos

#### Ejemplo 1: Procedimiento sin parámetros
```sql
DROP PROCEDURE IF EXISTS GetAllClients;

DELIMITER //
CREATE PROCEDURE GetAllClients()
BEGIN
    SELECT * FROM university.users;
END //
DELIMITER ;

-- Invocar el procedimiento
CALL GetAllClients();

-- Ver definición del procedimiento
SHOW CREATE PROCEDURE GetAllClients;
```

#### Ejemplo 2: Procedimiento con parámetro de entrada (`IN`)
```sql
DROP PROCEDURE IF EXISTS list_users;

DELIMITER $$
CREATE PROCEDURE list_users(IN p_nombre VARCHAR(50))
BEGIN
    SELECT * FROM users WHERE users.name = p_nombre;
END$$
DELIMITER ;

-- Invocar
CALL list_users('Claudia');
```

#### Ejemplo 3: Procedimiento con parámetro de salida (`OUT`)
El parámetro `OUT` actúa como un "sobre vacío" (`@variable`) que le entregas al procedimiento para que guarde un dato adentro.

```sql
DROP PROCEDURE IF EXISTS obtener_edad_usuario;

DELIMITER //
CREATE PROCEDURE obtener_edad_usuario(
    IN p_user_id INT,      -- El ID que queremos buscar
    OUT p_age_result INT   -- Donde guardaremos la edad encontrada
)
BEGIN
    SELECT age INTO p_age_result FROM users WHERE user_id = p_user_id;
END //
DELIMITER ;

-- 1. Llamamos al procedimiento pasando el ID 3 y una variable vacía
CALL obtener_edad_usuario(3, @edad_detectada);

-- 2. Consultamos nuestra variable para ver qué nos devolvió
SELECT @edad_detectada AS 'Edad de Claudia';
```

#### Ejemplo 4: Procedimiento con múltiples parámetros de salida (`OUT`)
```sql
DROP PROCEDURE IF EXISTS obtener_datos_contacto;

DELIMITER //
CREATE PROCEDURE obtener_datos_contacto(
    IN p_user_id INT,                        -- Entrada: ID del usuario
    OUT p_nombre_completo VARCHAR(150),      -- Salida 1: Nombre + Apellido
    OUT p_email_usuario VARCHAR(100)         -- Salida 2: Correo
)
BEGIN
    SELECT
        CONCAT(name, ' ', IFNULL(surname, '')),
        email
    INTO
        p_nombre_completo,
        p_email_usuario
    FROM users
    WHERE user_id = p_user_id;
END //
DELIMITER ;

-- Ejecución
CALL obtener_datos_contacto(1, @nombre, @correo);
SELECT @nombre AS 'Usuario', @correo AS 'Contacto';
```

---

## 4. Funciones Almacenadas

Una función almacenada se crea con `CREATE FUNCTION` y se invoca dentro de una sentencia `SELECT` o expresión. Todos sus parámetros son de entrada (no se escribe `IN`) y **siempre** devuelve un único valor.

### 4.1 Estructura Básica
```sql
CREATE FUNCTION nombre_func(parametro TIPO)
RETURNS TIPO_DATO DETERMINISTIC
BEGIN
    -- Lógica
    RETURN valor; -- ¡Obligatorio!
END;
```

### 4.2 Ejemplo Básico
```sql
DROP FUNCTION IF EXISTS contar_usuarios;

DELIMITER $$
CREATE FUNCTION contar_usuarios(nombre VARCHAR(50))
RETURNS INT UNSIGNED
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total INT UNSIGNED;
    -- Contar cuántos usuarios tienen ese nombre
    SET total = (SELECT COUNT(*) FROM university.users WHERE name = nombre);
    RETURN total;
END$$
DELIMITER ;

-- Uso
SELECT contar_usuarios('Claudia');
SELECT contar_usuarios('Marcela') AS Cantidad;
SELECT IF(contar_usuarios('Marcela') > 1, 'Hay varias', 'Hay una o ninguna');

-- Ver definición
SHOW CREATE FUNCTION contar_usuarios;
```

### 4.3 Características de la Función
Después de `RETURNS`, se deben indicar las características de la función:
* **`DETERMINISTIC`:** Siempre devuelve el mismo resultado para los mismos parámetros de entrada.
* **`NOT DETERMINISTIC`:** Puede devolver resultados distintos con los mismos parámetros (ej. si usa `NOW()` o `RAND()`). Es el valor por defecto.
* **`CONTAINS SQL`:** Contiene sentencias SQL que no leen ni modifican datos (ej. `SET @x = 1`).
* **`NO SQL`:** No contiene sentencias SQL.
* **`READS SQL DATA`:** Contiene sentencias de lectura (`SELECT`), pero no modifica datos.
* **`MODIFIES SQL DATA`:** Modifica datos (`INSERT`, `UPDATE`, `DELETE`).

> **Nota sobre Error 1418:** Si el *binary logging* está activado, MySQL exige especificar al menos `DETERMINISTIC`, `NO SQL` o `READS SQL DATA`. De lo contrario, arrojará el error `ERROR 1418 (HY000)`. Esto se puede desactivar con privilegios `SUPER` ejecutando:
> `SET GLOBAL log_bin_trust_function_creators = 1;`

### 4.4 Ejemplos Avanzados de Funciones y Procedimientos con JOIN

#### Ejemplo 1: Promedio de edad
```sql
DROP FUNCTION IF EXISTS AgeAverage;

DELIMITER $$
CREATE FUNCTION AgeAverage()
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    RETURN (SELECT AVG(age) FROM users);
END$$
DELIMITER ;

SELECT AgeAverage();
```

#### Ejemplo 2: Clasificación condicional (`IF / ELSEIF`)
```sql
DELIMITER $$
DROP FUNCTION IF EXISTS obtener_categoria_edad$$

CREATE FUNCTION obtener_categoria_edad(p_age INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE categoria VARCHAR(20);
    
    IF p_age IS NULL THEN
        SET categoria = 'No definida';
    ELSEIF p_age < 12 THEN
        SET categoria = 'Infantil';
    ELSEIF p_age BETWEEN 12 AND 17 THEN
        SET categoria = 'Adolescente';
    ELSEIF p_age BETWEEN 18 AND 29 THEN
        SET categoria = 'Joven';
    ELSE
        SET categoria = 'Adulto';
    END IF;
    
    RETURN categoria;
END$$
DELIMITER ;

SELECT name AS Nombre, age AS Edad, obtener_categoria_edad(age) AS Categoria FROM users;
```

#### Ejemplo 3: Función con `JOIN`
```sql
-- Preparación de tablas
CREATE TABLE facultades (
    facultad_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE carreras (
    carrera_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    facultad_id INT,
    FOREIGN KEY (facultad_id) REFERENCES facultades(facultad_id)
);

ALTER TABLE users
ADD COLUMN carrera_id INT,
ADD CONSTRAINT fk_users_carreras FOREIGN KEY (carrera_id) REFERENCES carreras(carrera_id);

-- Creación de la función
DELIMITER $$
DROP FUNCTION IF EXISTS obtener_facultad_estudiante$$

CREATE FUNCTION obtener_facultad_estudiante(p_user_id INT)
RETURNS VARCHAR(100)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_facultad VARCHAR(100);
    
    SELECT f.nombre INTO v_facultad
    FROM users u
    JOIN carreras c ON u.carrera_id = c.carrera_id
    JOIN facultades f ON c.facultad_id = f.facultad_id
    WHERE u.user_id = p_user_id;
    
    RETURN IFNULL(v_facultad, 'No encontrado');
END$$
DELIMITER ;

-- Consulta
SELECT user_id, name, surname, obtener_facultad_estudiante(user_id) AS facultad FROM users;
```
> **Importante:** Dentro de una función o procedimiento, la consulta con `SELECT ... INTO` debe devolver **exactamente una fila**; si devuelve más de una, MySQL lanzará un error.

#### Ejemplo 4: Procedimiento con `JOIN` y parámetros `OUT`
```sql
DELIMITER $$
DROP PROCEDURE IF EXISTS obtener_estadisticas_empresa$$

CREATE PROCEDURE obtener_estadisticas_empresa(
    IN p_company_id INT,
    OUT p_total_proyectos INT,
    OUT p_nombre_empresa VARCHAR(100)
)
BEGIN
    SELECT
        COUNT(p.proyecto_id),
        e.nombre
    INTO
        p_total_proyectos,
        p_nombre_empresa
    FROM empresas e
    LEFT JOIN users u ON e.company_id = u.company_id
    LEFT JOIN proyectos p ON u.user_id = p.user_id
    WHERE e.company_id = p_company_id
    GROUP BY e.company_id, e.nombre;
END$$
DELIMITER ;

-- Prueba
CALL obtener_estadisticas_empresa(1, @total, @empresa);
SELECT @empresa AS Nombre_Empresa, @total AS Total_Proyectos_Activos;
```

### 4.5 Tabla Comparativa: Funciones vs. Procedimientos

| Característica | Funciones (`CREATE FUNCTION`) | Procedimientos (`CREATE PROCEDURE`) |
| :--- | :--- | :--- |
| **Invocación** | Dentro de `SELECT`, `WHERE` o `SET`. | Con la palabra clave `CALL`. |
| **Parámetros** | Solo acepta parámetros de entrada (`IN`). | Acepta `IN`, `OUT` e `INOUT`. |
| **Retorno** | **Obligatorio.** Siempre devuelve un único valor con `RETURN`. | No usa `RETURN`. Devuelve datos mediante `SELECT` o parámetros `OUT`. |
| **Definición de retorno** | Debe especificar el tipo en `RETURNS`. | Se especifica el tipo en cada parámetro `OUT`. |
| **Propósito típico** | Encapsular fórmulas o reglas de negocio genéricas (calculador). | Procesar, manipular y modificar datos en la BD (operador). |

---

## 5. Índices (INDEX) y EXPLAIN

Un **índice** es una estructura de datos especial que se crea en una o más columnas de una tabla para mejorar la velocidad de las operaciones de búsqueda y acceso a los datos (similar al índice de un libro).

### 5.1 ¿Para qué sirve un índice?
* Acelerar consultas (`SELECT`, `WHERE`, `JOIN`, `ORDER BY`).
* Mejorar el rendimiento de claves foráneas y restricciones.
* Evitar duplicados cuando se usa un índice `UNIQUE`.
* Soportar búsquedas por rangos o patrones (`LIKE 'texto%'`).

### 5.2 Tipos comunes de índices en MySQL

| Tipo | Descripción |
| :--- | :--- |
| `INDEX` (`KEY`) | Índice normal; mejora la velocidad de búsquedas. Puede contener valores duplicados. |
| `UNIQUE` | Asegura que todos los valores en la columna sean diferentes. |
| `PRIMARY KEY` | Es un `UNIQUE INDEX` que identifica cada fila de forma única y no puede ser nulo. |
| `FULLTEXT` | Usado para búsquedas de texto completo en columnas `CHAR`, `VARCHAR` o `TEXT`. |
| `INDEX compuesto` | Creado sobre dos o más columnas. Ej: `CREATE INDEX idx_name ON users(name, surname);`. |

### 5.3 Cuándo crear y cuándo no abusar
* **Crear en:** Columnas usadas frecuentemente en `WHERE`, `JOIN`, `ORDER BY`, `GROUP BY` o que requieran ser `UNIQUE`.
* **No abusar:** Cada índice ocupa espacio en disco/memoria y ralentiza las operaciones `INSERT`, `UPDATE` y `DELETE` (porque el índice también debe actualizarse).

### 5.4 Sintaxis Básica
```sql
-- Crear un índice simple
CREATE INDEX idx_email ON users(email);

-- Crear un índice único
CREATE UNIQUE INDEX idx_user_id ON users(user_id);

-- Crear un índice compuesto único
CREATE UNIQUE INDEX idx_name_surname ON users(name, surname);

-- Ver los índices de una tabla
SHOW INDEX FROM users;
-- o ver estructura con claves (PRI, UNI, MUL)
DESCRIBE users;

-- Eliminar un índice
DROP INDEX idx_email ON users;
```

### 5.5 Análisis de Consultas con `EXPLAIN`
La sentencia `EXPLAIN` muestra el plan de ejecución que utiliza MySQL para procesar una consulta, permitiendo identificar cuellos de botella.

**Ejemplo sin índice:**
```sql
EXPLAIN SELECT company_id FROM users WHERE name = 'Claudia';
```
* `type: ALL` (Escaneo completo de tabla — **Ineficiente**).
* `possible_keys: NULL` / `key: NULL` (No se encontraron ni usaron índices).
* `Extra: Using where` (Filtró después de leer toda la tabla).

**Columnas clave de `EXPLAIN`:**
* **`select_type`:** Tipo de consulta (`SIMPLE`, `PRIMARY`, `DERIVED`, `SUBQUERY`, `UNION`, etc.).
* **`type` (de mejor a peor rendimiento):**
  1. `system` / `const`: Una sola fila coincidente (ej. búsqueda por `PRIMARY KEY` o `UNIQUE`).
  2. `eq_ref`: Unión usando índice agrupado.
  3. `ref`: Columna indexada accedida con operador de igualdad (`=`).
  4. `fulltext`: Uso de índice `FULLTEXT`.
  5. `index`: Escaneo completo del árbol del índice.
  6. `ALL`: Escaneo completo de toda la tabla (indica falta de índices).
* **`possible_keys` / `key`:** Índices candidatos vs. el índice realmente utilizado.
* **`rows`:** Número estimado de filas examinadas.
* **`filtered`:** Porcentaje de filas filtradas por la condición.
* **`Extra`:** Información adicional. Valores como `Using temporary` (creación de tabla temporal) o `Using filesort` (ordenamiento externo) suelen indicar consultas que requieren optimización.

---

## 6. Triggers (Disparadores)

Un **trigger** es un bloque de código SQL que se ejecuta automáticamente cuando ocurre un evento (`INSERT`, `UPDATE`, `DELETE`) en una tabla específica.

### 6.1 Momentos y Eventos
* **Momentos:** `BEFORE` (antes del evento) o `AFTER` (después del evento).
* **Eventos:** `INSERT`, `UPDATE`, `DELETE`.

### 6.2 Usos Comunes y Reglas
* **Usos:** Auditoría (historial de cambios), validación de datos, sincronización entre tablas y cálculos automáticos.
* **Reglas importantes:**
  * Pertenece a una sola tabla.
  * Se ejecuta por cada fila afectada (`FOR EACH ROW`).
  * No puede modificar la misma tabla que lo disparó (evita bucles infinitos).
* **Palabras clave `OLD` y `NEW`:**
  * `OLD.columna`: Valor antes del cambio (disponible en `UPDATE` y `DELETE`).
  * `NEW.columna`: Valor después del cambio (disponible en `INSERT` y `UPDATE`).

### 6.3 Ejemplo: Auditoría de Cambio de Correo
```sql
USE university;

-- 1. Crear tabla de historial
CREATE TABLE email_history (
    email_history_id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    email VARCHAR(100) NULL,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (email_history_id)
);

-- 2. Crear el trigger
DELIMITER //
DROP TRIGGER IF EXISTS tg_email;

CREATE TRIGGER tg_email
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    -- Comparamos el email antiguo con el nuevo
    IF OLD.email <> NEW.email THEN
        INSERT INTO email_history (user_id, email)
        VALUES (OLD.user_id, OLD.email);
    END IF;
END//
DELIMITER ;

-- 3. Probar el trigger
UPDATE users SET email = 'superdev@miemail.com' WHERE user_id = 1;
SELECT * FROM email_history;

-- Comandos de gestión de triggers
SHOW TRIGGERS;
SHOW TRIGGERS FROM university WHERE `Table` = 'users';
SHOW CREATE TRIGGER tg_email;
DROP TRIGGER tg_email;
```

---

## 7. Vistas (Views)

Una **vista** es una consulta guardada que se comporta como una tabla virtual. No almacena datos físicamente, sino la instrucción SQL subyacente.

### 7.1 Creación y Ejemplos
```sql
USE university;

-- Vista básica
CREATE VIEW usuarios_con_email AS
SELECT user_id, name, surname, email
FROM users
WHERE email IS NOT NULL;

-- Consultar la vista
SELECT * FROM usuarios_con_email;

-- Vista con cálculos y lógica condicional
CREATE VIEW usuarios_detallados AS
SELECT
    user_id,
    CONCAT(name, ' ', IFNULL(surname, '')) AS nombre_completo,
    age,
    init_date,
    email,
    CASE
        WHEN age < 18 THEN 'Menor de edad'
        WHEN age BETWEEN 18 AND 60 THEN 'Adulto'
        ELSE 'Adulto mayor'
    END AS categoria_edad,
    YEAR(CURDATE()) - YEAR(init_date) AS años_registrado
FROM users
WHERE init_date IS NOT NULL;

-- Vista para reportes agrupados
CREATE VIEW resumen_nombres AS
SELECT
    name,
    COUNT(*) AS total_usuarios,
    GROUP_CONCAT(DISTINCT surname ORDER BY surname) AS apellidos_asociados
FROM users
GROUP BY name;
```

### 7.2 Modificar, Eliminar y Listar Vistas
```sql
-- Modificar / Reemplazar una vista
CREATE OR REPLACE VIEW usuarios_con_email AS
SELECT user_id, name, surname, email, init_date
FROM users
WHERE email IS NOT NULL AND email LIKE '%@%';

-- Eliminar una vista
DROP VIEW IF EXISTS usuarios_con_email;

-- Ver vistas existentes
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SHOW CREATE VIEW usuarios_detallados;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'university';
```

### 7.3 ¿Cuándo usar Vistas?
* **Sí:** Reutilizar consultas complejas frecuentes, ocultar columnas sensibles a ciertos usuarios y simplificar reportes.
* **Revisar / No:** No mejoran el rendimiento por sí solas (no tienen índices propios). Para modificaciones complejas con restricciones, es preferible usar tablas temporales.

---

## 8. Complementos y Copias de Seguridad (`mysqldump`)

### 8.1 Acceder a archivos WSL desde Windows
Desde el Explorador de archivos de Windows, ingresa en la barra de direcciones:
```text
\\wsl$\
```

### 8.2 Copias de Seguridad con `mysqldump` (Terminal)
```bash
# Exportar una base de datos completa
mysqldump -u usuario -p nombre_base_datos > archivo_backup.sql
sudo mysqldump -u root -p university > university_backup.sql

# Exportar solo la estructura (sin datos)
mysqldump -u root -p --no-data universidad > estructura.sql

# Exportar una tabla específica
mysqldump -u root -p universidad estudiantes > tabla_estudiantes.sql

# Exportar varias bases de datos
mysqldump -u root -p --databases universidad tienda > multiples_bases.sql

# Exportar TODAS las bases de datos
mysqldump -u root -p --all-databases > todas_las_bases.sql
```

**Opciones útiles adicionales:**
* `--routines`: Incluye procedimientos almacenados y funciones.
* `--triggers`: Incluye triggers.
* `--events`: Incluye eventos programados.
* `--single-transaction`: Backup consistente sin bloquear tablas (InnoDB).
* `--lock-all-tables`: Bloquea tablas durante el backup (MyISAM).
* `--add-drop-table`: Agrega `DROP TABLE IF EXISTS` antes de cada `CREATE`.
* `--if-not-exists`: Usa `CREATE TABLE IF NOT EXISTS`.

**Ejemplo completo:**
```bash
mysqldump -u root -p --single-transaction --routines --triggers --events universidad > universidad_completo.sql
```

### 8.3 Limpiar Terminal de MySQL
Dentro del cliente de línea de comandos de MySQL:
```sql
\! clear
```

---

## 9. Configuración para Conexión Remota con MySQL Workbench

Para permitir conexiones externas desde MySQL Workbench hacia un servidor Ubuntu/Linux:

### Paso 1: Crear usuario remoto en MySQL
```sql
CREATE USER 'wp_user' IDENTIFIED BY 'Unicatolica2025+';
GRANT ALL PRIVILEGES ON *.* TO 'wp_user'@'%';
FLUSH PRIVILEGES;

-- Verificar
SELECT user, host FROM mysql.user;
EXIT;
```

### Paso 2: Permitir conexiones externas en la configuración de MySQL
Edita el archivo `mysqld.cnf` en la terminal de Linux:
```bash
sudo vi /etc/mysql/mysql.conf.d/mysqld.cnf
```
Comenta la línea de dirección local y habilita la escucha en todas las interfaces (`0.0.0.0`):
```ini
#bind-address = 127.0.0.1
bind-address = 0.0.0.0
```

### Paso 3: Reiniciar el servicio y obtener la IP
```bash
# Reiniciar MySQL
sudo systemctl restart mysql

# Obtener la IP del servidor Ubuntu
hostname -I
```
Con la IP obtenida, el usuario (`wp_user`) y la contraseña, configura la nueva conexión en **MySQL Workbench**.

---

## Fuentes y Temas Pendientes
* **Fuente:** [Unidad 12 - Teoría (José Juan Sánchez)](https://josejuansanchez.org/bd/unidad-12-teoria/index.html)
* **Pendiente por estudiar:**
  * Subqueries (Subconsultas)
  * Common Table Expressions (CTEs)
  * Scheduled Events (Eventos programados)
  * Transaction Statements (Transacciones)
  * Prepared Statements (Sentencias preparadas)