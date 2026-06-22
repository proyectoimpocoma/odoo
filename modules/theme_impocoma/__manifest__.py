{
    "name": "Impocoma Theme",
    "version": "19.0.1.0.0",
    "category": "Theme",
    "author": "Angel",
    "website": "https://www.impocoma.com",
    "summary": "Identidad visual de Impocoma para backend, portal y website",
    "description": """
Tema corporativo Impocoma
=========================

Centraliza la paleta de marca de Impocoma y la aplica al backend, login,
portal y website.

Paleta:
    - Primario:   #f77c00 (naranja)
    - Secundario: #003b73 (azul marino)
    - Texto:      #121c2c
""",
    "depends": ["web", "website"],
    "data": [
        "views/website_layout_templates.xml",
        "views/login_templates.xml",
        "views/dashboard_views.xml",
    ],
    "assets": {
        # Las variables primarias deben cargarse en este bundle especial
        # para que el resto de SCSS de Odoo las pueda usar al compilar.
        "web._assets_primary_variables": [
            "theme_impocoma/static/src/scss/primary_variables.scss",
        ],
        # La pantalla de login usa el layout de frontend.
        "web.assets_frontend": [
            "theme_impocoma/static/src/scss/login.scss",
            "theme_impocoma/static/src/scss/website_layout.scss",
        ],
        # App Dashboard (antes módulo custom_app_dashboard, ahora integrado).
        "web.assets_backend": [
            "theme_impocoma/static/src/js/app_dashboard.js",
            "theme_impocoma/static/src/js/navbar_patch.js",
            "theme_impocoma/static/src/xml/navbar_patch.xml",
            "theme_impocoma/static/src/xml/app_dashboard.xml",
            "theme_impocoma/static/src/scss/app_dashboard.scss",
        ],
    },
    "post_init_hook": "post_init_hook",
    "installable": True,
    "application": False,
    "auto_install": False,
    "license": "LGPL-3",
}
