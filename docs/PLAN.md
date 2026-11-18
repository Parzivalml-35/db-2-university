# Plan: Parcial Final · Caso 2, Clínica Veterinaria "Huellas"

## Contexto
Primero se resolvió por error el `taller.md` (funciones y procedimientos sobre `university.users`). El enunciado correcto es `apuntes/parcial_final.md`: un script SQL con 9 requerimientos sobre el caso asignado, el **Caso 2 (Veterinaria)**. La solución del taller se borró y queda en el historial de git (commit `8fe42db` y anteriores).

## Decisiones
- **Un solo script** (`sql/parcial_veterinaria.sql`), como pide el enunciado, con secciones numeradas del 1 al 9 y pruebas con el resultado esperado en comentarios.
- **Modelo en `docs/MODELO.md`** con Mermaid, porque GitHub lo dibuja.
- **5 tablas** (`propietarios`, `especies`, `mascotas`, `veterinarios`, `consultas_medicas`) + `historial_diagnosticos`. `consultas_medicas` es la tabla N:M.
- **`fecha_nacimiento` en vez de edad**, y las fechas de prueba son relativas a `CURDATE()` para que las etapas de vida no cambien con el tiempo.
- **`historial_diagnosticos` sin FK**, para que la auditoría sobreviva si se borra la consulta.
- **Trigger:** `AFTER UPDATE`, compara con `<=>` (seguro con NULL) y registra con `USER()`.
- **Función** `fn_etapa_vida`: `DETERMINISTIC NO SQL`.
- **Procedimiento:** "mascotas tratadas" es ambiguo, así que devuelve la cantidad y la lista de nombres. Se agregó el nombre del veterinario para distinguir "no existe" de "sin consultas".
- **`SET NAMES utf8mb4`** al inicio del script, porque sin él el cliente `mysql` de Docker guardaba las tildes doblemente codificadas.
- **Roles exactamente como el enunciado:** admin con DML completo, empleado con SELECT e INSERT. No se da `EXECUTE`. La vista funciona para ambos porque se ejecuta con los privilegios de su creador (`SQL SECURITY DEFINER`).

## Estado (actualizado 2026-11-18)

### Hecho
- Script verificado en un contenedor temporal con **MySQL 8.4.11** (binlog activo): todas las salidas coinciden con lo esperado y dos ejecuciones seguidas dan el mismo resultado.
- Roles verificados: `recepcion_huellas` puede hacer INSERT y SELECT (incluida la vista), y recibe ERROR 1142 en UPDATE y DELETE. `admin_huellas` puede todo, y el trigger lo registra como `admin_huellas@localhost`.

### Pendiente
- [ ] Ejecutar en el PC Windows de la universidad con Workbench.
- [ ] Commits y push.
- [ ] Decidir si los `apuntes/` deben quedar en un repo público (tienen contraseñas de ejemplo de clase).

### Hallazgos fuera de alcance (en los apuntes, sin corregir)
- `GRANT USAGE … IDENTIFIED BY` no funciona en MySQL 8 (usar `ALTER USER`).
- `GRANT FILE ON wordpress_db.*` falla: `FILE` solo es global (`*.*`).
- Trigger `tg_email`: `OLD.email <> NEW.email` no detecta cambios desde o hacia NULL; usar `NOT (OLD.email <=> NEW.email)`.
