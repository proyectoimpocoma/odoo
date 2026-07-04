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

## Module Icons

- Para iconos de módulos, usa la misma paleta de `primary_variables.scss`.
- No generes iconos con fondo blanco o tarjeta interna: el PNG final debe tener
  alfa real y esquinas transparentes.
- El icono debe quedar grande dentro del canvas; recorta el espacio vacío antes
  de guardarlo como `static/description/icon.png`.
- Consulta `docs/ai/module_icons.md` para formato, `web_icon` y validación.

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

## Trampas Técnicas del Tema

Reglas operativas que rompen assets o vistas si se ignoran. Mantenlas
localizadas; los anti-patrones generales viven en `anti_patterns.md`.

- **Sass `min()` / `max()` con unidades mixtas** (`px` con `vw` o `%`) rompe
  la compilación. Usar `width` + `max-width` separados.
- **Heredar vistas QWeb**: no depender de `hasclass()` cuando la clase viene
  de un `t-attf-class`. Usar atributos estáticos cuando existan en la vista
  base.
- **No forzar el color del navbar** desde un módulo de negocio. Lo gobierna
  `$o-navbar-background` del tema. Si necesitas color de marca en otro
  elemento, usa las variables `$imp-*`.
- **Cargar el JS del dashboard** en `web.assets_frontend` no se ve. El
  `app_dashboard.js` y el `navbar_patch.js` deben ir en
  `web.assets_backend`; sus plantillas QWeb/OWL en
  `static/src/xml/...` también.
- **Heredar `primary_variables.scss`** solo si necesitas extender variables
  globales. Para estilos de módulo nuevo, crea un SCSS propio en
  `static/src/scss/` y registra el asset en el manifest.
