# Impocoma Odoo Module Blueprint

Use this blueprint before creating or extending modules in this repository.

## Location And Naming

- Create addons under `modules/`.
- Use lowercase `snake_case` addon names without hyphens.
- Use dotted business model names, for example `fleet.onboarding.request`.
- Do not rename an existing model `_name` without a migration plan.
- When creating Odoo models, always set a clear `_description` that identifies the business object and module context. Audit log entries use model descriptions, so avoid generic labels like `Record`, `Request`, or `Line`.

Example:

```python
class FleetOnboardingRequest(models.Model):
    _name = "fleet.onboarding.request"
    _description = "Fleet Onboarding Request"
```

## Default Structure

Start backend modules from `templates/odoo_module/`.

Use these folders only when they are needed:

```text
controllers/        website or HTTP routes
models/             ORM fields, constraints, workflows, business methods
security/           groups and access CSV
views/backend/      internal Odoo views, actions, menus, search views
views/website/      public website or portal QWeb templates
views/wizards/      transient model views
static/src/scss/    module SCSS that can reuse theme variables
static/src/js/      browser behavior only when needed
tests/              focused module tests
migrations/         versioned migration scripts
```

## Manifest Defaults

Use `category: "Impocoma"` and `license: "LGPL-3"`.

Default depends for business backend modules:

```python
["base", "mail", "web", "theme_impocoma"]
```

Add only when required:

- `website`: public website pages or forms.
- `portal`: portal pages for authenticated external users.
- `auth_signup`: signup or account invitation flows.

Load files in this order:

1. base data and configuration
2. `security/groups.xml`
3. `security/ir.model.access.csv`
4. backend views, actions, menus
5. wizards
6. website or portal templates

If a menu references an action, load the action before the menu.

## Website Forms

For public or multi-step forms:

- Use `auth="public"`, `website=True`, and `csrf=True` for POST routes unless there is a concrete reason not to.
- Store drafts in `request.session`.
- Keep an explicit allowlist of fields by step.
- Validate server-side even when JavaScript validation exists.
- Use `sudo()` only for the final write and only with allowlisted fields.
- Clear the session after successful submission.

## Size And Split Rules

- Keep model files focused by responsibility.
- Prefer a separate `_inherit = "model.name"` file for workflow, formatting, external sync, or document logic when a model grows.
- Move reusable controller form schemas, session helpers, mappers, and validators out of large route files.
- Avoid inline CSS or JavaScript inside XML except for tiny prototypes.
