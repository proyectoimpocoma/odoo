# Impocoma Odoo Anti-Patterns

Lista canónica de trampas, deprecateds y errores típicos que se han visto en
este repositorio. Antes de cerrar un cambio, revisa si tocaste alguna de estas
áreas.

## Warnings del entorno (no romper por esto)

- `module izi_data: not installable`: warning del entorno, no relacionado con
  cambios nuevos. Ignorar.
- `_sql_constraints is no longer supported`: warning de Odoo 19 en modelos
  existentes. Convive con cambios no relacionados; no mezclar en el mismo commit.

## Reglas del theme (CSS / SCSS / QWeb)

- **Sass `min()` / `max()` con unidades mixtas** (`px` con `vw` o `%`) rompe
  compilación. Usar `width` + `max-width` separados.
- **`hasclass()` sobre clase de `t-attf-class`**: no usar para decidir la
  herencia de una vista QWeb. Preferir atributos estáticos cuando existan.
- **Carga de assets del tema corporativo**:
  - Variables → `web._assets_primary_variables`.
  - Login y website público → `web.assets_frontend`.
  - App Dashboard del backend → `web.assets_backend`.
  - Cargar el dashboard en `web.assets_frontend` no se ve.
- **No forzar el color del navbar** desde un módulo de negocio. Lo gobierna
  `$o-navbar-background`.
- **No hardcodear la paleta Impocoma** (naranja `#f77c00`, azul `#003b73`,
  texto `#121c2c`, líneas `#cbd5e0`, fondos suaves `#f5f7fa`). Usar
  `$imp-*` de `primary_variables.scss`.

## Vistas XML (Odoo 19)

- **`<tree>`** → `<list>`.
- **`attrs="{...}"`** y **`states="..."`** → modificadores inline
  (`invisible="..."`, `readonly="..."`, `required="..."`).
- **Search view `<group expand="0" string="Group By">`** → debe ser
  `<group name="group_by">` (sin `expand`, sin `string`). El RNG de search
  no admite esos atributos.
- **`<kanban-box>`** → `<t t-name="card">` en templates kanban.
- **`class="alert alert-*"`** sin `role`. Añadir `role="status"` para
  informativos o `role="alert"` para interrumpir al usuario.
- **Acciones antes de menús**: si un menú referencia una acción, la acción
  debe cargarse antes en el manifest.

## QWeb templates

- **`t-esc`** → `t-out` (escape correcto y compatible con v19).
- **`t-raw`** en contenido editable por el usuario es vector XSS. Usar
  `t-out` con un `Markup` sanitizado, o `html_sanitize`.
- **Inline `<script>...</script>`** en páginas públicas puede ser bloqueado
  por CSP. Mover la lógica a `static/src/js/` y cargarla desde el manifest.
- **CDN externos** (Bootstrap, Google Fonts, etc.) rompen la promesa
  self-hosted y CSP. Vendorizar en `static/lib/`.
- **Mail templates**: los subjects construidos dentro de `{{ }}` no se
  extraen como término traducible. Mantenerlos como literal o construirlos
  en Python con `_()` y `email_values={"subject": ...}`.

## Controladores / HTTP

- **`type='json'`** → `type='jsonrpc'`. (`type='http'` no cambia).
- **`website=True`** sin depender realmente de `website`. Acopla a un módulo
  no declarado.
- **Rutas POST públicas** deben usar `csrf=True` y validar server-side aunque
  haya validación JS.
- **`sudo()`** solo en la escritura final y solo con campos allowlist. Antes
  de `sudo()`, demostrar propiedad/acceso con chequeos explícitos.

## ORM / Python (Odoo 19)

- **`@api.multi`**: deprecado desde v17. No usarlo.
- **`read_group(...)`** → `formatted_read_group(...)` (público) o
  `_read_group(...)` (interno, nueva firma).
- **`_flush_search()`**: deprecado. El flushing ocurre en `execute_query()`.
- **`name_get()`** → definir `_compute_display_name` o leer `display_name`.
- **`record._cr` / `record._context` / `record._uid`** → usar
  `self.env.cr` / `self.env.context` / `self.env.uid`.
- **`from odoo import registry`** → `from odoo.modules.registry import Registry`.
- **`_name` faltante** cuando el nombre CamelCase ya mapea correctamente
  (`ResPartner` → `res.partner`) es válido en v19. No añadir `_name` redundante.
- **`SQL crudo con `+` o `%` para interpolar** es SQL injection. Usar
  `psycopg2` con placeholders `%s` o `odoo.tools.SQL`.
- **`getattr(record, field_user_input)`** permite acceder a cualquier
  atributo. Usar `record[field_user_input]`.
- **`eval()`** sobre input del usuario: usar `ast.literal_eval` para parsing
  seguro o `odoo.tools.safe_eval` con `globals_dict` y `locals_dict` explícitos.

## Seguridad

- **`res.partner.title`** fue eliminado en v19. Dejar de referenciarlo.
- **`res.groups`** ya no usa `category_id` directo. Usar
  `ir.module.category` + `res.groups.privilege` + `res.groups` con
  `privilege_id` (ver `docs/ai/permissions_policy.md`).
- **`perm_unlink=1`** por defecto en registros de negocio, solicitudes,
  documentos y datos sensibles está prohibido. `0` por defecto.
- **Sin grupos explícitos** confiando solo en `base.group_user` o reglas ad
  hoc: violar la política de permisos.

## Manifest

- **`version`** debe ser `19.0.x.y.z`. Bump en cada cambio mayor.
- **`external_dependencies`**: usar el nombre de distribución PyPI, no el de
  import (`Pillow`, no `PIL`).
- **`pypdf` no se puede declarar** en la imagen `odoo:19.0` oficial (Odoo
  usa `odoo.tools.pdf`). Si el código degrada con `try/except ImportError`,
  no declararlo.
- **`category`** de un módulo Impocoma debe ser `"Impocoma"`, no `"Tools"`.
- **`depends`** por defecto: `["base", "mail", "web", "theme_impocoma"]`
  para módulos de negocio con UI propia (ver `module_blueprint.md`).

## Rendimiento

- **`search_count` dentro de un loop** → usar `_read_group` con un solo
  dominio sobre el recordset completo.
- **`@api.depends('partner_id')`** con `record.partner_id.email` adentro
  genera N queries. Usar paths con punto: `@api.depends('partner_id.email')`.
- **`with_context(...)` encadenado** varias veces. Consolidar en un solo
  `with_context(lang=..., active_test=False, ...)`.
- **`invalidate_cache()` global** cuando solo cambiaron algunos campos. Usar
  `invalidate_recordset(['field1', 'field2'])`.
- **`formatted_read_group` con `lazy=False`** cuando se van a contar
  registros: más eficiente que `read_group` + `len()`.

## Git

- **Commits de `risk_module`** deben hacerse desde su propio directorio
  (es un submódulo Git anidado).
- **Revertir cambios no hechos** por uno mismo: prohibido.
- **`git status --short`** antes de editar y antes de cerrar.
