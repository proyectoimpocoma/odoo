# Impocoma Odoo Validation Checklist

Run the checks that match the touched files before finishing.

## Static Checks

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
docker compose exec -T odoo odoo -c /etc/odoo/odoo.conf -d mi_empresa -u addon_name --stop-after-init --no-http
docker compose restart odoo
```

Check logs:

```bash
docker compose logs --tail=120 odoo
```
