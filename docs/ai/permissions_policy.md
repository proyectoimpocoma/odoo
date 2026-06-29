# Impocoma Odoo Permissions Policy

Apply this policy to production modules.

## Groups

Always create explicit recommended module groups in `security/groups.xml` for production modules. Do not rely only on `base.group_user` or ad hoc access rules.

Recommended pattern:

```xml
<record id="module_category_addon" model="ir.module.category">
    <field name="name">Human Category</field>
    <field name="sequence">60</field>
</record>

<record id="res_groups_privilege_addon" model="res.groups.privilege">
    <field name="name">Human Category</field>
    <field name="category_id" ref="module_category_addon"/>
    <field name="sequence">60</field>
</record>

<record id="group_addon_user" model="res.groups">
    <field name="name">Addon User</field>
    <field name="privilege_id" ref="res_groups_privilege_addon"/>
    <field name="sequence">10</field>
    <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
</record>

<record id="group_addon_manager" model="res.groups">
    <field name="name">Addon Manager</field>
    <field name="privilege_id" ref="res_groups_privilege_addon"/>
    <field name="sequence">20</field>
    <field name="implied_ids" eval="[(4, ref('addon_name.group_addon_user'))]"/>
</record>
```

## Access CSV Defaults

- Give users the minimum required permissions.
- Give managers create/write when the workflow needs it.
- Keep `perm_unlink=0` by default for business records, requests, documents, logs, and sensitive data.
- Use `base.group_system` only for technical settings, credentials, integrations, and destructive admin operations.

Example:

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_addon_record_user,addon.record.user,model_addon_record,addon_name.group_addon_user,1,1,1,0
access_addon_record_manager,addon.record.manager,model_addon_record,addon_name.group_addon_manager,1,1,1,0
```

## Sensitive Data

Protect cedulas, phones, emails, documents, banking data, GPS credentials, Microsoft Graph secrets, SharePoint configuration, legal authorizations, and audit history.

When routes use `sudo()`, first prove ownership or access through explicit checks before reading or writing records.
