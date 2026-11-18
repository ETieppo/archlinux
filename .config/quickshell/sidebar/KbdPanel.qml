import QtQuick
import QtQuick.Layouts
import qs
import qs.components

ColumnLayout {
    id: root

    readonly property real fraction: KbdLight.bright / KbdLight.max
    readonly property bool manual: KbdLight.since > 0
    property real now: Date.now()

    function levelAt(x) {
        return Math.round(KbdLight.max * Math.max(0, Math.min(1, x / track.width)));
    }

    function presetLabel(level) {
        return level === 0 ? "Off" : level === KbdLight.max ? "Max" : `${level}%`;
    }

    spacing: 14

    Timer {
        running: root.visible && root.manual
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    RowLayout {
        Label {
            Layout.fillWidth: true
            text: "Keyboard light"
            color: Theme.accent
        }
        Label {
            text: KbdLight.levelText
            color: KbdLight.bright > 0 ? Theme.fg : Theme.dim
            font.pixelSize: 20
        }
    }

    Rectangle {
        id: track
        Layout.fillWidth: true
        implicitHeight: 34
        radius: height / 2
        color: Theme.surface

        Rectangle {
            visible: KbdLight.bright > 0
            width: Math.max(parent.height, parent.width * root.fraction)
            height: parent.height
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.18) }
                GradientStop { position: 1; color: Qt.alpha(Theme.accent, 0.35 + 0.5 * root.fraction) }
            }
            Behavior on width {
                enabled: !drag.pressed
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height - 10
                height: width
                radius: width / 2
                color: Theme.accent
                scale: drag.pressed ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
            }
        }

        Icon {
            visible: KbdLight.bright === 0
            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            text: "󰥻"
            color: Theme.dim
            font.pixelSize: 14
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: m => KbdLight.setBright(root.levelAt(m.x))
            onPositionChanged: m => {
                const level = root.levelAt(m.x);
                if (pressed && level !== KbdLight.bright)
                    KbdLight.setBright(level);
            }
            onWheel: w => KbdLight.stepBright(w.angleDelta.y > 0 ? 1 : -1)
        }
    }

    RowLayout {
        spacing: 6
        Repeater {
            model: KbdLight.presets
            Rectangle {
                required property int modelData
                readonly property bool selected: KbdLight.bright === modelData
                Layout.fillWidth: true
                implicitHeight: 26
                radius: 9
                color: selected ? Qt.alpha(Theme.accent, 0.18) : chip.containsMouse ? Theme.surface2 : Theme.surface
                border.width: modelData === KbdLight.autoBright ? 1 : 0
                border.color: Qt.alpha(Theme.accent, 0.4)
                Behavior on color { ColorAnimation { duration: 140 } }

                Label {
                    anchors.centerIn: parent
                    text: root.presetLabel(parent.modelData)
                    color: parent.selected ? Theme.accent : Theme.dim
                    font.pixelSize: 11
                }
                MouseArea {
                    id: chip
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: KbdLight.setBright(parent.modelData)
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        radius: 10
        color: root.manual && reset.containsMouse ? Theme.surface2 : Theme.surface
        Behavior on color { ColorAnimation { duration: 140 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            Icon {
                text: root.manual ? "󰏤" : KbdLight.restingAtNight ? "󰒲" : "󰁪"
                color: root.manual ? Theme.yellow : Theme.accent
                font.pixelSize: 13
            }
            Label {
                Layout.fillWidth: true
                text: root.manual ? `Auto in ${Term.fmt(Math.max(0, KbdLight.since + KbdLight.hold - root.now))}` : KbdLight.restingAtNight ? "Off for the night" : `Auto · ${KbdLight.autoBright}%`
                color: Theme.dim
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Label {
                visible: root.manual
                text: "Reset"
                color: Theme.accent
                font.pixelSize: 11
            }
        }
        MouseArea {
            id: reset
            anchors.fill: parent
            enabled: root.manual
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: KbdLight.restore()
        }
    }
}
