# Impocoma Odoo 18 → 19 Migration Guide

Detailed, battle-tested guide for migrating custom addons from Odoo 18 to Odoo 19.
Written from real migrations in this repository. Apply it in order and validate after
each phase.

## Mindset

- Code that parses and compiles is **not** proof of compatibility. Odoo validates views
  against a RELAX NG (RNG) schema at install time. Many 18→19 breakages only surface when
  the module is actually installed.
- When a view fails, **read the `RELAXNGV` lines in the log, not only the final
  `ParseError`**. The final error names the view; the `RELAXNGV` lines name the exact
  element and attribute.
- When unsure about the correct 19 syntax, **do not guess**. Check the real source on the
  `19.0` branch: the RNG schema and a core view that already uses the pattern.

## Phase 0 — Validation Workflow (use throughout)

Static checks (fast, local, catch syntax only):

```bash
python3 -m py_compile modules/ADDON/__init__.py modules/ADDON/models/*.py modules/ADDON/controllers/*.py
python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree as ET
for p in Path("modules/ADDON").rglob("*.xml"):
    ET.parse(p); print(p, "ok")
PY
```

Runtime check (the only real proof — RNG + ORM + assets):

```bash
./scripts/docker.sh install ADDON
docker compose logs --tail=160 odoo
```

Authoritative references when a pattern is in doubt:

- View schemas: `https://raw.githubusercontent.com/odoo/odoo/19.0/odoo/addons/base/rng/search_view.rng`
  and `.../base/rng/common.rng` (the `<group>`, `<field>`, `<container>` definitions live here).
- A working core view, e.g. `.../base/views/res_partner_views.xml`, to copy the exact 19 syntax.

## Phase 1 — Manifest

- Bump `version` to `19.0.x.y.z`.
- Update any `"... for Odoo 18"` text in `description`.
- **Do not add `external_dependencies` unless the library is truly mandatory.** This is a
  hard install gate in Odoo (`importlib.metadata.version(name)`); a missing package aborts
  the whole DB init. Two traps:
  - Use the **PyPI distribution name**, not the import name: `Pillow`, not `PIL`.
  - `pypdf` is **not** declarable on the official `odoo:19.0` image (Odoo ships its PDF
    helpers under `odoo.tools.pdf`; `pypdf` has no package metadata there). Declaring it
    raises `MissingDependency: pypdf`.
  - If the code already degrades gracefully (try/except ImportError with a fallback), the
    library is optional — leave it out of the manifest.
- `web.assets_frontend` / `web.assets_backend` bundle names are unchanged in 19.

## Phase 2 — Views (XML) — the highest-risk area

### 2.1 Lists
- `<tree>` → `<list>` (already required since 17; verify none remain).

### 2.2 Modifiers
- `attrs="{...}"` and `states="..."` are gone. Use inline Python:
  `invisible="state != 'draft'"`, `readonly="..."`, `required="..."`.

### 2.3 Search views — `<group>` for "Group By" (real 18→19 break)
In a `<search>`, the group-by wrapper changed. Per `common.rng`, the search `<group>`
allows `name`, `colspan`, `rowspan`, `fill`, `height`, `width`, `color`, `invisible` —
but **NOT `expand` and NOT `string`**.

```xml
<!-- WRONG in 19 (works in form views, fails RNG in search views) -->
<group expand="0" string="Group By">
    <filter string="State" name="group_state" context="{'group_by': 'state'}"/>
</group>

<!-- CORRECT in 19 (matches core res.partner search view) -->
<group name="group_by">
    <filter string="State" name="group_state" context="{'group_by': 'state'}"/>
</group>
```

Notes:
- The visible "Group By" label is **not** taken from the group; each `<filter>`'s `string`
  is its own label, and `context="{'group_by': ...}"` places it under the Group By menu.
- A malformed search `<group>` cascades: the log also reports
  `Element search has extra content: field` and `Expecting an element field, got nothing`.
  Fix the group; the cascade clears.
- `<group string="...">` is **still valid in form views** — this stricter rule is search-only.
  Do not "fix" form groups by removing their `string`.

### 2.4 Kanban
- `<kanban-box>` → `<card>` for kanban templates (only if the module has a kanban view).

### 2.5 Accessibility (warning, not fatal, but clean it up)
- Any `class="alert alert-*"` element must carry a role. Use `role="status"` for
  informational banners, `role="alert"` only for content that must interrupt the user.

```xml
<div class="alert alert-success mb-3" role="status" invisible="state != 'signed'">
```

### 2.6 Still valid in 19 (no change needed)
- `<chatter/>` (the 18+ replacement for `<div class="oe_chatter">`).
- `widget="statusbar|badge|url|binary|html"`, `decoration-*`, `optional="show|hide"`,
  `editable="bottom"`, `oe_button_box` / `oe_stat_button` / `oe_title`.
- `<menuitem>` with `web_icon`, `parent`, `action`, `sequence`.

## Phase 3 — QWeb templates

- `t-esc` → `t-out` everywhere. `t-raw` is gone (use `t-out` on a Markup value).
- Public/standalone HTML pages rendered via `request.render` still work, but beware
  **Content-Security-Policy** in 19:
  - Avoid inline `<script>...</script>` blocks in templates — move logic into a JS file
    loaded from the addon (`/ADDON/static/src/js/...`). Inline scripts can be blocked by CSP.
  - Do not load third-party CSS/JS from a CDN (Bootstrap, Google Fonts, etc.). Vendor them
    into `static/lib/` and reference them locally. CDN assets break the "self-hosted" promise
    and can be blocked by CSP.
- Mail templates: Jinja2 syntax (`{% if %}`, `| safe`) was removed back in v14 and stays
  removed. Use QWeb `inline_template` rendering, or build the body in Python. Delete dead
  Jinja templates rather than shipping them.

## Phase 4 — Controllers / HTTP

- `type='json'` routes → `type='jsonrpc'`. (`type='http'` routes are unaffected.)
- Drop `website=True` unless the addon actually depends on the `website` module and renders
  inside `web.layout`. Standalone pages do not need it; keeping it couples you to an
  undeclared dependency.
- House rule for public POST routes: prefer `csrf=True`; validate server-side; use `sudo()`
  only on the final write and only after proving ownership/access.

## Phase 5 — ORM / Python

Check for and replace these (rare in small addons, but breaking):

- `name_get()` → define `_compute_display_name` / read the `display_name` field.
- `read_group(...)` → `formatted_read_group(...)` (public) or `_read_group(...)` (internal,
  new signature).
- `_flush_search()` is deprecated (flushing happens in `execute_query()`).
- Deprecated attributes: `record._cr`, `record._context`, `record._uid` → use
  `self.env.cr`, `self.env.context`, `self.env.uid`.
- Registry import: `from odoo import registry` → `from odoo.modules.registry import Registry`.
- These stay valid in 19: `@api.model_create_multi` (`def create(self, vals_list)`),
  `@api.depends`, `mail.thread` / `mail.activity.mixin`, `from odoo.tools.pdf import PdfReader, PdfWriter`,
  `message_post(body=..., message_type="notification")`, `secrets.token_urlsafe(...)`.
- Python 3.11+ runtime; f-strings, `secrets`, `base64`, `re` are all fine.

## Phase 6 — Security

- `res.partner.title` model was removed — stop referencing it.
- New privilege model `res.groups.privilege` groups categories. When you define custom
  groups, follow `permissions_policy.md` (explicit user/manager groups, `perm_unlink=0` by
  default). Using `base.group_user` directly still installs but is a policy violation, not a
  19 break.

## Quick checklist

- [ ] Manifest `version` is `19.0.*`; no risky `external_dependencies` (PyPI names, no `pypdf`).
- [ ] No `<tree>`, no `attrs=`/`states=`.
- [ ] Every search `<group>` is `<group name="group_by">` (no `expand`, no `string`).
- [ ] No `<kanban-box>`; alerts have `role`.
- [ ] No `t-esc` / `t-raw`; no inline `<script>` or CDN assets in public pages.
- [ ] No `type='json'`; no stray `website=True`; public POST uses `csrf=True`.
- [ ] No `name_get`, `read_group`, `_flush_search`, `._cr/._context/._uid`, old registry import.
- [ ] `./scripts/docker.sh install ADDON` installs clean; logs show no `RELAXNGV` warnings.
