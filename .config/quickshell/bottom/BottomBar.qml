import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

PanelWindow {
  id: bottom
  screen: modelData
  color: "transparent"
  implicitWidth: row.implicitWidth + 2 * Theme.fillet + 36
  implicitHeight: Theme.bottomHeight

  required property ShellScreen modelData

  anchors {
    bottom: true
  }

  component Rule: Rectangle {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: 1
    implicitHeight: 14
    color: Theme.muted
  }

  EdgeShape {
    anchors.fill: parent
    edge: "bottom"
    fillet: Theme.fillet
    radius: 14
  }

  RowLayout {
    id: row
    anchors.horizontalCenter: parent.horizontalCenter
    height: parent.height
    spacing: 18

    TermSeg {
      Layout.preferredWidth: 300
    }

    Rule {}

    MusicSeg {
      Layout.preferredWidth: 340
    }

    Rule {}

    PomodoroSeg {
      Layout.preferredWidth: 110
    }

    Rule {}

    AutoSeg {
      Layout.preferredWidth: 70
    }

    Rule {}

    NotifSeg {
      Layout.preferredWidth: 240
    }
  }
}
