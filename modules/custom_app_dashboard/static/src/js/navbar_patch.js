/** @odoo-module **/

import { patch } from "@web/core/utils/patch";
import { NavBar } from "@web/webclient/navbar/navbar";

patch(NavBar.prototype, {
    setup() {
        super.setup();

        const root =
            this.menuService.getMenuAsTree("root")?.childrenTree || [];

        this.dashboardMenu = root.find(
            (app) =>
                app.xmlid ===
                "custom_app_dashboard.menu_main_dashboard"
        );
    },

    onClickDashboard(ev) {
        ev.preventDefault();
        ev.stopPropagation();

        if (
            this.dashboardMenu &&
            typeof this._onMenuClicked === "function"
        ) {
            this._onMenuClicked(this.dashboardMenu);
        }
    },
});