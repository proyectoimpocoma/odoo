/** @odoo-module **/

import { registry } from "@web/core/registry";
import { Component, useState, onWillStart } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";

class MainDashboard extends Component {

    setup() {

        this.menuService = useService("menu");

        this.state = useState({
            apps: [],
        });

        onWillStart(async () => {

            const apps = this.menuService.getApps() || [];

            this.state.apps = apps.filter(
                app =>
                    app.xmlid &&
                    app.xmlid !==
                    "theme_impocoma.menu_main_dashboard"
            );
        });
    }
}

MainDashboard.template =
    "theme_impocoma.MainDashboard";

registry.category("actions").add(
    "theme_impocoma.main_dashboard",
    MainDashboard
);
