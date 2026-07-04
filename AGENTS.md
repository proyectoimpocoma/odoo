# AGENTS.md — Odoo Impocoma

Índice de reglas para agentes que trabajen en este proyecto Odoo 19 con
Docker. Esta es la **puerta de entrada**; las reglas viven en `docs/ai/`.

> **Regla de mantenimiento**: este archivo no contiene reglas de negocio.
> Si necesitas añadir una regla, muévela a `docs/ai/anti_patterns.md` o a la
> guía que corresponda. Aquí solo se indexa.

## Proyecto

Instalación local de Odoo 19 con Docker. Servicios: `odoo-postgres` y
`odoo19` (puerto 8069). Base por defecto: `mi_empresa`. Addons montados desde
`modules/` en `/mnt/extra-addons`.

Detalle del entorno y comandos en:

- `README.md` (entrada de usuario).
- `README_DOCKER.md` (comandos Docker completos, scripts por plataforma).
- `scripts/docker.sh` y `scripts/docker-windows.ps1` (helpers).

Para una primera ejecución usa `./scripts/docker.sh init`. Solo `up` no
instala el esquema ni los módulos en una base nueva.

## Módulos Actuales

### `modules/risk_module`

Módulo de negocio principal: habilitación de terceros (formulario público,
portal, backend, SharePoint, OTP, firmas, reportes). Estructura y
responsabilidades detalladas en `README.md`. Antes de tocar un paso del
formulario, revisa juntos:

- `controllers/risk_submission_controller.py`
- `controllers/risk_submission_form_schema.py`
- `views/website/website_risk_submission_step_*.xml`
- `static/src/js/risk_submission_*.js`
- `tests/test_risk_submission.py`

### `modules/theme_impocoma`

Tema corporativo (paleta, login, website, App Dashboard). Variables SCSS,
asset bundles y trampas en `docs/ai/theme_usage.md`.

## Cuándo Leer Qué Guía de `docs/ai/`

| Tarea | Guía |
|---|---|
| Crear o extender un módulo | `module_blueprint.md` |
| Grupos, ACL, record rules | `permissions_policy.md` |
| Antes de cerrar un cambio (checks) | `validation_checklist.md` |
| Migrar de 18 a 19, RELAXNG, deprecateds | `migration_18_to_19.md` |
| Traducciones, `_()`, `.po` | `i18n_guide.md` |
| Tema, SCSS, asset bundles | `theme_usage.md` |
| Crear o corregir iconos de módulos | `module_icons.md` |
| Errores típicos, trampas, deprecateds | `anti_patterns.md` |

## Errores Más Disruptivos del Repo

Lista corta. La canónica y completa está en `docs/ai/anti_patterns.md`.

- `module izi_data: not installable`: warning del entorno, ignorar.
- No usar `_sql_constraints`: en Odoo 19 el estándar del repo es
  `models.Constraint` con atributo privado.
- Sass `min()` con unidades mixtas: rompe compilación.
- `t-attf-class` + `hasclass()`: no usar para heredar vistas QWeb.
- `<group expand="0" string="Group By">` en search view: debe ser
  `<group name="group_by">`.
- Icono de módulo que no aparece: no basta con
  `static/description/icon.png`; el menú raíz debe tener `web_icon` y el
  módulo debe actualizarse para poblar `web_icon_data`.

## Skills Cargadas

- `.agents/skills/odoo-19/`: base de conocimiento Odoo 19 (18 guías + API
  highlights). Referencia de API, ORM, decoradores, views, seguridad,
  rendimiento. La única skill Odoo del proyecto.
- `skills-lock.json`: lock con el `computedHash` esperado. Si cambia el
  contenido, actualizar el hash o re-vincular con `npx skills update`.

## Git

- `modules/risk_module` es **repo Git anidado**. Commits de risk van desde
  ese directorio (`git -C modules/risk_module ...` o entrar y usar Git).
- Repo raíz registra cambios generales: Docker, theme, `docs/ai/`, prompts
  de `.opencode/`, lock, `AGENTS.md`.
- No revertir cambios que no hiciste.
- Antes de editar y antes de cerrar: `git status --short` y revisar
  `git diff`.
