import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

ColumnLayout {
    id: root

    spacing: 4

    readonly property var actions: [
        { icon: "󰌾", tip: "Lock", color: Theme.fg, cmd: "lock" },
        { icon: "󰍃", tip: "Exit Hyprland", color: Theme.mauve, cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { icon: "󰤄", tip: "Suspend", color: Theme.accent, cmd: "suspend" },
        { icon: "󰜉", tip: "Reboot", color: Theme.accent, cmd: ["systemctl", "reboot"] },
        { icon: "󰐥", tip: "Power off", color: Theme.red, cmd: ["systemctl", "poweroff"] }
    ]

    Item {
        Layout.fillWidth: true
        implicitHeight: Ui.powerOpen ? drawer.implicitHeight : 0
        clip: true
        Behavior on implicitHeight { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: drawer
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: 4

            Repeater {
                model: root.actions
                SideButton {
                    required property var modelData
                    required property int index
                    icon: modelData.icon
                    tip: modelData.tip
                    iconColor: modelData.color
                    opacity: Ui.powerOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 + index * 60 } }
                    onClicked: {
                        Ui.powerOpen = false;
                        if (modelData.cmd === "lock") {
                            Ui.lock();
                        } else if (modelData.cmd === "suspend") {
                            Ui.lock();
                            Quickshell.execDetached(["sh", "-c", "sleep 0.6; systemctl suspend"]);
                        } else {
                            Quickshell.execDetached(modelData.cmd);
                        }
                    }
                }
            }
        }
    }

    SideButton {
        icon: Ui.powerOpen ? "󰅖" : "󰐥"
        iconColor: Theme.red
        active: Ui.powerOpen
        tip: Ui.powerOpen ? "" : "Power"
        onClicked: Ui.powerOpen = !Ui.powerOpen
    }

    Timer {
        running: Ui.powerOpen
        interval: 6000
        onTriggered: Ui.powerOpen = false
    }
}
