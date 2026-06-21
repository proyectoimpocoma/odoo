# Proyecto Odoo Impocoma

Entorno local de Odoo 19 para desarrollo de modulos personalizados de Impocoma. El proyecto usa Docker Compose con PostgreSQL 16 y monta los addons locales desde `modules/`.

## Contenido

- `risk_module`: modulo principal para habilitacion de terceros, gestion documental, revision de riesgo, portal y SharePoint.
- `theme_impocoma`: tema corporativo para login, website y estilos base.
- `custom_app_dashboard`: dashboard/app launcher para backend de Odoo Community.
- `docker-compose.yml`: servicios `db` y `odoo`.
- `Dockerfile.odoo`: imagen Odoo con dependencias Python adicionales.
- `config/odoo.docker.conf`: configuracion usada dentro del contenedor.
- `scripts/`: utilidades para levantar, instalar, actualizar, respaldar y restaurar.

## Requisitos

- Docker Desktop.
- Docker Compose.
- En Windows, PowerShell.

## Primera Ejecucion

En Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 init
```

En macOS/Linux:

```bash
./scripts/docker.sh init
```

El comando `init`:

1. Construye y levanta los contenedores.
2. Espera a que PostgreSQL este listo.
3. Instala `theme_impocoma,risk_module`.
4. Reinicia Odoo.

Luego abre:

```text
http://localhost:8069
```

Base local por defecto:

```text
mi_empresa
```

## Uso Diario

Levantar el entorno:

```bash
./scripts/docker.sh up
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 up
```

Ver estado:

```bash
./scripts/docker.sh ps
```

Ver logs:

```bash
./scripts/docker.sh logs
```

Reiniciar Odoo:

```bash
./scripts/docker.sh restart
```

Detener sin borrar datos:

```bash
./scripts/docker.sh down
```

## Instalar o Actualizar Modulos

Instalar modulos:

```bash
./scripts/docker.sh install theme_impocoma,risk_module
```

Actualizar modulos principales:

```bash
./scripts/docker.sh update-all
```

Actualizar solo un modulo:

```bash
./scripts/docker.sh update risk_module
```

Equivalente Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 update risk_module
```

## Modulos

### `risk_module`

Modulo de negocio para el flujo de habilitacion de terceros.

Incluye:

- Formulario publico paso a paso.
- Portal para consultar solicitudes.
- Backend para analistas y administradores.
- Validaciones de riesgo.
- Gestion documental.
- Rechazos y correcciones.
- Firmas y verificacion por correo.
- Plantillas de mensajes.
- Integracion con SharePoint/Microsoft Graph.

Rutas relevantes:

- `modules/risk_module/controllers/`
- `modules/risk_module/models/`
- `modules/risk_module/views/backend/`
- `modules/risk_module/views/website/`
- `modules/risk_module/static/src/css/`
- `modules/risk_module/static/src/js/`
- `modules/risk_module/tests/`

Nota: `modules/risk_module` es un repositorio Git anidado. Para commits del modulo de riesgo, usa Git dentro de esa carpeta.

### `theme_impocoma`

Tema corporativo Impocoma.

Incluye:

- Login personalizado.
- Header/footer publico.
- Logo y paleta corporativa.
- Variables SCSS para Odoo.

Paleta:

- Naranja: `#f77c00`.
- Azul marino: `#003b73`.
- Texto: `#121c2c`.

### `custom_app_dashboard`

Modulo UI para dashboard/app launcher en Odoo Community.

## Base de Datos

Entrar a `psql`:

```bash
./scripts/docker.sh db
```

Ejecutar una consulta:

```bash
./scripts/docker.sh db-query "select name, state from ir_module_module order by name limit 10;"
```

Ver estado de modulos principales:

```bash
./scripts/docker.sh module-status
```

## Backup y Restore

Crear backup:

```bash
./scripts/docker.sh backup
```

Restaurar backup:

```bash
./scripts/docker.sh restore backups/mi_empresa_YYYYmmdd_HHMMSS.sql
```

## Reset Completo

Este comando borra contenedores, volumenes, base de datos y filestore. Pide confirmacion escribiendo el nombre de la base.

```bash
./scripts/docker.sh reset
```

Luego vuelve a inicializar:

```bash
./scripts/docker.sh init
```

## Desarrollo

Reglas practicas:

- Cambios Python simples: reinicia Odoo.
- Cambios XML, modelos, security, data, assets o manifest: actualiza el modulo con `update`.
- Cambios en dependencias Python: modifica `Dockerfile.odoo` y reconstruye.
- No edites codigo dentro del contenedor; edita en `modules/`.
- Los addons locales se montan en `/mnt/extra-addons`.

Checks utiles:

```bash
python3 -m py_compile modules/risk_module/controllers/*.py modules/risk_module/models/*.py
python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree as ET
for path in Path("modules/risk_module").rglob("*.xml"):
    ET.parse(path)
    print(path, "ok")
PY
```

## Documentacion Relacionada

- `README_DOCKER.md`: detalle del entorno Docker.
- `AGENTS.md`: guia para agentes de desarrollo y convenciones del proyecto.

