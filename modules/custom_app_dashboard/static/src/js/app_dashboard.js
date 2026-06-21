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
                    "custom_app_dashboard.menu_main_dashboard"
            );
        });
    }
}

MainDashboard.template =
    "custom_app_dashboard.MainDashboard";

registry.category("actions").add(
    "custom_app_dashboard.main_dashboard",
    MainDashboard
);

