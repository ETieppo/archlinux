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
  readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 1

  function go(ws) {
    Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = "${ws}" })`]);
  }

  implicitWidth: column.implicitWidth
  implicitHeight: column.implicitHeight

  WheelHandler {
    onWheel: e => root.go(e.angleDelta.y > 0 ? "+1" : "-1")
  }

  Column {
    id: column
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 2

    Repeater {
      model: root.ids

      Rectangle {
        id: btn
        required property int modelData
        readonly property bool active: root.activeId === modelData

        width: Theme.dockHeight - 12
        height: 26
        radius: 10
        color: ma.containsMouse ? Theme.surface : "transparent"

        Text {
          anchors.centerIn: parent
          text: btn.active ? "" : ""
          color: btn.active ? Theme.accent : Theme.muted
          font.family: Theme.font
          font.pixelSize: btn.active ? 18 : 14
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
