import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

PanelWindow {
  id: bar

  required property ShellScreen modelData

  implicitHeight: Theme.wbHeight
  color: "transparent"
  screen: modelData

  anchors {
    top: true
    left: true
    right: true
  }
  margins {
    top: Theme.gap
    left: Theme.gap
    right: Theme.gap
  }

  RowLayout {
    x: Math.round((parent.width - width) / 2)
    height: parent.height
    spacing: 0

    SystemStats {}
    DistroBadge {}
    ClockDate {}
    Connectivity {}
  }

  RowLayout {
    anchors.left: parent.left
    height: parent.height
    spacing: 0

    AppStrip {}
  }

  RowLayout {
    anchors.right: parent.right
    height: parent.height
    spacing: 0

    DeviceStatus {}
  }
}
