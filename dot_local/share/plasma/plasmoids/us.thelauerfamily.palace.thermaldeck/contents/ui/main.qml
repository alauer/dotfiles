// Palace Thermal Deck — Plasma 6 applet (us.thelauerfamily.palace.thermaldeck)
// SPDX-License-Identifier: GPL-2.0-or-later
//
// Single-file applet: sensor bindings, formatted values, health rollup,
// missing-sensor graceful degradation, no animation noise.
//
// Hierarchy:
//   header (title + HEALTHY/WARN/ALERT pill)
//   LOOP  (large central temp)
//   CPU TEMP / GPU TEMP
//   CPU%  GPU%  RAM  VRAM  (usage rows w/ thin bars)
//   RAD FANS  LOOP PUMP  (RPM rows)

import QtQuick
import QtQuick.Layouts
import QtQml

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.formatter as Formatter
// (config values read via Plasmoid.configuration — see ConfigGroup removal note below)

PlasmoidItem {
    id: root

    // ---- Layout sizing: vertical card tuned for 3440x1440 upper-right ----
    Layout.minimumWidth: 240
    Layout.minimumHeight: 380
    Layout.preferredWidth: 260
    Layout.preferredHeight: 430
    Layout.maximumWidth: 320
    Layout.maximumHeight: 540

    // No animation noise.
    Behavior on x { NumberAnimation { duration: 0 } }
    Behavior on y { NumberAnimation { duration: 0 } }

    // ---- Config: thresholds from plasmoid config (Plasma 6 canonical pattern) ----
    // Values are read from Plasmoid.configuration.<key> with `!== undefined`
    // guards so unset / pre-migration configs fall back to the spec defaults.
    // (This replaces the legacy KF5 `ConfigGroup { cfg.readConfigValue(...) }`
    // pattern, which is not a type in Plasma 6.)

    property real loopWarnC: Plasmoid.configuration.loopWarnC !== undefined ? Plasmoid.configuration.loopWarnC : 35
    property real loopAlertC: Plasmoid.configuration.loopAlertC !== undefined ? Plasmoid.configuration.loopAlertC : 40
    property real cpuWarnC: Plasmoid.configuration.cpuWarnC !== undefined ? Plasmoid.configuration.cpuWarnC : 75
    property real cpuAlertC: Plasmoid.configuration.cpuAlertC !== undefined ? Plasmoid.configuration.cpuAlertC : 90
    property real gpuWarnC: Plasmoid.configuration.gpuWarnC !== undefined ? Plasmoid.configuration.gpuWarnC : 75
    property real gpuAlertC: Plasmoid.configuration.gpuAlertC !== undefined ? Plasmoid.configuration.gpuAlertC : 90
    property int  pumpLowRpm: Plasmoid.configuration.pumpLowRpm !== undefined ? Plasmoid.configuration.pumpLowRpm : 2500

    // ---- Font: monospace family for tabular numerals (system-installed) ----
    property string monoFamily: {
        const families = Qt.fontFamilies();
        const candidates = [
            "Hack", "DejaVu Sans Mono", "Liberation Mono",
            "Noto Sans Mono", "JetBrains Mono", "Ubuntu Mono",
            "Consolas", "Menlo", "monospace"
        ];
        for (let i = 0; i < candidates.length; ++i) {
            if (families.indexOf(candidates[i]) !== -1) return candidates[i];
        }
        return "monospace";
    }

    // ---- Health rollup ----
    // Worst state wins: Unknown = 0, Healthy = 1, Warn = 2, Alert = 3.
    readonly property int stateHealthy: 1
    readonly property int stateWarn: 2
    readonly property int stateAlert: 3

    property int cpuTempState: stateHealthy
    property int gpuTempState: stateHealthy
    property int loopState: stateHealthy
    property int pumpState: stateHealthy
    property int healthState: stateHealthy

    function worstState(...states) {
        let m = stateHealthy;
        for (let i = 0; i < states.length; ++i) {
            if (states[i] > m) m = states[i];
        }
        return m;
    }

    function tempState(value, warn, alert) {
        if (!Number.isFinite(value)) return stateHealthy; // missing = don't penalise
        if (value >= alert) return stateAlert;
        if (value >= warn) return stateWarn;
        return stateHealthy;
    }

    function pumpStateFromRpm(rpm) {
        if (!Number.isFinite(rpm)) return stateHealthy;
        if (rpm < pumpLowRpm) return stateAlert; // pump failure / stalling = alert
        return stateHealthy;
    }

    onCpuTempStateChanged: healthState = worstState(cpuTempState, gpuTempState, loopState, pumpState)
    onGpuTempStateChanged: healthState = worstState(cpuTempState, gpuTempState, loopState, pumpState)
    onLoopStateChanged: healthState = worstState(cpuTempState, gpuTempState, loopState, pumpState)
    onPumpStateChanged: healthState = worstState(cpuTempState, gpuTempState, loopState, pumpState)

    // ---- Formatted helpers (em dash for missing values, fixed precision) ----
    readonly property string na: "—"

    function fmtTemp(v) {
        if (!Number.isFinite(v)) return na;
        return v.toFixed(1) + "°C";
    }

    // Big-numeric variant used for the LOOP block: value + degree sign only.
    // The unit "C" is appended as a separate, smaller label so the eye reads
    // "34.0°  C" instead of an oversized "°C" glued onto the number.
    function fmtTempBig(v) {
        if (!Number.isFinite(v)) return na;
        return v.toFixed(1) + "°";
    }

    function fmtPercent(v) {
        if (!Number.isFinite(v)) return na;
        return Math.round(v) + "%";
    }

    function fmtPercentF(v) {
        if (!Number.isFinite(v)) return na;
        return v.toFixed(0) + "%";
    }

    function fmtClockMhz(v) {
        if (!Number.isFinite(v)) return na;
        // Auto display as MHz until 1000+, then GHz.
        if (v >= 1000) return (v / 1000).toFixed(2) + " GHz";
        return Math.round(v) + " MHz";
    }

    function fmtRpm(v) {
        if (!Number.isFinite(v)) return na;
        return Math.round(v) + " RPM";
    }

    function fmtBytesGiB(used, total) {
        // Inputs are bytes (KSysGuard units: UnitByte). Convert to GiB.
        const gib = 1024 * 1024 * 1024;
        if (Number.isFinite(used) && Number.isFinite(total) && total > 0) {
            return (used / gib).toFixed(1) + " / " + (total / gib).toFixed(1) + " GiB";
        }
        if (Number.isFinite(used)) return (used / gib).toFixed(1) + " GiB";
        return na;
    }

    function colorForState(s) {
        switch (s) {
            case stateAlert: return "#ff6b3d"; // red-orange
            case stateWarn:  return "#ffd24a"; // amber
            default:         return "#6fff8b"; // acid green
        }
    }

    function colorForStateMuted(s) {
        switch (s) {
            case stateAlert: return "#b85a36";
            case stateWarn:  return "#b89836";
            default:         return "#5fb87a";
        }
    }

    // ---- Sensors ----
    Sensors.Sensor {
        id: cpuUsage
        sensorId: "cpu/all/usage"
        updateRateLimit: 1000
        onValueChanged: if (Number.isFinite(value)) {
            // No state derived from usage alone; only temps + pump drive health.
        }
    }

    Sensors.Sensor {
        id: gpuUsage
        sensorId: "gpu/gpu0/usage"
        updateRateLimit: 1000
    }

    Sensors.Sensor {
        id: ramUsed
        sensorId: "memory/physical/used"
        updateRateLimit: 2000
    }
    Sensors.Sensor {
        id: ramTotal
        sensorId: "memory/physical/total"
        updateRateLimit: 5000
    }
    Sensors.Sensor {
        id: ramPercent
        sensorId: "memory/physical/usedPercent"
        updateRateLimit: 1000
    }

    Sensors.Sensor {
        id: vramUsed
        sensorId: "gpu/gpu0/usedVram"
        updateRateLimit: 2000
    }
    Sensors.Sensor {
        id: vramTotal
        sensorId: "gpu/gpu0/totalVram"
        updateRateLimit: 5000
    }

    Sensors.Sensor {
        id: cpuTemp
        sensorId: "cpu/all/maximumTemperature"
        updateRateLimit: 1000
        onValueChanged: cpuTempState = tempState(value, root.cpuWarnC, root.cpuAlertC)
    }

    Sensors.Sensor {
        id: gpuTemp
        sensorId: "gpu/gpu0/temperature"
        updateRateLimit: 1000
        onValueChanged: gpuTempState = tempState(value, root.gpuWarnC, root.gpuAlertC)
    }

    Sensors.Sensor {
        id: loopTemp
        sensorId: "lmsensors/asusec-isa-000a/temp4"
        updateRateLimit: 1000
        onValueChanged: loopState = tempState(value, root.loopWarnC, root.loopAlertC)
    }

    Sensors.Sensor {
        id: gpuClock
        sensorId: "gpu/gpu0/coreFrequency"
        updateRateLimit: 2000
    }

    Sensors.Sensor {
        id: cpuAvgClock
        sensorId: "cpu/all/averageFrequency"
        updateRateLimit: 2000
    }

    Sensors.Sensor {
        id: radFans
        sensorId: "lmsensors/nct6798-isa-0290/fan1"
        updateRateLimit: 2000
    }

    Sensors.Sensor {
        id: loopPump
        sensorId: "lmsensors/nct6798-isa-0290/fan2"
        updateRateLimit: 2000
        onValueChanged: pumpState = pumpStateFromRpm(value)
    }

    // ---- Visual: card ----
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14
        // Translucent near-black plum (alpha leaves composite visible).
        color: Qt.rgba(0.055, 0.040, 0.078, 0.92)
        // Subtle violet border/glow.
        border.color: Qt.rgba(0.42, 0.30, 0.72, 0.45)
        border.width: 1
        // Soft outer glow via layered shadow rect.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: parent.radius + 3
            color: "transparent"
            border.color: Qt.rgba(0.55, 0.30, 0.95, 0.18)
            border.width: 3
            z: -1
        }

        ColumnLayout {
            id: stack
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ---- Header: two-tier (title row above, pill row below) ----
            // Single-row layout truncated the title at 260 px; giving the
            // title the full row width keeps "PALACE THERMAL DECK" intact.
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "PALACE THERMAL DECK"
                    color: "#c8b5e8"
                    font.family: root.monoFamily
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideNone
                }

                Rectangle {
                    id: healthPill
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: healthPillLabel.implicitWidth + 16
                    radius: 9
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.color: root.colorForState(root.healthState)
                    border.width: 1
                    Layout.alignment: Qt.AlignRight

                    Text {
                        id: healthPillLabel
                        anchors.centerIn: parent
                        text: {
                            switch (root.healthState) {
                                case root.stateAlert: return "ALERT";
                                case root.stateWarn:  return "WARN";
                                default:              return "HEALTHY";
                            }
                        }
                        color: root.colorForState(root.healthState)
                        font.family: root.monoFamily
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                }
            }

            // Thin separator
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(0.42, 0.30, 0.72, 0.18) }

            // ---- LOOP section ----
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 88

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        text: "LOOP"
                        color: "#8a7daa"
                        font.family: root.monoFamily
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        spacing: 4

                        // Big numeric value (degree sign only — full °C unit is
                        // carried by the smaller "C" label that follows).
                        Text {
                            text: root.fmtTempBig(loopTemp.value)
                            color: root.healthState === root.stateAlert ? "#ff6b3d"
                                 : root.healthState === root.stateWarn  ? "#ffd24a"
                                 : "#f3eaff"
                            font.family: root.monoFamily
                            font.pixelSize: 52
                            font.bold: true
                            font.kerning: false
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            text: "C"
                            color: "#8a7daa"
                            font.family: root.monoFamily
                            font.pixelSize: 14
                            font.bold: true
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 12
                        }
                    }
                    Text {
                        text: "warn ≥ " + root.loopWarnC.toFixed(0) + "°  alert ≥ " + root.loopAlertC.toFixed(0) + "°"
                        color: Qt.rgba(0.55, 0.45, 0.78, 0.55)
                        font.family: root.monoFamily
                        font.pixelSize: 9
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // ---- CPU/GPU temps row ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "CPU TEMP"; color: "#8a7daa"; font.family: root.monoFamily; font.pixelSize: 9; font.letterSpacing: 1.0; font.bold: true }
                    Text {
                        text: root.fmtTemp(cpuTemp.value)
                        color: root.cpuTempState === root.stateAlert ? "#ff5fb0"
                             : root.cpuTempState === root.stateWarn  ? "#ffd24a"
                             : "#ff8fcb"
                        font.family: root.monoFamily; font.pixelSize: 18; font.bold: true; font.kerning: false
                    }
                }
                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Qt.rgba(0.42, 0.30, 0.72, 0.18) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "GPU TEMP"; color: "#8a7daa"; font.family: root.monoFamily; font.pixelSize: 9; font.letterSpacing: 1.0; font.bold: true }
                    Text {
                        text: root.fmtTemp(gpuTemp.value)
                        color: root.gpuTempState === root.stateAlert ? "#ff6b3d"
                             : root.gpuTempState === root.stateWarn  ? "#ffd24a"
                             : "#5fd6ff"
                        font.family: root.monoFamily; font.pixelSize: 18; font.bold: true; font.kerning: false
                    }
                }
            }

            // Thin separator
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(0.42, 0.30, 0.72, 0.18) }

            // ---- Usage rows: CPU / GPU / RAM / VRAM ----
            Component {
                id: usageRow
                ColumnLayout {
                    property string rowLabel: ""
                    property string rowValue: ""
                    property real   rowPercent: NaN
                    property color  rowBarColor: "#5fd6ff"
                    property color  rowBarTrack: Qt.rgba(0.20, 0.16, 0.30, 0.55)
                    property string rowSub: ""

                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: rowLabel
                            color: "#8a7daa"
                            font.family: root.monoFamily; font.pixelSize: 9; font.letterSpacing: 1.0; font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: rowSub
                            color: Qt.rgba(0.78, 0.70, 0.95, 0.50)
                            font.family: root.monoFamily; font.pixelSize: 9
                        }
                        Text {
                            text: rowValue
                            color: rowBarColor
                            font.family: root.monoFamily; font.pixelSize: 12; font.bold: true; font.kerning: false
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        radius: 1.5
                        color: rowBarTrack
                        Rectangle {
                            height: parent.height
                            width: {
                                if (!Number.isFinite(rowPercent)) return 0;
                                const p = Math.max(0, Math.min(100, rowPercent));
                                return parent.width * (p / 100);
                            }
                            radius: parent.radius
                            color: rowBarColor
                            opacity: 0.85
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                sourceComponent: usageRow
                onLoaded: {
                    item.rowLabel = "CPU";
                    item.rowBarColor = "#5fd6ff";
                    // Qt.binding() makes these re-evaluate whenever the
                    // underlying Sensors.Sensor.value changes (Loader.onLoaded
                    // is a one-shot — direct assignments would freeze on the
                    // value seen at first load, which is `undefined`).
                    item.rowValue = Qt.binding(function() {
                        return root.fmtPercentF(cpuUsage.value);
                    });
                    item.rowPercent = Qt.binding(function() {
                        return Number.isFinite(cpuUsage.value) ? cpuUsage.value : NaN;
                    });
                    item.rowSub = Qt.binding(function() {
                        return root.fmtClockMhz(cpuAvgClock.value);
                    });
                }
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: usageRow
                onLoaded: {
                    item.rowLabel = "GPU";
                    item.rowBarColor = "#ff5fb0";
                    // rowSub shows the GPU clock (reactive on gpuClock.value).
                    item.rowSub = Qt.binding(function() {
                        return root.fmtClockMhz(gpuClock.value);
                    });
                    item.rowValue = Qt.binding(function() {
                        return root.fmtPercentF(gpuUsage.value);
                    });
                    item.rowPercent = Qt.binding(function() {
                        return Number.isFinite(gpuUsage.value) ? gpuUsage.value : NaN;
                    });
                }
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: usageRow
                onLoaded: {
                    item.rowLabel = "RAM";
                    item.rowBarColor = "#b78dff";
                    item.rowSub = Qt.binding(function() {
                        return root.fmtPercentF(ramPercent.value);
                    });
                    item.rowValue = Qt.binding(function() {
                        return root.fmtBytesGiB(ramUsed.value, ramTotal.value);
                    });
                    item.rowPercent = Qt.binding(function() {
                        return Number.isFinite(ramPercent.value) ? ramPercent.value : NaN;
                    });
                }
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: usageRow
                onLoaded: {
                    item.rowLabel = "VRAM";
                    item.rowBarColor = "#5f9eff";
                    // All three are reactive: re-evaluate whenever the
                    // vramUsed / vramTotal sensor values change.
                    item.rowValue = Qt.binding(function() {
                        return root.fmtBytesGiB(vramUsed.value, vramTotal.value);
                    });
                    item.rowPercent = Qt.binding(function() {
                        const used = vramUsed.value;
                        const total = vramTotal.value;
                        if (Number.isFinite(used) && Number.isFinite(total) && total > 0) {
                            return (used / total) * 100;
                        }
                        return NaN;
                    });
                    item.rowSub = Qt.binding(function() {
                        const used = vramUsed.value;
                        const total = vramTotal.value;
                        if (Number.isFinite(used) && Number.isFinite(total) && total > 0) {
                            return ((used / total) * 100).toFixed(0) + "%";
                        }
                        return "";
                    });
                }
            }

            // Thin separator
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(0.42, 0.30, 0.72, 0.18) }

            // ---- RPM rows ----
            Component {
                id: rpmRow
                RowLayout {
                    property string rowLabel: ""
                    property string rowValue: ""
                    property int    rowState: root.stateHealthy

                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: root.colorForState(rowState)
                        opacity: rowState === root.stateHealthy ? 0.85 : 1.0
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: rowLabel
                        color: "#8a7daa"
                        font.family: root.monoFamily; font.pixelSize: 9; font.letterSpacing: 1.0; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: rowValue
                        color: rowState === root.stateAlert ? "#ff6b3d"
                             : rowState === root.stateWarn  ? "#ffd24a"
                             : "#6fff8b"
                        font.family: root.monoFamily; font.pixelSize: 12; font.bold: true; font.kerning: false
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                sourceComponent: rpmRow
                onLoaded: {
                    item.rowLabel = "RAD FANS";
                    // Reactive so the cell updates live as ksystemstats
                    // publishes new rpm values; one-shot onLoaded was leaving
                    // the row stuck on `undefined → em-dash` until restart.
                    item.rowValue = Qt.binding(function() {
                        return root.fmtRpm(radFans.value);
                    });
                }
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: rpmRow
                onLoaded: {
                    item.rowLabel = "LOOP PUMP";
                    item.rowValue = Qt.binding(function() {
                        return root.fmtRpm(loopPump.value);
                    });
                    // The state indicator dot is a property on the row, so
                    // rebind it against root.pumpState (which itself tracks
                    // loopPump.value via pumpStateFromRpm).
                    item.rowState = Qt.binding(function() {
                        return root.pumpState;
                    });
                }
            }
        }
    }

    // ---- Compact representation (when added to a vertical panel) ----
    compactRepresentation: Item {
        Layout.minimumWidth: 90
        Layout.minimumHeight: 28
        Layout.preferredWidth: 110
        Layout.preferredHeight: 32

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Qt.rgba(0.055, 0.040, 0.078, 0.92)
            border.color: root.colorForState(root.healthState)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: root.colorForState(root.healthState)
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.fmtTemp(loopTemp.value)
                    color: "#f3eaff"
                    font.family: root.monoFamily
                    font.pixelSize: 12
                    font.bold: true
                    font.kerning: false
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ---- Tooltip on hover ----
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        textFormat: Text.RichText
        mainText: "Palace Thermal Deck"
        subText:
            "<b>Loop</b> " + root.fmtTemp(loopTemp.value) +
            " &nbsp; <b>CPU</b> " + root.fmtTemp(cpuTemp.value) +
            " &nbsp; <b>GPU</b> " + root.fmtTemp(gpuTemp.value) +
            "<br/><b>CPU</b> " + root.fmtPercentF(cpuUsage.value) +
            " &nbsp; <b>GPU</b> " + root.fmtPercentF(gpuUsage.value) +
            " &nbsp; <b>CPU clk</b> " + root.fmtClockMhz(cpuAvgClock.value) +
            " &nbsp; <b>GPU clk</b> " + root.fmtClockMhz(gpuClock.value) +
            "<br/><b>RAM</b> " + root.fmtBytesGiB(ramUsed.value, ramTotal.value) +
            " &nbsp; <b>VRAM</b> " + root.fmtBytesGiB(vramUsed.value, vramTotal.value) +
            "<br/><b>Rad fans</b> " + root.fmtRpm(radFans.value) +
            " &nbsp; <b>Pump</b> " + root.fmtRpm(loopPump.value)
    }
}
