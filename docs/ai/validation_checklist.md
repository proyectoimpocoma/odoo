# Impocoma Odoo Validation Checklist

Run the checks that match the touched files before finishing.

## Static Checks

Revisar tamaño y responsabilidades:

```bash
find modules/addon_name -type f \
  \( -name '*.py' -o -name '*.js' -o -name '*.scss' -o -name '*.xml' \) \
  -exec wc -l {} + | sort -nr
```

Todo archivo manual por encima de 400 líneas debe factorizarse o quedar con
justificación temporal y un plan explícito de extracción.

Compile Python:

```bash
python3 -m py_compile modules/addon_name/__init__.py modules/addon_name/models/*.py
```

Parse XML:

```bash
python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree as ET
for path in Path("modules/addon_name").rglob("*.xml"):
    ET.parse(path)
    print(path, "ok")
PY
```

Check JavaScript when present:

```bash
node --check modules/addon_name/static/src/js/file.js
```

Check for generated Python cache files:

```bash
find modules/addon_name -name "__pycache__" -type d -print
```

## Multilanguage Checks

When the addon has translated UI, mail, reports or public pages, follow
`docs/ai/i18n_guide.md` and verify all four layers: source, catalogs, database
and rendered output.

- Runtime source literals are English; Spanish exists in `msgstr` values.
- The current POT has no Spanish `msgid` terms.
- `es.po` and `es_CO.po` have no missing or fuzzy module-owned entries.
- Placeholders and HTML/QWeb structure match between `msgid` and `msgstr`.
- Existing `noupdate="1"` translated records have a safe versioned migration.
- Standalone pages apply the effective language and emit the matching HTML
  `lang` attribute.
- Runtime tests compare menus, fields and stored translated values under
  `en_US` and `es_CO`.

```bash
msgfmt --check --check-format \
  modules/addon_name/i18n/es.po -o /dev/null
msgfmt --check --check-format \
  modules/addon_name/i18n/es_CO.po -o /dev/null
```

If an existing database keeps an old translation after `-u`, import the
corrected PO deliberately with `odoo i18n import -w`; a clean file alone is not
runtime proof.

## Manifest Checks

- Every XML file needed by Odoo is listed in `data`.
- Every asset path exists.
- If the module has a launcher icon, `static/description/icon.png` is
  `200 x 200`, has alpha, has transparent corners, and the root menu has
  `web_icon="addon_name,static/description/icon.png"`.
- Security files load before views.
- Actions load before menus.
- Optional dependencies are only added when used.

## Odoo Update

When runtime validation is needed:

```bash
./scripts/docker.sh update addon_name
```

Check logs:

```bash
docker compose logs --tail=120 odoo
```
