/* SPDX-License-Identifier: GPL-2.0-or-later */
import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "#09070D"
    property int stage

    Item {
        id: mark
        anchors.centerIn: parent
        width: Kirigami.Units.gridUnit * 8
        height: width
        opacity: 0
        scale: 0.94

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: "#A970FF"
            opacity: 0.8
        }

        Rectangle {
            id: pulse
            anchors.centerIn: parent
            width: parent.width * 0.34
            height: width
            radius: width / 2
            color: "#59E1FF"
            opacity: 0.9

            SequentialAnimation on opacity {
                running: Kirigami.Units.longDuration > 1
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 650; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.9; duration: 650; easing.type: Easing.InOutQuad }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: Kirigami.Units.largeSpacing
            width: parent.width * 1.4
            height: 2
            color: "#21152F"

            Rectangle {
                width: Math.max(2, parent.width * Math.min(1, root.stage / 6))
                height: parent.height
                color: "#A970FF"
                Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
        }
    }

    states: State {
        when: root.stage >= 2
        PropertyChanges { target: mark; opacity: 1; scale: 1 }
    }

    transitions: Transition {
        ParallelAnimation {
            NumberAnimation { properties: "opacity,scale"; duration: 180; easing.type: Easing.OutCubic }
        }
    }
}
