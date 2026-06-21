{
    'name': 'App Dashboard for Odoo Community',
    'version': '19.0.1.0.0',
    'license': 'LGPL-3',
    'category': 'Tools',
    'summary': 'Modern App Dashboard for Odoo Community',
    'description': 'Enterprise-style App Dashboard for Odoo Community Edition.',
    'author': 'GTMTechsol',
    'maintainer': 'GTMTechsol',
    'website': 'https://gtmtechsol.com',
    'images': ['static/description/banner.png'],
    'depends': ['web'],
    'data': [
        'views/dashboard_views.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'custom_app_dashboard/static/src/js/app_dashboard.js',
            'custom_app_dashboard/static/src/js/navbar_patch.js',
            'custom_app_dashboard/static/src/xml/navbar_patch.xml',
            'custom_app_dashboard/static/src/xml/app_dashboard.xml',
            'custom_app_dashboard/static/src/scss/app_dashboard.scss',
        ],
    },
    'installable': True,
    'application': True,
    'auto_install': False,
}
