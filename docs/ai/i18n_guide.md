# Impocoma Odoo Multilanguage (i18n) Guide

Canonical workflow for building and validating multilingual Odoo 19 addons in
this repository. The rules were verified in production code while normalizing
`easy_sign` to an English source with complete `es` and `es_CO` translations.

## Language contract

Every addon must follow this contract:

1. **English is the only source language.** User-facing literals in Python,
   XML, QWeb, mail templates, JavaScript and seed data are written in English.
2. **Other languages exist only as translations.** Spanish belongs in the
   `msgstr` values of `i18n/es.po` and `i18n/es_CO.po`, never in a runtime
   `msgid`.
3. **Do not create `en.po`.** With English source strings, `en_US` reads the
   source directly.
4. **Both generic and regional catalogs must be valid.** `es.po` is the Spanish
   base and `es_CO.po` is the Colombian override. Keep them aligned unless a
   regional wording difference is intentional.
5. **The database is part of the acceptance test.** A correct PO file does not
   prove that an existing database stopped serving stale translations.

This contract applies to runtime/product text. User-entered data, intentional
test fixtures, contributor documentation and binary screenshots are not
translation source terms. They must still be reviewed separately when they can
be shown to an end user.

## File-by-file review before changing translations

Inventory the whole addon before exporting catalogs. Use this matrix so a
mixed-language source is not hidden in a file the extractor handles
differently:

| Area | What to inspect |
|---|---|
| `models/`, `controllers/`, `wizards/` | Field labels/help, selections, exceptions, notifications, email subjects, generated PDF text and public responses. |
| `views/`, `report/`, `templates/` | `string`, `help`, `placeholder`, `confirm`, text nodes, menu/action names and standalone HTML attributes. |
| `data/` | Mail subjects/bodies, cron names, sequences and names stored in translatable fields. |
| `security/` | Group, category and record-rule names/descriptions. |
| `static/src/js/` | `_t()` coverage, raw errors exposed to notifications and standalone-page messages. |
| `static/src/xml/` | OWL/QWeb text nodes and attributes such as `title` and `placeholder`. |
| `migrations/` | Existing translated records, especially XML records loaded with `noupdate="1"`. |
| `i18n/` | Current POT coverage, missing/fuzzy/obsolete entries, placeholders and HTML structure. |
| `tests/` | Runtime assertions for every supported language; distinguish fixtures from source literals. |

Search for accented and accent-less leftovers. A POT-based regression test is
the final authority because it scans what Odoo actually extracted; `rg` is only
the fast first pass.

## What Odoo extracts automatically

No `_()` is needed for static declarations that Odoo already marks as
translatable:

- Model `_description`, field `string` and `help`, and selection labels.
- View text and attributes such as `string`, `confirm`, `placeholder` and
  `help`.
- Menu, action, group, record-rule and cron names.
- QWeb text nodes, including reports and standalone pages.
- Mail template `subject` and `body_html`.

```python
name = fields.Char(string="Reference")
state = fields.Selection(
    [("draft", "Draft"), ("sent", "Sent")],
    string="Status",
)
expiry_date = fields.Date(
    help="The signing link will stop working after this date."
)
_description = "Electronic Signature Request"
```

```xml
<menuitem id="menu_sign_root" name="Sign"/>
<field name="subject" placeholder="Enter the email subject..."/>
<button name="action_send" string="Send" confirm="Send this request?"/>
```

The source remains English even when Spanish is the language most users see.

## Python runtime strings

Wrap every Python string shown to a user in `_()`:

```python
from odoo import _
from odoo.exceptions import UserError

raise UserError(_("Upload a PDF document before sending."))
self.message_post(body=_("The request has been cancelled."))
label = _("Signature: %(name)s", name=signer_name)
```

The first argument to `_()` must be a literal:

```python
# Wrong: neither form can be extracted reliably.
_(message)
_(f"Page {page} is invalid.")

# Correct: keep one complete sentence and pass dynamic values separately.
_("Page %(page)s is invalid.", page=page)
_("%(name)s declined. Reason: %(reason)s", name=name, reason=reason)
```

Do not concatenate translated fragments. Word order changes between languages.
If a PDF, attachment or notification is generated for another person, evaluate
the term under that person's effective language:

```python
localized_request = request.with_context(lang=request._signer_lang())
localized_request._create_signed_document()
```

Logs, technical exception codes and developer diagnostics do not need `_()`.
Do not let those raw technical errors reach a user-facing notification.

## JavaScript and OWL

Backend assets use `_t()`:

```javascript
import { _t } from "@web/core/l10n/translation";

this.notification.add(
    _t("Could not read the file. Please try again."),
    { type: "danger" }
);
```

Utilities should return a technical error or code. Translate it at the UI
boundary instead of showing `err.message`, which may be English-only or expose
implementation details.

Standalone public pages often do not load the backend translation service. Put
their messages in translated QWeb nodes and read them from JavaScript:

```xml
<div id="i18n" class="d-none">
    <span data-key="sent">Code sent. Check your email.</span>
</div>
```

```javascript
const I18N = {};
document.querySelectorAll("#i18n [data-key]").forEach((element) => {
    I18N[element.dataset.key] = element.textContent.trim();
});
```

Every key consumed by the public JavaScript must exist in the QWeb block.

## Standalone public QWeb pages

Calling `request.render()` without `web.layout` requires two explicit steps:

1. Apply the effective language before rendering.
2. Set the HTML `lang` attribute from that same context.

```python
def _apply_lang(self, item):
    lang = item.request_id._signer_lang()
    if lang:
        request.update_context(lang=lang)

def _render(self, template, values=None):
    values = dict(values or {})
    values["html_lang"] = (request.env.lang or "en_US").replace("_", "-")
    return request.render(template, values)
```

```xml
<html t-att-lang="html_lang">
```

The language decision must be deterministic. For a signer flow, define the
precedence once, for example: forced request language, then request owner
language, then `en_US`. Reuse it for the page, messages, emails, attachments and
reports.

## Mail templates

Mail `subject` and `body_html` are translatable, but literals hidden inside a
QWeb expression are not reliably extracted:

```xml
<!-- Extractable -->
<field name="subject">Please sign</field>
<field name="lang">{{ object._signer_lang() }}</field>

<!-- Avoid: the literal is buried inside an expression. -->
<field name="subject">{{ 'Please sign: ' + object.name }}</field>
```

For a dynamic subject, build one complete literal in Python with `_()` and pass
it through `email_values`. Every mail template must define the recipient
language and be rendered in both `en_US` and the supported Spanish language
during acceptance testing.

When translating `body_html`, preserve HTML tags, QWeb expressions, variables,
URLs and placeholder counts. Translate only human-readable text.

## Translatable seed data and `noupdate="1"`

A field must declare `translate=True` when its stored values need per-language
variants:

```python
name = fields.Char(required=True, translate=True)
```

Fresh database XML always contains the English source:

```xml
<data noupdate="1">
    <record id="role_customer" model="sign.role">
        <field name="name">Customer</field>
    </record>
</data>
```

Changing that XML does **not** update an existing database because of
`noupdate="1"`. Bump the module version and add a versioned migration. Migrate
only known legacy defaults so customized customer data is preserved:

```python
from odoo import api, SUPERUSER_ID


def migrate(cr, version):
    if not version:
        return
    env = api.Environment(cr, SUPERUSER_ID, {})
    role = env.ref("my_module.role_customer", raise_if_not_found=False)
    if not role:
        return

    english_role = role.with_context(lang="en_US")
    if english_role.name == "Cliente":  # known legacy default only
        english_role.name = "Customer"

    for language in env["res.lang"].search([
        ("active", "=", True),
        ("code", "in", ["es", "es_CO"]),
    ]):
        spanish_role = role.with_context(lang=language.code)
        if spanish_role.name in {"Cliente", "Customer"}:
            spanish_role.name = "Cliente"
```

Test the migration for fresh defaults, legacy defaults, customized values,
idempotency and every active supported language.

## Catalog layout and ownership

```text
i18n/
  my_module.pot  # English msgid template generated by Odoo
  es.po          # generic Spanish
  es_CO.po       # Colombian Spanish overrides
```

Do not create a PO file from scratch. Generate it with Odoo so entries include
the required module and source references. Editing generated `msgstr` values is
expected; do not invent or manually renumber references.

```po
#. module: easy_sign
#: model:ir.model.fields,field_description:easy_sign.field_sign_request__name
msgid "Reference"
msgstr "Referencia"
```

For `es_CO`, Odoo can load the generic `es.po` base and then apply
`es_CO.po`. Both files must remain syntactically valid and current. A complete
regional file is preferred in this repository because it can be audited and
deployed independently.

## Reproducible repository workflow

The validated sequence for this Docker repository is:

### 1. Normalize the source

- Review the addon with the file matrix above.
- Convert every runtime literal to English.
- Add `_()`/`_t()` only where extraction is not automatic.
- Add migrations for stored source values.
- Bump the addon version when a migration is required.

### 2. Update Odoo and export from the extractor

```bash
./scripts/docker.sh update my_module

docker compose exec -T odoo \
  odoo i18n export my_module \
  -c /etc/odoo/odoo.conf \
  -d mi_empresa \
  -l pot es es_CO
```

Export after the source and XML records are registered. The POT is the current
source-of-truth set; do not merge against an old source inventory.

### 3. Translate and validate catalogs

- Fill every module-owned `msgstr`.
- Remove fuzzy status after reviewing the translation.
- Remove obsolete entries or keep them out of completeness counts.
- Preserve `%s`, `%(name)s`, markup, QWeb expressions and numeric literals that
  are semantically significant.
- Keep `es` and `es_CO` aligned unless regional terminology differs.

```bash
msgfmt --check --check-format \
  modules/my_module/i18n/es.po -o /dev/null
msgfmt --check --check-format \
  modules/my_module/i18n/es_CO.po -o /dev/null
```

### 4. Import into an existing database

A normal `-u` may preserve an existing database translation. When correcting
stale terms, explicitly import with overwrite:

```bash
docker compose exec -T odoo \
  odoo i18n import \
  -c /etc/odoo/odoo.conf \
  -d mi_empresa \
  -w -l es_CO \
  /mnt/extra-addons/my_module/i18n/es_CO.po
```

Repeat for `es` when that language is active. Use overwrite deliberately: it
replaces database translations for the imported terms.

### 5. Validate source files and runtime

Run the normal syntax checks plus the module update:

```bash
python3 -m compileall -q \
  modules/my_module/controllers \
  modules/my_module/models \
  modules/my_module/wizards \
  modules/my_module/tests \
  modules/my_module/migrations

rg --files modules/my_module/static/src -g '*.js' -0 \
  | xargs -0 -n1 node --check

python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree as ET

for path in Path("modules/my_module").rglob("*.xml"):
    ET.parse(path)
PY

git diff --check
./scripts/docker.sh update my_module
```

Finally, query or browse the same menu, fields, selections and seed records
under `en_US`, `es` and/or `es_CO`. The source file result and the database
result must agree.

## Required automated coverage

At minimum, multilingual addons should have these regression tests:

1. **English source test:** parse the POT and reject Spanish `msgid` values.
2. **Catalog completeness test:** compare current POT IDs against `es.po` and
   `es_CO.po`; reject missing and fuzzy entries.
3. **Runtime language test:** read representative menus, translated records and
   `fields_get()` labels with `with_context(lang=...)`.
4. **Public controller test:** assert both translated content and `<html lang>`
   for English and Spanish.
5. **Migration test:** verify legacy defaults change while customized data is
   untouched.
6. **Format test:** run `msgfmt --check --check-format` for every PO file.

Example runtime assertion:

```python
expected = {
    "en_US": ("Sign", "Customer", "Reference"),
    "es_CO": ("Firmar", "Cliente", "Referencia"),
}
for lang, (menu_name, role_name, field_name) in expected.items():
    menu = self.env.ref("my_module.menu_root").with_context(lang=lang)
    role = self.env.ref("my_module.role_customer").with_context(lang=lang)
    fields = self.env["my.model"].with_context(lang=lang).fields_get(["name"])
    self.assertEqual(menu.name, menu_name)
    self.assertEqual(role.name, role_name)
    self.assertEqual(fields["name"]["string"], field_name)
```

## `easy_sign` reference implementation

`easy_sign` is the repository example for this contract:

- Version `19.0.1.4.9` normalized Python, XML, QWeb and JavaScript sources to
  English.
- Built-in roles use `Signer 1`, `Customer` and `Employee` as source values;
  a migration preserves `Firmante 1`, `Cliente` and `Empleado` in Spanish and
  leaves custom names untouched.
- Standalone signing pages render `en-US` or `es-CO` in the HTML `lang`
  attribute from the effective signer context.
- `easy_sign.pot`, `es.po` and `es_CO.po` are current together; both Spanish
  catalogs cover all 642 extracted terms without fuzzy entries.
- `tests/test_i18n.py`, the controller language tests and migration tests guard
  the contract at source, catalog, database and HTTP levels.

Use these files as concrete examples:

- `modules/easy_sign/tests/test_i18n.py`
- `modules/easy_sign/tests/test_controllers.py`
- `modules/easy_sign/migrations/19.0.1.4.9/post-migration.py`
- `modules/easy_sign/controllers/main.py`
- `modules/easy_sign/templates/sign_page.xml`

## Final acceptance checklist

- [ ] Every runtime source string is English.
- [ ] Python user messages use literal `_()` calls; no f-strings inside `_()`.
- [ ] Backend JavaScript uses `_t()` and does not expose raw technical errors.
- [ ] XML, QWeb, mail and OWL text is extractable by Odoo.
- [ ] Standalone pages apply the effective language and declare the matching
      HTML `lang`.
- [ ] Mail, reports, public pages and generated documents use the recipient's
      effective language.
- [ ] Translatable seed fields use `translate=True`.
- [ ] Changed `noupdate` records have a safe, idempotent migration.
- [ ] POT contains no non-English runtime source terms.
- [ ] `es.po` and `es_CO.po` have no missing, fuzzy or malformed entries.
- [ ] Placeholders and HTML/QWeb structure match between `msgid` and `msgstr`.
- [ ] Corrected catalogs were imported with overwrite when the database had
      stale values.
- [ ] Runtime assertions pass for English and Spanish.
- [ ] The module update, syntax checks and focused tests pass.
