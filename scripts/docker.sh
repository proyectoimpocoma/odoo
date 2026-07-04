#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_NAME="${ODOO_DB:-mi_empresa}"
ODOO_CONFIG="${ODOO_CONFIG:-/etc/odoo/odoo.conf}"
DEFAULT_MODULES="${ODOO_MODULES:-theme_impocoma,risk_module}"

cd "$ROOT_DIR"

usage() {
  cat <<EOF
Uso:
  ./scripts/docker.sh <comando> [argumentos]

Comandos:
  help                         Muestra esta ayuda
  config                       Valida docker-compose.yml
  build                        Construye la imagen de Odoo
  rebuild                      Construye la imagen de Odoo sin cache
  init                         Primera ejecucion: levanta Docker e instala ${DEFAULT_MODULES}
  up                           Levanta Postgres y Odoo en segundo plano
  up-logs                      Levanta Postgres y Odoo en primer plano
  down                         Detiene y elimina contenedores sin borrar datos
  stop                         Detiene los servicios
  restart                      Reinicia Odoo
  logs [servicio]              Sigue logs de odoo o db
  ps                           Muestra estado de servicios
  shell                        Entra al contenedor de Odoo
  db                           Entra a psql
  db-query <sql>               Ejecuta una consulta SQL
  install <modulos>            Instala modulos, ejemplo: risk_module
  update <modulos>             Actualiza modulos, ejemplo: risk_module
  update-all                   Actualiza ${DEFAULT_MODULES}
  apply-theme                  Fuerza theme_impocoma como tema del website
  module-status                Muestra estado de modulos principales
  backup                       Exporta backups/mi_empresa_YYYYmmdd_HHMMSS.sql
  restore <archivo.sql>        Restaura un SQL en ${DB_NAME}
  reset                        Borra contenedores, volumenes, base y filestore

Variables opcionales:
  ODOO_DB=mi_empresa
  ODOO_MODULES=theme_impocoma,risk_module
EOF
}

require_arg() {
  local value="${1:-}"
  local message="$2"

  if [[ -z "$value" ]]; then
    echo "Error: $message" >&2
    echo >&2
    usage >&2
    exit 2
  fi
}

compose() {
  docker compose "$@"
}

run_odoo_module_command() {
  local mode="$1"
  local modules="$2"
  local exit_code=0

  echo "Ejecutando -${mode} ${modules} en la base ${DB_NAME}..."

  compose up -d db
  wait_for_database

  echo "Deteniendo Odoo para evitar escrituras concurrentes durante la actualizacion..."
  compose stop odoo || true

  compose run --rm --no-deps odoo odoo -c "$ODOO_CONFIG" \
    -d "$DB_NAME" \
    "-${mode}" "$modules" \
    --stop-after-init \
    --no-http || exit_code=$?

  echo "Levantando Odoo..."
  compose up -d odoo

  if ! wait_for_odoo; then
    if [[ "$exit_code" -eq 0 ]]; then
      exit_code=1
    fi
  fi

  return "$exit_code"
}

wait_for_database() {
  echo "Esperando a que PostgreSQL este listo..."
  for _ in $(seq 1 60); do
    if compose exec -T db pg_isready -U odoo -d "$DB_NAME" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "Error: PostgreSQL no estuvo listo a tiempo." >&2
  exit 1
}

wait_for_odoo() {
  local successful_checks=0

  echo "Esperando a que Odoo responda..."
  for _ in $(seq 1 60); do
    if curl --fail --silent --output /dev/null --max-time 2 "http://127.0.0.1:8069/web/login"; then
      successful_checks=$((successful_checks + 1))
      if [[ "$successful_checks" -ge 5 ]]; then
        return 0
      fi
    else
      successful_checks=0
    fi
    sleep 2
  done

  echo "Error: Odoo no respondio en http://127.0.0.1:8069/web/login." >&2
  return 1
}

init_environment() {
  echo "Levantando contenedores..."
  compose up --build -d
  wait_for_database
  run_odoo_module_command "i" "$DEFAULT_MODULES"
  apply_theme
}

apply_theme() {
  echo "Aplicando theme_impocoma al website..."
  compose exec -T odoo odoo shell -c "$ODOO_CONFIG" -d "$DB_NAME" <<'PY'
theme = env["ir.module.module"].sudo().search([("name", "=", "theme_impocoma")], limit=1)
if not theme:
    raise SystemExit("theme_impocoma no esta disponible")

websites = env["website"].sudo().search([])
if not websites:
    websites = env["website"].sudo().create({
        "name": "Impocoma",
        "theme_id": theme.id,
    })

theme_loader = theme.with_context(apply_new_theme=True)._theme_get_stream_themes()
for website in websites:
    website.write({"theme_id": theme.id})
    theme_loader._theme_load(website)

env.cr.commit()
print("theme_impocoma aplicado a websites:", ", ".join(str(w.id) for w in websites))
PY

  echo "Reiniciando Odoo..."
  compose restart odoo
}

confirm_reset() {
  echo "Esto borrara contenedores, volumenes, base de datos y filestore."
  printf "Escribe '%s' para confirmar: " "$DB_NAME"
  read -r confirmation

  if [[ "$confirmation" != "$DB_NAME" ]]; then
    echo "Cancelado."
    exit 1
  fi
}

command="${1:-help}"
shift || true

case "$command" in
  help|-h|--help)
    usage
    ;;

  config)
    compose config
    ;;

  build)
    compose build odoo
    ;;

  rebuild)
    compose build --no-cache odoo
    ;;

  init)
    init_environment
    ;;

  up)
    compose up --build -d
    ;;

  up-logs)
    compose up --build
    ;;

  down)
    compose down
    ;;

  stop)
    compose stop
    ;;

  restart)
    compose restart odoo
    ;;

  logs)
    service="${1:-odoo}"
    compose logs -f "$service"
    ;;

  ps|status)
    compose ps
    ;;

  shell)
    compose exec odoo bash
    ;;

  db)
    compose exec db psql -U odoo -d "$DB_NAME"
    ;;

  db-query)
    sql="${1:-}"
    require_arg "$sql" "debes indicar una consulta SQL"
    compose exec db psql -U odoo -d "$DB_NAME" -c "$sql"
    ;;

  install)
    modules="${1:-}"
    require_arg "$modules" "debes indicar uno o mas modulos, separados por coma"
    run_odoo_module_command "i" "$modules"
    ;;

  update)
    modules="${1:-}"
    require_arg "$modules" "debes indicar uno o mas modulos, separados por coma"
    run_odoo_module_command "u" "$modules"
    ;;

  update-all)
    run_odoo_module_command "u" "$DEFAULT_MODULES"
    ;;

  apply-theme)
    apply_theme
    ;;

  module-status)
    compose exec db psql -U odoo -d "$DB_NAME" \
      -c "select name, state from ir_module_module where name in ('risk_module', 'theme_impocoma') order by name;"
    ;;

  backup)
    mkdir -p backups
    backup_file="backups/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
    compose exec -T db pg_dump -U odoo -d "$DB_NAME" > "$backup_file"
    echo "Backup creado: $backup_file"
    ;;

  restore)
    backup_file="${1:-}"
    require_arg "$backup_file" "debes indicar el archivo .sql a restaurar"

    if [[ ! -f "$backup_file" ]]; then
      echo "Error: no existe el archivo $backup_file" >&2
      exit 1
    fi

    compose exec -T db psql -U odoo -d "$DB_NAME" < "$backup_file"
    ;;

  reset)
    confirm_reset
    compose down -v
    ;;

  *)
    echo "Error: comando desconocido: $command" >&2
    echo >&2
    usage >&2
    exit 2
    ;;
esac
