# Impocoma Odoo Translation (i18n) Guide

How to make a module translatable the Odoo way, and how to add a language.
Written from real work on the `easy_sign` module — including the mistakes.

## Golden rules

1. **Source language is English.** Write all literals in English in the code.
   Other languages are *translations*, never the source. Odoo tooling, OCA and
   the community all assume English source.
2. **Never hand-write a `.po` file.** Odoo's PO reader requires per-entry
   `#. module:` and `#:` reference comments. A hand-made file without them
   crashes the web client (`AttributeError: 'NoneType' object has no attribute
   'groups'` on `/web/webclient/translations`). Always generate it with the
   export.
3. **Translatable terms must be literal in the source.** The extractor reads the
   source; a string built from variables is not extracted.

## What is translatable automatically (no `_()` needed)

These are extracted by Odoo just by existing:

- **Model field labels, help, selection labels, `_description`.**
- **View text and attributes** (`string=`, `confirm=`, `placeholder=`,
  `help=`, menu `name`, action `name`/`help`, group/page strings).
- **QWeb template text nodes** (`<p>Text</p>`), including standalone pages.
- **Mail template `subject` and `body_html`** (both are `translate=True`).
  `body_html` is extracted per text node; `subject` is extracted as one term.
- **Group / record-rule / cron `name` fields.**

```python
# All of these become translatable terms automatically:
name = fields.Char(string="Reference")
state = fields.Selection([("draft", "Draft"), ("sent", "Sent")], string="Status")
expiry_date = fields.Date(help="The signing link will stop working after this date.")
_description = "Electronic Signature Request"
```

## What needs `_()` — Python user-facing strings

Only strings the user sees that you write in **Python** need wrapping in `_()`
(`from odoo import _`). Logs and technical strings do **not**.

```python
from odoo import _

raise UserError(_("Upload a PDF document before sending."))
self.message_post(body=_("The request has been cancelled."))
```

### `_()` rules (these break translation silently if ignored)

- **The first argument must be a literal**, never a variable.
  `_(var)` is NOT extracted. `_("Page %s", n)` is.
- **Never put an f-string inside `_()`.** Use placeholders:

```python
# WRONG — not translatable, and the value is baked into the source term:
raise UserError(f"Page {n} is invalid.")
raise UserError(_(f"Page {n} is invalid."))

# RIGHT — positional or named placeholders:
raise UserError(_("Page %s is invalid.", n))
raise UserError(_("%(name)s declined. Reason: %(reason)s", name=n, reason=r))
```

- **Do not concatenate translated strings** (`_("A") + " " + _("B")`); each
  language orders words differently. Use one term with placeholders.
- For a specific language (e.g. an email in the recipient's language), evaluate
  `_()` under that language's context:

```python
self = self.with_context(lang=self.user_id.lang)
subject = _("[SIGN] Please sign: %s", doc_name)  # `_` reads the context lang
```

## Mail templates — two gotchas

- **Subjects built inside `{{ }}` are NOT extracted.** `{{ 'Please sign: ' +
  object.name }}` keeps the literal inside an expression, so the extractor can't
  see it. Either keep the subject a plain literal, or **build it in Python with
  `_()`** and pass it via `email_values={"subject": ...}`.
- **Send each email in the recipient's language** with the template `lang` field:

```xml
<field name="subject">Please sign</field>            <!-- plain, translatable -->
<field name="lang">{{ object.partner_id.lang }}</field>
```

## Public / standalone QWeb pages

A page rendered with `request.render(...)` (no `web.layout`) is only translated
if you render it in the right language. Set the context before rendering:

```python
def sign_view(self, token, **kw):
    item = ...
    if item.request_id.user_id.lang:
        request.update_context(lang=item.request_id.user_id.lang)
    return request.render("module.template", {...})
```

## JavaScript strings

The canonical way is `_t` from `@web/core/l10n/translation`. But standalone
pages do not load the web asset bundle. The portable pattern: render the strings
server-side (already translated by QWeb) into hidden elements, and read them in
JS.

```xml
<div id="i18n" style="display:none">
    <span data-key="sent">Code sent. Check your email.</span>
</div>
```
```javascript
var I18N = {};
document.querySelectorAll('#i18n [data-key]').forEach(function (el) {
    I18N[el.getAttribute('data-key')] = el.textContent.trim();
});
// use I18N.sent
```

## The `i18n/` folder

```text
i18n/
  <module>.pot     # template: all source terms, empty translations (optional but standard)
  es.po            # Spanish translation
  en.po            # only if source is NOT English
```

A `.po` entry looks like this (note the required `#.`/`#:` lines that only the
export produces correctly):

```po
#. module: easy_sign
#: model:ir.model.fields,field_description:easy_sign.field_sign_request__name
msgid "Reference"
msgstr "Referencia"

#. module: easy_sign
#. odoo-python
#: code:addons/easy_sign/models/sign_request.py:0
msgid "[SIGN] Please sign: %s"
msgstr "[FIRMA] Por favor firma: %s"
```

`.po` files in `i18n/` load automatically — no manifest entry needed.

## How to add a language (step by step)

1. **Make sure the source is English** and all Python strings use `_()`.
2. **Reload the module** so terms are registered:
   `odoo -u <module> -d <db> --stop-after-init`.
3. **Activate the target language**: Settings → Translations → Languages
   (developer mode on).
4. **Export the template**: Settings → Translations → Export → Language: target,
   Format: **PO**, Module: yours → download the `.po`. It comes with correct
   `msgid` + reference comments and empty `msgstr`.
5. **Fill the `msgstr`** (keep `%s` / `%(x)s` counts identical to the `msgid`).
   Leave inherited `mail.thread`/base fields empty — Odoo translates those from
   its own base `.po`.
6. **Validate**: `msgfmt --check i18n/es.po -o /dev/null` (no errors).
7. Place as `i18n/<lang>.po`, `-u <module>`, test with a user in that language.

## Validation checklist

- [ ] All Python user strings wrapped in `_()`, no f-strings inside `_()`.
- [ ] No translated-string concatenation.
- [ ] No Spanish/source-language leftovers (grep accents AND accent-less words
      like `de`, `y`, `Firmados`).
- [ ] Mail subjects translatable (literal or Python `_()`), template `lang` set.
- [ ] Standalone pages render under the right `lang` context.
- [ ] `.po` generated by **export**, never by hand; `msgfmt --check` passes.
- [ ] `%s` / `%(name)s` placeholder counts match between `msgid` and `msgstr`.
