{
    "name": "Addon Name",
    "version": "19.0.1.0.0",
    "category": "Impocoma",
    "author": "Impocoma",
    "website": "https://www.impocoma.com",
    "summary": "Short business summary",
    "depends": ["base", "mail", "web", "theme_impocoma"],
    "data": [
        "security/groups.xml",
        "security/ir.model.access.csv",
        "views/backend/record_views.xml",
        "views/backend/record_menus.xml",
    ],
    "assets": {
        "web.assets_backend": [
            "addon_name/static/src/scss/record.scss",
        ],
    },
    "installable": True,
    "application": True,
    "license": "LGPL-3",
}
