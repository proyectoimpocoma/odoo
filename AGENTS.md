# AGENTS.md

Guia para agentes que trabajen en este proyecto Odoo. Lee este archivo antes de editar codigo, crear modulos, actualizar vistas o ejecutar comandos.

## Proyecto

Este repositorio contiene una instalacion local de Odoo 19 con Docker.

Rutas principales:

- `docker-compose.yml`: define PostgreSQL y Odoo.
- `Dockerfile.odoo`: imagen local de Odoo.
- `config/odoo.docker.conf`: configuracion usada dentro del contenedor.
- `modules/`: addons montados en `/mnt/extra-addons`.
- `backups/`: respaldos SQL locales.
- `scripts/`: comandos auxiliares por plataforma.

Servicios Docker:

- Base de datos: `odoo-postgres`, PostgreSQL 16.
- Odoo: `odoo19`, expuesto en `http://localhost:8069`.
- Base local por defecto: `mi_empresa`.

Comandos frecuentes:

```bash
./scripts/docker.sh init
docker compose ps
docker compose logs --tail=120 odoo
docker compose restart odoo
docker compose exec -T odoo odoo -c /etc/odoo/odoo.conf -d mi_empresa -u module_name --stop-after-init --no-http
```

Usa `./scripts/docker.sh init` o `scripts/docker-windows.ps1 init` para una primera ejecucion. `up` solo levanta contenedores; no instala el esquema/modulos de Odoo en una base nueva.

Despues de actualizar un modulo con `--stop-after-init --no-http`, reinicia Odoo:

```bash
docker compose restart odoo
```

## Modulos Actuales

### `modules/risk_module`

Modulo principal del negocio de riesgo/habilitacion de terceros.

Responsabilidades:

- Formulario publico paso a paso para habilitacion de terceros.
- Portal de usuario para consultar solicitudes.
- Backend para analistas y administradores.
- Documentos requeridos, revision, rechazos, firmas, OTP y reportes.
- Integracion SharePoint/Microsoft Graph.
- Advertencias/validaciones de riesgo.
- Plantillas de mensajes.

Estructura relevante:

- `controllers/`: rutas HTTP, flujo del formulario, portal y firma/OTP.
- `models/`: modelos ORM, reglas de negocio, SharePoint y sincronizacion.
- `models/risk_submission_mixins/`: logica separada por responsabilidad.
- `views/backend/`: vistas internas de Odoo.
- `views/website/`: templates del formulario publico y portal.
- `views/wizards/`: asistentes de aprobacion/rechazo/SharePoint.
- `views/mail/`: plantillas de correo.
- `views/reports/`: reportes imprimibles.
- `data/`: configuracion inicial, rutas SharePoint, documentos y plantillas.
- `security/`: grupos y accesos.
- `static/src/css/`: estilos frontend/backend.
- `static/src/js/`: comportamiento del formulario.
- `tests/`: pruebas del modulo.
- `migrations/`: scripts por version.

Nota Git: `modules/risk_module` es un repositorio Git anidado. Si haces commits de risk, entra a ese directorio y usa Git desde ahi. El repo raiz solo vera el modulo como un directorio modificado.

### `modules/theme_impocoma`

Tema corporativo Impocoma para website, login y variables visuales.

Responsabilidades:

- Paleta corporativa.
- Header/footer publico del website.
- Pantalla de login personalizada.
- Logo corporativo en `static/src/img/impocoma_logo.jpeg`.

Paleta estandar:

- Naranja primario: `#f77c00`.
- Azul marino secundario: `#003b73`.
- Texto principal: `#121c2c`.
- Lineas/bordes suaves: `#cbd5e0`.
- Fondos suaves: `#f5f7fa`.

Archivos clave:

- `static/src/scss/primary_variables.scss`: variables primarias de Odoo.
- `static/src/scss/login.scss`: login publico.
- `static/src/scss/website_layout.scss`: header/footer publico.
- `views/login_templates.xml`: branding del login.
- `views/website_layout_templates.xml`: header y footer.

Reglas importantes:

- Carga variables en `web._assets_primary_variables`.
- Carga estilos de login/website en `web.assets_frontend`.
- Evita `min()` Sass con unidades mixtas (`px` y `vw/%`). Usa `width` + `max-width`.
- Para heredar vistas QWeb, evita depender de clases dinamicas con `hasclass()` si la clase viene de `t-attf-class`; usa atributos estaticos cuando existan.

### `modules/custom_app_dashboard`

Modulo de dashboard/app launcher de backend para Odoo Community. Es de tipo UI backend y depende de `web`.

## Estandar Para Nuevos Modulos

Crear addons nuevos dentro de `modules/` con nombre `snake_case`, sin guiones.

Estructura base recomendada:

```text
modules/addon_name/
├── __init__.py
├── __manifest__.py
├── controllers/
│   ├── __init__.py
│   └── record_controller.py
├── models/
│   ├── __init__.py
│   └── record.py
├── security/
│   ├── groups.xml
│   └── ir.model.access.csv
├── static/
│   └── src/
│       ├── css/
│       ├── js/
│       └── scss/
├── views/
│   ├── backend/
│   ├── website/
│   └── wizards/
└── tests/
```

Para un modulo backend simple, puedes omitir `controllers/`, `views/website/`, `static/src/js/` y `tests/` si no aplican.

Convenciones:

- Modelo Odoo: nombre de negocio con punto, por ejemplo `risk.submission` o `fleet.onboarding.request`.
- Clase Python: PascalCase, por ejemplo `RiskSubmission`.
- Archivo Python: `snake_case`, por ejemplo `risk_submission.py`.
- XML IDs: claros y prefijados por proposito:
  - `view_model_name_list`
  - `view_model_name_form`
  - `action_model_name`
  - `menu_model_name_root`
- No renombres `_name` de modelos existentes sin plan de migracion.
- No mezcles CSS/JS inline dentro de XML salvo prototipos muy pequenos.

Manifest recomendado:

```python
{
    "name": "Human Module Name",
    "version": "19.0.1.0.0",
    "category": "Impocoma",
    "summary": "Resumen corto de negocio",
    "depends": ["base", "website"],
    "data": [
        "security/groups.xml",
        "security/ir.model.access.csv",
        "views/backend/record_views.xml",
        "views/backend/record_menus.xml",
        "views/website/record_templates.xml",
    ],
    "assets": {
        "web.assets_frontend": [
            "addon_name/static/src/css/record.css",
            "addon_name/static/src/js/record.js",
        ],
    },
    "installable": True,
    "application": True,
    "license": "LGPL-3",
}
```

Orden de carga:

1. Datos base/configuracion.
2. `security/groups.xml`.
3. `security/ir.model.access.csv`.
4. Vistas, acciones y menus.
5. Templates website.

Si un menu referencia una accion, carga la accion antes del menu.

## Formularios Website

Para formularios publicos o multi-paso:

- Usa rutas `auth="public"`, `website=True` y `csrf=True` para POST salvo razon concreta.
- Guarda borradores multi-paso en `request.session`.
- Mantiene una lista permitida de campos por paso.
- Valida del lado servidor aunque exista validacion JS.
- Usa `sudo()` solo en la escritura final y con campos allowlist.
- Limpia la sesion al completar.
- Para datos sensibles, limita el acceso backend con grupos especificos.

En `risk_module`, antes de cambiar un paso del formulario revisa juntos:

- `controllers/risk_submission_controller.py`
- `controllers/risk_submission_form_schema.py`
- Templates en `views/website/website_risk_submission_step_*.xml`
- JS relacionado en `static/src/js/risk_submission_*.js`
- Tests en `tests/test_risk_submission.py`

## Seguridad y Accesos

Para modulos productivos crea grupos propios:

```xml
<record id="group_record_user" model="res.groups">
    <field name="name">Record User</field>
</record>

<record id="group_record_manager" model="res.groups">
    <field name="name">Record Manager</field>
    <field name="implied_ids" eval="[(4, ref('group_record_user'))]"/>
</record>
```

Access CSV ejemplo:

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_record_user,record.user,model_addon_record,addon_name.group_record_user,1,1,1,0
access_record_manager,record.manager,model_addon_record,addon_name.group_record_manager,1,1,1,1
```

Defaults:

- Evita `perm_unlink=1` para solicitudes, documentos o registros sensibles.
- Protege cedulas, telefonos, correos, documentos, credenciales GPS, secretos Graph y datos legales.
- Las opciones SharePoint deben ser visibles/editables solo para administradores.

## Estandar Visual

Usa `theme_impocoma` como fuente de identidad visual.

- Reutiliza la paleta Impocoma: naranja `#f77c00`, azul `#003b73`, texto `#121c2c`.
- Mantiene interfaces de negocio densas, limpias y escaneables.
- Evita layouts tipo landing cuando se construyan herramientas operativas.
- En formularios, agrupa por pasos claros y muestra errores junto al campo o bloque afectado.
- No agregues textos explicativos decorativos dentro de la UI si no ayudan a completar la tarea.
- Usa botones con etiquetas directas: `Crear cuenta`, `Continuar`, `Guardar`, `Enviar`.
- Para portal publico, usa "Habilitacion Terceros" en lugar de "Solicitud de riesgo" cuando sea visible al usuario final.

## Validacion Antes de Terminar

Chequeos rapidos:

```bash
python3 -m py_compile modules/addon_name/__init__.py modules/addon_name/models/*.py modules/addon_name/controllers/*.py
python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree as ET
for path in Path("modules/addon_name").rglob("*.xml"):
    ET.parse(path)
    print(path, "ok")
PY
node --check modules/addon_name/static/src/js/file.js
```

Actualizar modulo:

```bash
docker compose exec -T odoo odoo -c /etc/odoo/odoo.conf -d mi_empresa -u addon_name --stop-after-init --no-http
docker compose restart odoo
```

Verificar pagina:

```bash
curl -sS -o /tmp/page.html -w '%{http_code}\n' --max-time 3 http://localhost:8069/web/login
```

Para assets o estilos, revisa logs:

```bash
docker compose logs --tail=120 odoo
```

Errores conocidos:

- `module izi_data: not installable`: warning actual del entorno, no necesariamente relacionado con cambios nuevos.
- `_sql_constraints is no longer supported`: warning de Odoo 19 en modelos existentes; no lo mezcles con cambios no relacionados.
- Error Sass por unidades incompatibles: evita funciones Sass `min()`/`max()` con unidades mixtas.

## Git

- No reviertas cambios que no hiciste.
- Revisa `git status --short` antes de editar y antes de terminar.
- `modules/risk_module` tiene Git propio; confirma commits de risk desde ese directorio.
- El repo raiz debe registrar cambios generales como Docker, theme y punteros de modulos anidados cuando aplique.

Comandos utiles:

```bash
git status --short
git diff -- path/to/file
git -C modules/risk_module status --short
git -C modules/risk_module diff -- path/to/file
```
