// Palace Thermal Deck — config model (top-level)
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Thresholds")
        icon: "preferences-system-power-management"
        source: "config/Thresholds.qml"
    }
}
