# Plan: Parcial Final · Caso 2, Clínica Veterinaria "Huellas"

## Contexto
Primero se resolvió por error el `taller.md` (funciones y procedimientos sobre `university.users`). El enunciado correcto es `apuntes/parcial_final.md`: un script SQL con 9 requerimientos sobre el caso asignado, el **Caso 2 (Veterinaria)**. La solución del taller se borró y queda en el historial de git (commit `8fe42db` y anteriores).

## Decisiones
- **Un solo script** (`sql/parcial_veterinaria.sql`), como pide el enunciado, con secciones numeradas del 1 al 9 y pruebas con el resultado esperado en comentarios.
- **Modelo en `docs/MODELO.md`** con Mermaid, porque GitHub lo dibuja.
- **9 tablas + `historial_diagnosticos`** (2026-11-18). La estructura se basó en el script de una compañera (razas, especialidades, tratamientos y detalle de consultas), con estos ajustes:
  - Se añadieron las columnas que exige el Caso 2: `diagnostico`, `motivo` y `fecha_nacimiento`.
  - Se quitó `total_consulta`, porque es derivado.
  - `mascotas` guarda solo `raza_id`, sin `especie_id` (3FN).
  - PK `INT AUTO_INCREMENT`, `nombre`/`apellido` separados, `UNIQUE` y `CHECK`.
- **Dos N:M:** `consultas_medicas` (mascotas↔veterinarios) y `detalle_consultas` (consultas↔tratamientos, PK compuesta).
- **`precio_aplicado` en el detalle:** conserva lo cobrado aunque cambie el precio de lista. La consulta 1 se cobró a 45.000 y hoy vale 50.000, para demostrarlo.
- La versión anterior de 5 tablas está en el commit `85046e6`.
- **`fecha_nacimiento` en vez de edad**, y las fechas de prueba son relativas a `CURDATE()` para que las etapas de vida no cambien con el tiempo.
- **`historial_diagnosticos` sin FK**, para que la auditoría sobreviva si se borra la consulta.
- **Trigger:** `AFTER UPDATE`, compara con `<=>` (seguro con NULL) y registra con `USER()`.
- **Función** `fn_etapa_vida`: `DETERMINISTIC NO SQL`.
- **Procedimiento:** "mascotas tratadas" es ambiguo, así que devuelve la cantidad y la lista de nombres. Se agregó el nombre del veterinario para distinguir "no existe" de "sin consultas".
- **`SET NAMES utf8mb4`** al inicio del script, porque sin él el cliente `mysql` de Docker guardaba las tildes doblemente codificadas.
- **Roles exactamente como el enunciado:** admin con DML completo, empleado con SELECT e INSERT. No se da `EXECUTE`. La vista funciona para ambos porque se ejecuta con los privilegios de su creador (`SQL SECURITY DEFINER`).

## Estado (actualizado 2026-11-18)

### Hecho
- Script verificado en un contenedor temporal con **MySQL 8.4.11** (binlog activo): todas las salidas coinciden con lo esperado y dos ejecuciones seguidas dan el mismo resultado. Se volvió a verificar con la estructura de 9 tablas.
- `sql/banco_consultas.sql` verificado: se ejecuta completo dos veces sin errores, deja las 10 tablas con el mismo checksum, y cada `DEMO ERROR` da el código que anuncia.
- Roles verificados: `recepcion_huellas` puede hacer INSERT y SELECT (incluida la vista), y recibe ERROR 1142 en UPDATE y DELETE. `admin_huellas` puede todo, y el trigger lo registra como `admin_huellas@localhost`.

### Pendiente
- [ ] Ejecutar en el PC Windows de la universidad con Workbench.
- [x] Commits y push.
- [ ] Decidir si los `apuntes/` deben quedar en un repo público (tienen contraseñas de ejemplo de clase).

### Hallazgos fuera de alcance (en los apuntes, sin corregir)
- `GRANT USAGE … IDENTIFIED BY` no funciona en MySQL 8 (usar `ALTER USER`).
- `GRANT FILE ON wordpress_db.*` falla: `FILE` solo es global (`*.*`).
- Trigger `tg_email`: `OLD.email <> NEW.email` no detecta cambios desde o hacia NULL; usar `NOT (OLD.email <=> NEW.email)`.
