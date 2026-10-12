import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
        top: true
        left: true
    }
    margins {
        top: Theme.gap
        left: Theme.gap
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    color: "transparent"
    visible: Notifs.popups.length > 0
    implicitWidth: 360
    implicitHeight: Math.max(1, list.contentHeight + 20)

    ListView {
        id: list
        anchors.fill: parent
        anchors.leftMargin: 10
        spacing: 8
        interactive: false
        model: ScriptModel {
            values: Notifs.popups
        }
        delegate: Toast {}

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; from: -360; to: 0; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; to: -360; duration: 260; easing.type: Easing.InCubic }
                NumberAnimation { property: "opacity"; to: 0; duration: 260 }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 260; easing.type: Easing.OutCubic }
        }
    }
}
