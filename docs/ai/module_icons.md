# Impocoma Odoo Module Icons

Guía para crear, reemplazar y validar iconos de módulos Odoo en este repo.
Úsala cuando el usuario pida crear un icono, cambiar un icono existente o
diagnosticar por qué no aparece en el launcher de Odoo.

## Fuente Visual

- Usa `modules/theme_impocoma` como fuente de identidad visual.
- Antes de generar o editar el icono, revisa la paleta real en
  `modules/theme_impocoma/static/src/scss/primary_variables.scss`.
- Paleta actual del tema:
  - Naranja primario: `#f77c00`.
  - Azul marino: `#003b73`.
  - Texto/tinta: `#121c2c`.
  - Blanco: `#ffffff`.
  - Fondo suave: `#f5f7fa`.
  - Línea suave: `#cbd5e0`.
- No inventes una paleta "parecida" si el repo tiene variables de marca.
- El icono debe comunicar el dominio del módulo en un golpe de vista; evita
  ilustraciones genéricas o demasiado decorativas.

## Formato Requerido

El icono principal del módulo debe vivir en:

```text
modules/<addon_name>/static/description/icon.png
```

Requisitos:

- PNG cuadrado.
- `200 x 200` px para el archivo final de Odoo.
- Canal alfa real (`RGBA`) y esquinas transparentes.
- Sin fondo blanco, tarjeta, marco, círculo o contenedor decorativo horneado
  dentro de la imagen.
- Contenido grande: recortar al objeto principal y dejar solo un margen pequeño.
  Como referencia, el `alpha_bbox` debe ocupar la mayor parte del canvas.
- Bordes nítidos al tamaño final; generar grande primero y reducir con buen
  resampling si hace falta.
- Sin texto legible dentro del icono. Etiquetas, códigos o barcodes pueden
  aparecer como detalle visual, pero no deben depender de lectura.

## Relación Con Odoo

Hay dos lugares distintos que suelen confundirse:

- `static/description/icon.png`: icono del módulo y fuente recomendada para el
  launcher.
- `images` en `__manifest__.py`: screenshots, GIFs o material de descripción;
  no reemplaza el icono del launcher.

Para que el icono aparezca en el launcher/app menu de Odoo, el menú raíz debe
tener `web_icon`:

```xml
<menuitem
    id="menu_addon_root"
    name="Addon Name"
    web_icon="addon_name,static/description/icon.png"/>
```

Después de cambiar `web_icon` o `icon.png`, actualiza el módulo:

```bash
./scripts/docker.sh update addon_name
```

## Verificación Obligatoria

Verifica el archivo local:

```bash
sips -g pixelWidth -g pixelHeight -g hasAlpha modules/addon_name/static/description/icon.png
```

Verifica que Odoo sirva el asset:

```bash
curl -I http://localhost:8069/addon_name/static/description/icon.png
```

Verifica que el menú raíz tenga el icono cargado:

```bash
docker compose exec -T odoo odoo shell -c /etc/odoo/odoo.conf -d mi_empresa --no-http <<'PY'
menu = env.ref("addon_name.menu_addon_root", raise_if_not_found=False)
print(menu and {
    "web_icon": menu.web_icon,
    "web_icon_data": bool(menu.web_icon_data),
})
PY
```

Si el archivo y la base están bien pero el navegador no cambia, probar recarga
fuerte (`Cmd+Shift+R` en macOS) porque Odoo y el navegador cachean iconos.

## Checklist Antes De Cerrar

- [ ] Se revisó la paleta real de `theme_impocoma`.
- [ ] `static/description/icon.png` existe.
- [ ] El PNG final es `200 x 200`.
- [ ] Tiene alfa (`RGBA`) y esquinas transparentes.
- [ ] No tiene fondo, marco ni tarjeta dentro del bitmap.
- [ ] El objeto principal ocupa casi todo el canvas.
- [ ] El menú raíz tiene `web_icon="addon_name,static/description/icon.png"`.
- [ ] El módulo fue actualizado con `-u addon_name`.
- [ ] `web_icon_data` quedó poblado en `ir.ui.menu`.
- [ ] Se informó al usuario si necesita recarga fuerte por cache.
