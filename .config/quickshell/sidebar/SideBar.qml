import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs
import qs.components

PanelWindow {
  id: side
  screen: modelData
  implicitWidth: Theme.sideWidth
  color: "transparent"

  required property ShellScreen modelData

  anchors {
    left: true
    top: true
    bottom: true
  }

  EdgeShape {
    id: shape
    anchors.fill: parent
    edge: "left"
    fillet: Theme.fillet
  }

  ColumnLayout {
    anchors.top: parent.top
    anchors.topMargin: Theme.fillet + 10
    anchors.horizontalCenter: parent.horizontalCenter
    width: Theme.sideButton
    spacing: 2

    ClockRing {}

    Sep {}

    MeterBlock {
      title: "CPU"
      summary: `${Sys.cpu}%`
      values: Sys.cores.map(v => v / 100)
      labels: Sys.cores.map(v => `${v}%`)
      names: Sys.cores.map((v, i) => `T${i}`)
      rows: 2
      tip: `CPU · ${Sys.cpu}% across ${Sys.cores.length} threads\nhottest thread: ${Math.max(0, ...Sys.cores)}%`
    }

    MeterBlock {
      readonly property var hottest: Sys.temps.reduce((a, b) => b.t > (a?.t ?? -1) ? b : a, null)
      title: "TEMP"
      summary: hottest ? `${hottest.t}°` : ""
      values: Sys.temps.map(s => (s.t - 30) / 70)
      labels: Sys.temps.map(s => `${s.t}°`)
      names: Sys.temps.map(s => s.name.split(" ")[0].slice(0, 4).toUpperCase())
      barHeight: 26
      warn: 0.57
      hot: 0.79
      tip: Sys.temps.map(s => `${s.name} · ${s.t}°C`).join("\n")
    }
  }

  WorkspaceDots {
    id: dots
    anchors.centerIn: parent
  }

  Tray {
    anchors.top: dots.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    width: Theme.sideButton
    window: side
  }

  ColumnLayout {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.fillet + 10
    anchors.horizontalCenter: parent.horizontalCenter
    width: Theme.sideButton
    spacing: 2

    SideButton {
      icon: "󰈊"
      tip: Ui.lastColor ? `Last: ${Ui.lastColor}\n󰍽 right-click: copy again` : "Color picker"
      onClicked: m => m.button === Qt.RightButton && Ui.lastColor ? Quickshell.clipboardText = Ui.lastColor : Ui.pickColor()

      Rectangle {
        visible: Ui.lastColor !== ""
        x: parent.width - 13
        y: parent.height - 13
        width: 10
        height: 10
        radius: 5
        color: Ui.lastColor || "transparent"
        border.width: 1.5
        border.color: Theme.bgSolid
      }
    }
    SideButton {
      icon: "󰹑"
      tip: "Region screenshot\n󰍽 right-click: full screen"
      onClicked: m => Ui.screenshot(m.button !== Qt.RightButton)
    }
    SideButton {
      icon: "󱩌"
      tip: Ui.nightLight ? "Night light: on" : "Night light: off"
      active: Ui.nightLight
      iconColor: Theme.accent
      onClicked: Ui.toggleNightLight()
    }
    KbdButton {}
    PowerProfileButton {}
    SideButton {
      icon: "󰚩"
      tip: "Claude  (ALT + /)"
      iconColor: "#d97757"
      active: Ui.claudeOpen
      onClicked: Ui.toggleClaude()
    }


    Sep {}

    PowerDrawer {}
  }
}
