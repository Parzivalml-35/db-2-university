#!/usr/bin/env bash
# Regenera sql/todo_en_uno.sql uniendo el esquema y los 6 ejercicios.
# Ejecútalo cada vez que modifiques uno de los scripts individuales.
set -euo pipefail
cd "$(dirname "$0")/sql"

salida="todo_en_uno.sql"
archivos=(
    00_esquema_y_datos.sql
    funciones/01_es_mayor_edad.sql
    funciones/02_antiguedad_usuario.sql
    funciones/03_formato_correo.sql
    procedimientos/01_get_user_stats.sql
    procedimientos/02_count_by_surname.sql
    procedimientos/03_check_email_status.sql
)

{
    echo "-- ====================================================================="
    echo "-- TODO EN UNO · generado por generar_todo_en_uno.sh — NO editar a mano."
    echo "-- Crea la BD university, la tabla users, las 3 funciones, los"
    echo "-- 3 procedimientos y ejecuta todas las pruebas."
    echo "-- ====================================================================="
    for f in "${archivos[@]}"; do
        echo
        echo "-- >>>>>>>>>>>>>>>>>>>> $f"
        cat "$f"
    done
} > "$salida"

echo "Generado sql/$salida"
