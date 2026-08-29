// JeevesLock — quickshell session-lock UI for the Jeeves After Dark palette.
// Replaces swaylock when running; swaylock remains the explicit fallback
// in the omarchy-cmd-lock wrapper and the Phase-1 hypridle listener chain.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "." as Local

WlSessionLock {
    id: lock

    surface: Component {
        Item {
            id: root

            // ---- Background ----
            Rectangle {
                anchors.fill: parent
                color: Local.Colors.backgroundDeep
            }
            // Subtle Jeeves-violet border
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Local.Colors.borderSubtle
                border.width: 1
            }

            // ---- Time + date (top center) ----
            ColumnLayout {
                anchors.top: parent.top
                anchors.topMargin: 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    id: timeText
                    text: Qt.formatDateTime(new Date(), "HH:mm")
                    color: Local.Colors.foregroundNormal
                    font.family: Local.Colors.fontFamily
                    font.pixelSize: 64
                    font.bold: true
                    font.kerning: false
                    Layout.alignment: Qt.AlignHCenter
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
                    }
                }
                Text {
                    text: Qt.formatDateTime(new Date(), "dddd, d MMMM yyyy")
                    color: Local.Colors.foregroundInactive
                    font.family: Local.Colors.fontFamily
                    font.pixelSize: 14
                    font.letterSpacing: 0.5
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // ---- Password prompt (center) ----
            ColumnLayout {
                id: promptColumn
                anchors.centerIn: parent
                spacing: 12
                Layout.preferredWidth: Math.min(root.width * 0.5, 480)

                Rectangle {
                    id: pill
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 26
                    color: Local.Colors.cardSurface
                    border.color: passwordInput.activeFocus ? Local.Colors.lavenderAccent : Local.Colors.borderSubtle
                    border.width: 2

                    Behavior on border.color {
                        ColorAnimation { duration: 120 }
                    }

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 22
                        anchors.rightMargin: 22
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Local.Colors.foregroundNormal
                        selectionColor: Local.Colors.lavenderAccent
                        selectedTextColor: Local.Colors.foregroundNormal
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 16
                        focus: true
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        onAccepted: root.submit()
                        Keys.onEscapePressed: { passwordInput.text = ""; passwordInput.forceActiveFocus(); }
                    }
                }

                Text {
                    id: errorText
                    Layout.alignment: Qt.AlignHCenter
                    color: Local.Colors.redAlert
                    font.family: Local.Colors.fontFamily
                    font.pixelSize: 12
                    text: ""
                    visible: text.length > 0
                }
            }

            // ---- PAM (system `login` stack: password prompt, unlock on success) ----
            PamContext {
                id: pam
                config: "login"

                onCompleted: {
                    if (success) {
                        lock.unlock()
                    } else {
                        // flash error, refocus input
                        pill.border.color = Local.Colors.redAlert
                        errorText.text = (message && message.length > 0) ? message : "Authentication failed"
                        passwordInput.text = ""
                        flashTimer.start()
                        passwordInput.forceActiveFocus()
                    }
                }
            }

            Timer {
                id: flashTimer
                interval: 350
                repeat: false
                onTriggered: pill.border.color = passwordInput.activeFocus ? Local.Colors.lavenderAccent : Local.Colors.borderSubtle
            }

            // Submit: start PAM if needed, then respond. PAM may take a tick after
            // start() before responseRequired becomes true — Qt.callLater defers it.
            function submit() {
                if (pam.active) {
                    if (pam.responseRequired) pam.respond(passwordInput.text)
                    return
                }
                if (pam.start()) {
                    Qt.callLater(function() {
                        if (pam.responseRequired && passwordInput.text.length > 0) {
                            pam.respond(passwordInput.text)
                        }
                    })
                }
            }

            Component.onCompleted: passwordInput.forceActiveFocus()
        }
    }
}
