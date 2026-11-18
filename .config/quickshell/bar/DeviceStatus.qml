import QtQuick
import QtQuick.Layouts
import qs

RowLayout {
  spacing: 0

  Item {
    id: pulse
    readonly property bool open: hover.hovered
    implicitHeight: Theme.wbHeight
    implicitWidth: (open ? input.implicitWidth + 10 : 0) + output.implicitWidth + 10
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    HoverHandler {
      id: hover
    }

    WbModule {
      id: input
      readonly property real vol: BarKit.source?.audio?.volume ?? 0
      x: 5
      height: parent.height
      opacity: pulse.open ? 1 : 0
      marginsOn: false
      minChars: 7
      text: (BarKit.source?.audio?.muted ? "󰍭" : "󰍬") + ` ${Math.round(vol * 100)}%`
      tip: `<b>Input Device</b>: ${BarKit.source?.description ?? ""}`
      onClicked: BarKit.toggleMute(BarKit.source)
      onWheel: d => BarKit.changeVolume(BarKit.source, d > 0 ? 1 : -1)
      Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    WbModule {
      id: output
      readonly property real vol: BarKit.sink?.audio?.volume ?? 0
      readonly property bool muted: BarKit.sink?.audio?.muted ?? false
      readonly property string form: BarKit.sink?.properties["device.form-factor"] ?? ""
      anchors.right: parent.right
      anchors.rightMargin: 5
      height: parent.height
      marginsOn: false
      minChars: 7
      text: (form === "headphone" ? (muted ? "󰟎" : "󰋋")
        : form === "headset" ? (muted ? "󰋐" : "󰋎")
        : muted ? "󰝟" : BarKit.icon(["󰕿", "󰖀", "󰕾"], vol * 100)) + ` ${Math.round(vol * 100)}%`
      tip: `<b>Output Device</b>: ${BarKit.sink?.description ?? ""}`
      onClicked: BarKit.toggleMute(BarKit.sink)
      onWheel: d => BarKit.changeVolume(BarKit.sink, d > 0 ? 1 : -1)
    }
  }

  WbModule {
    visible: Hardware.backlightPath !== ""
    minChars: 7
    text: BarKit.icon(["", "", "", "", "", "", "", "", ""], Sys.brightness) + ` ${Sys.brightness}%`
    onWheel: d => Sys.setBrightness(Sys.brightness + (d > 0 ? 1 : -1))
  }

  WbModule {
    visible: Battery.present
    minChars: 7
    text: (Battery.charging ? "󰉁" : BarKit.icon(["󰂎", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"], Battery.pct)) + ` ${Battery.pct}%`
    color: Battery.charging ? Theme.green : Battery.discharging && Battery.pct <= 10 ? Theme.red : Battery.discharging && Battery.pct <= 20 ? Theme.yellow : Theme.wbFg
    tip: Battery.timeLeft > 0 ? `${Math.floor(Battery.timeLeft / 3600)}h ${Math.floor(Battery.timeLeft % 3600 / 60)}min` : `${Battery.pct}%`
  }
}
