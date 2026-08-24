// Palace Thermal Deck — Thresholds config page
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: root

    // ---- KCFG contract ----
    // The Plasma 6 config loader instantiates this root Item with the kcfg
    // schema (contents/config/main.xml) and tries to set initial properties
    // named `cfg_<entryName>` and `cfg_<entryName>Default` on it. If they are
    // not declared here the loader logs
    //     "Setting initial properties failed: Thresholds does not have a
    //      property called cfg_loopWarnC"
    // and the page is never placed in the scene. Declaring them as plain
    // properties of the right type satisfies the contract; the values are
    // overwritten by the config system at load time and we mirror them to
    // plasmoid.configuration below.
    property string title: i18n("Thresholds")
    property real cfg_loopWarnC:        35
    property real cfg_loopWarnCDefault: 35
    property real cfg_loopAlertC:       40
    property real cfg_loopAlertCDefault: 40
    property real cfg_cpuWarnC:         75
    property real cfg_cpuWarnCDefault:  75
    property real cfg_cpuAlertC:        90
    property real cfg_cpuAlertCDefault: 90
    property real cfg_gpuWarnC:         75
    property real cfg_gpuWarnCDefault:  75
    property real cfg_gpuAlertC:        90
    property real cfg_gpuAlertCDefault: 90
    property int  cfg_pumpLowRpm:       2500
    property int  cfg_pumpLowRpmDefault: 2500

    // Read current values from plasmoid.configuration, falling back to the
    // hard-coded defaults above if the configuration object is empty (fresh
    // install / pre-migration). The cfg_* properties are kept in sync with
    // plasmoid.configuration through the KCM contract; the SpinBox UI binds
    // to these local properties so changes round-trip on Apply.
    property real loopWarnC:  plasmoid.configuration.loopWarnC  !== undefined ? plasmoid.configuration.loopWarnC  : cfg_loopWarnCDefault
    property real loopAlertC: plasmoid.configuration.loopAlertC !== undefined ? plasmoid.configuration.loopAlertC : cfg_loopAlertCDefault
    property real cpuWarnC:   plasmoid.configuration.cpuWarnC   !== undefined ? plasmoid.configuration.cpuWarnC   : cfg_cpuWarnCDefault
    property real cpuAlertC:  plasmoid.configuration.cpuAlertC  !== undefined ? plasmoid.configuration.cpuAlertC  : cfg_cpuAlertCDefault
    property real gpuWarnC:   plasmoid.configuration.gpuWarnC   !== undefined ? plasmoid.configuration.gpuWarnC   : cfg_gpuWarnCDefault
    property real gpuAlertC:  plasmoid.configuration.gpuAlertC  !== undefined ? plasmoid.configuration.gpuAlertC  : cfg_gpuAlertCDefault
    property int  pumpLowRpm: plasmoid.configuration.pumpLowRpm !== undefined ? plasmoid.configuration.pumpLowRpm : cfg_pumpLowRpmDefault

    function commit() {
        plasmoid.configuration.loopWarnC  = loopWarnC;
        plasmoid.configuration.loopAlertC = loopAlertC;
        plasmoid.configuration.cpuWarnC   = cpuWarnC;
        plasmoid.configuration.cpuAlertC  = cpuAlertC;
        plasmoid.configuration.gpuWarnC   = gpuWarnC;
        plasmoid.configuration.gpuAlertC  = gpuAlertC;
        plasmoid.configuration.pumpLowRpm = pumpLowRpm;
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing

        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            // Helper local component for a labeled SpinBox row
            Component {
                id: labeledSpin
                RowLayout {
                    property alias label: caption.text
                    property alias spin: sb
                    property int  spinFrom: 0
                    property int  spinTo: 100
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    Label {
                        id: caption
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        elide: Text.ElideRight
                    }
                    SpinBox {
                        id: sb
                        from: spinFrom; to: spinTo
                        editable: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    }
                }
            }

            Label {
                text: i18n("Loop temperature (°C)")
                font.bold: true
                Layout.fillWidth: true
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: labeledSpin
                onLoaded: { item.label = i18n("Warn ≥"); item.spinFrom = 0; item.spinTo = 100; item.spin.value = root.loopWarnC; item.spin.onValueModified.connect(function(){ root.loopWarnC = item.spin.value; root.commit(); }); }
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: labeledSpin
                onLoaded: { item.label = i18n("Alert ≥"); item.spinFrom = 0; item.spinTo = 100; item.spin.value = root.loopAlertC; item.spin.onValueModified.connect(function(){ root.loopAlertC = item.spin.value; root.commit(); }); }
            }

            Label {
                text: i18n("CPU temperature (°C)")
                font.bold: true
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: labeledSpin
                onLoaded: { item.label = i18n("Warn ≥"); item.spinFrom = 0; item.spinTo = 120; item.spin.value = root.cpuWarnC; item.spin.onValueModified.connect(function(){ root.cpuWarnC = item.spin.value; root.commit(); }); }
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: labeledSpin
                onLoaded: { item.label = i18n("Alert ≥"); item.spinFrom = 0; item.spinTo = 120; item.spin.value = root.cpuAlertC; item.spin.onValueModified.connect(function(){ root.cpuAlertC = item.spin.value; root.commit(); }); }
            }

            Label {
                text: i18n("GPU temperature (°C)")
                font.bold: true
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: labeledSpin
                onLoaded: { item.label = i18n("Warn ≥"); item.spinFrom = 0; item.spinTo = 120; item.spin.value = root.gpuWarnC; item.spin.onValueModified.connect(function(){ root.gpuWarnC = item.spin.value; root.commit(); }); }
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: labeledSpin
                onLoaded: { item.label = i18n("Alert ≥"); item.spinFrom = 0; item.spinTo = 120; item.spin.value = root.gpuAlertC; item.spin.onValueModified.connect(function(){ root.gpuAlertC = item.spin.value; root.commit(); }); }
            }

            Label {
                text: i18n("Loop pump low-RPM alert")
                font.bold: true
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: labeledSpin
                onLoaded: { item.label = i18n("Alert if < (RPM)"); item.spinFrom = 0; item.spinTo = 10000; item.spin.value = root.pumpLowRpm; item.spin.onValueModified.connect(function(){ root.pumpLowRpm = item.spin.value; root.commit(); }); }
            }
        }
    }
}
