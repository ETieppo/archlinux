import QtQuick
import QtQuick.Layouts
import qs

RowLayout {
  spacing: 0

  Text {
    Layout.fillHeight: true
    Layout.rightMargin: -1
    verticalAlignment: Text.AlignVCenter
    text: "  "
    color: Theme.accent
    font.family: Theme.font
    font.pixelSize: 22
    font.bold: true
  }
  Rectangle {
    Layout.fillHeight: true
    implicitWidth: 6 + Math.max(Math.ceil(distroMetrics.advanceWidth("0")) * 3, distro.implicitWidth)
    color: Theme.accent

    FontMetrics {
      id: distroMetrics
      font: distro.font
    }
    Text {
      id: distro
      x: 6 + (parent.width - 6 - width) / 2
      anchors.verticalCenter: parent.verticalCenter
      text: "󰣇 "
      color: Theme.slate1
      font.family: Theme.font
      font.pixelSize: 16
      font.bold: true
    }
  }
  Text {
    Layout.fillHeight: true
    Layout.leftMargin: -1
    verticalAlignment: Text.AlignVCenter
    text: "  "
    color: Theme.accent
    font.family: Theme.font
    font.pixelSize: 22
    font.bold: true
  }
}
