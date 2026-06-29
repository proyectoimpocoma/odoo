# Impocoma Theme Usage

Use `theme_impocoma` as the visual source of truth.

## Dependency

Business modules with custom UI should depend on `theme_impocoma`:

```python
"depends": ["base", "mail", "web", "theme_impocoma"]
```

## SCSS

Prefer SCSS for new module styles so theme variables can be reused.

Use variables from `modules/theme_impocoma/static/src/scss/primary_variables.scss`:

```scss
$imp-primary
$imp-primary-dark
$imp-secondary
$imp-ink
$imp-muted
$imp-line
$imp-soft
$imp-surface
$imp-danger
$imp-success
```

Do not hardcode the Impocoma orange, blue, text, line, or soft background colors in new modules.

## Boundaries

- Do not force global navbar colors from business modules.
- Do not duplicate login, website layout, or app dashboard behavior.
- Keep operational screens dense, clean, and scannable.
- Use direct button labels such as `Crear`, `Guardar`, `Enviar`, `Aprobar`, and `Rechazar`.
- For public portal text, prefer `Habilitacion Terceros` over internal risk wording when the audience is an end user.

## Asset Bundles

- Backend UI styles: `web.assets_backend`.
- Public website or portal styles: `web.assets_frontend`.
- Global Odoo theme variables belong only in `theme_impocoma` under `web._assets_primary_variables`.
