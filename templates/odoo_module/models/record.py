from odoo import fields, models


class AddonRecord(models.Model):
    _name = "addon.record"
    _description = "Addon Record"
    _inherit = ["mail.thread", "mail.activity.mixin"]
    _rec_name = "name"

    name = fields.Char(required=True, tracking=True)
    active = fields.Boolean(default=True)
    state = fields.Selection(
        [
            ("draft", "Draft"),
            ("active", "Active"),
            ("done", "Done"),
        ],
        default="draft",
        required=True,
        tracking=True,
    )
