import QtQuick
import QtQuick.Layouts
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
    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 1

    function go(ws) {
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = "${ws}" })`]);
    }

    Layout.rightMargin: 5
    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.wbHeight

    WheelHandler {
        onWheel: e => root.go(e.angleDelta.y > 0 ? "+1" : "-1")
    }

    WbModule {
        anchors.fill: parent
        marginsOn: false
        minWidth: 0
        padL: 0
    }

    Row {
        id: row
        x: 6
        height: parent.height

        Repeater {
            model: root.ids

            Rectangle {
                id: btn
                required property int modelData
                readonly property bool active: root.activeId === modelData

                width: 20 + Math.max(16, glyph.implicitWidth)
                height: parent.height - 6
                y: 3
                radius: 16
                color: ma.containsMouse ? Theme.slate1 : "transparent"

                Text {
                    id: glyph
                    anchors.centerIn: parent
                    text: btn.active ? "" : ""
                    color: btn.active ? Theme.accent : Theme.wbFg
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(btn.modelData)
                }
            }
        }
    }
}
