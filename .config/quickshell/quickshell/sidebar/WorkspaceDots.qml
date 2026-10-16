import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

Item {
    id: root

    readonly property var ids: {
        const s = new Set([1, 2, 3, 4, 5]);
        for (const w of Hyprland.workspaces.values)
            if (w.id > 0)
                s.add(w.id);
        return [...s].sort((a, b) => a - b);
    }
    readonly property var used: Hyprland.workspaces.values.filter(w => w.id > 0 && (w.toplevels?.values.length ?? 1) > 0).map(w => w.id)
    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 1

    function go(ws) {
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = "${ws}" })`]);
    }

    implicitWidth: Theme.sideButton
    implicitHeight: col.implicitHeight + 12

    WheelHandler {
        onWheel: e => root.go(e.angleDelta.y > 0 ? "-1" : "+1")
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.ids

            Item {
                id: ws
                required property int modelData
                readonly property bool active: root.activeId === modelData
                readonly property bool busy: root.used.includes(modelData)

                width: Theme.sideButton
                height: active ? 26 : 14

                Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.centerIn: parent
                    width: ws.active ? 6 : ma.containsMouse ? 8 : 6
                    height: ws.active ? 22 : width
                    radius: 3
                    color: ws.active ? Theme.accent : ws.busy ? Theme.fg : Theme.muted
                    Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(ws.modelData)
                }
            }
        }
    }
}
