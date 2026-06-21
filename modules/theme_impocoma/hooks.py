def post_init_hook(env):
    """Apply the Impocoma theme to the available websites after installation."""
    theme = env["ir.module.module"].sudo().search([("name", "=", "theme_impocoma")], limit=1)
    if not theme:
        return

    Website = env["website"].sudo()
    websites = Website.search([])
    if not websites:
        websites = Website.create({
            "name": "Impocoma",
            "theme_id": theme.id,
        })

    theme_loader = theme.with_context(apply_new_theme=True)._theme_get_stream_themes()
    for website in websites:
        theme_loader._theme_load(website)
        website.write({"theme_id": theme.id})
