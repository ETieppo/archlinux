import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs

PanelWindow {
  id: bar
  implicitHeight: Theme.wbHeight
  color: "transparent"
  screen: modelData
  required property ShellScreen modelData

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

  readonly property string scripts: Quickshell.shellPath("scripts") + "/"
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
  readonly property var battery: UPower.displayDevice
  readonly property var bt: Bluetooth.defaultAdapter

  function icon(list, value, max = 100) {
    const step = Math.floor(max / list.length);
    return list[Math.max(0, Math.min(list.length - 1, Math.floor(Math.round(value) / step)))];
  }

  function sh(cmd) {
    Quickshell.execDetached(["sh", "-c", cmd]);
  }

  PwObjectTracker {
    objects: [bar.sink, bar.source]
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  RowLayout {
    x: Math.round((parent.width - width) / 2)
    height: parent.height
    spacing: 0

    WbModule {
      minChars: 7
      text: (Sys.disk >= 75 ? "󰀧" : "󰋊") + ` ${Sys.disk}%`
      tip: `<b>Disk</b>: ${Sys.diskInfo}`
    }
    WbModule {
      minChars: 8
      readonly property bool critical: Sys.temp >= 90
      text: (critical ? "󰀦" : bar.icon(["󱃃", "󰔏", "󱃂"], Sys.temp, 90)) + ` ${Sys.temp}°C`
      color: critical ? Theme.red : Theme.wbFg
      tip: `<b>Temperature</b>: ${Sys.temp}°C`
    }
    WbModule {
      minChars: 7
      text: (Sys.mem >= 75 ? "󰀧" : "󰘚") + ` ${Sys.mem}%`
      color: Sys.mem >= 90 ? Theme.red : Sys.mem >= 75 ? Theme.yellow : Theme.wbFg
      tip: `<b>Memory</b>: ${Sys.memUsed.toFixed(1)} / ${Sys.memTotal.toFixed(1)} GiB`
    }
    WbModule {
      minChars: 3
      text: `󰢮 ${Sys.gpu}%`
      tip: `<b>GPU</b>: ${Sys.gpu}%` + (Sys.gpuTemp ? ` · ${Sys.gpuTemp}°C` : "")
    }
    WbModule {
      minChars: 7
      text: (Sys.cpu >= 75 ? "󰀨" : "󰍛") + ` ${Sys.cpu}%`
      color: Sys.cpu >= 90 ? Theme.red : Sys.cpu >= 75 ? Theme.yellow : Theme.wbFg
      tip: `<b>CPU</b>: ${Sys.cpu}%`
    }

    Text {
      Layout.fillHeight: true
      verticalAlignment: Text.AlignVCenter
      Layout.rightMargin: -1
      text: "  "
      color: Theme.accent
      font.family: Theme.font
      font.pixelSize: 22
      font.bold: true
    }
    Rectangle {
      Layout.fillHeight: true
      implicitWidth: 6 + Math.max(Math.ceil(distroFm.advanceWidth("0")) * 3, distro.implicitWidth)
      color: Theme.accent

      FontMetrics {
        id: distroFm
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
      verticalAlignment: Text.AlignVCenter
      Layout.leftMargin: -1
      text: "  "
      color: Theme.accent
      font.family: Theme.font
      font.pixelSize: 22
      font.bold: true
    }

    WbModule {
      minChars: 5
      padL: 19
      padR: 16
      text: Qt.formatTime(clock.date, "HH:mm")
      tip: `<b>Standard Time</b>: ${Qt.formatTime(clock.date, "hh:mm AP").toLowerCase()}`
    }
    WbModule {
      id: datePill
      minChars: 8
      padL: 19
      padR: 16
      text: "󰸗 " + Qt.formatDate(clock.date, "dd-MM")
      CalendarPopup {
        target: datePill
        visible: datePill.hovered
      }
    }
    WbModule {
      minChars: 2
      padL: 0
      padR: 4
      text: !Sys.wifiEnabled && Sys.netType !== "ethernet" ? "󰤮" : Sys.netType === "ethernet" ? "󰈀" : Sys.netType === "wifi" ? bar.icon(["󰤟", "󰤢", "󰤥", "󰤨"], Sys.netSignal) : "󰤯"
      tip: Sys.netType === "ethernet" ? `<b>Interface</b>: ${Sys.netIf}`
      : Sys.netType === "wifi" ? `<b>Network</b>: ${Sys.netName}<br><b>IP Addr</b>: ${Sys.netIp}<br><b>Strength</b>: ${Sys.netSignal}%<br><b>Frequency</b>: ${Sys.netFreq.toFixed(1)} GHz`
      : Sys.wifiEnabled ? "Wi-Fi Disconnected" : "Wi-Fi Disabled"
      onClicked: m => {
        if (m.button === Qt.RightButton)
        bar.sh(bar.scripts + "network off");
        else
        bar.sh("ghostty -e " + bar.scripts + "network");
        Sys.refreshNet();
      }
    }
    WbModule {
      minChars: 2
      padL: 1
      readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
      text: !bar.bt || !bar.bt.enabled ? "󰂲" : connected.length ? "󰂱" : "󰂰"
      tip: !bar.bt || !bar.bt.enabled ? "Bluetooth Off" : connected.length ? connected.map(d => `Device: ${d.name}` + (d.batteryAvailable ? `\nBattery: ${Math.round(d.battery * 100)}%` : "")).join("\n") : "Bluetooth Disconnected"
      onClicked: m => bar.sh(m.button === Qt.RightButton ? bar.scripts + "bluetooth off" : "ghostty -e " + bar.scripts + "bluetooth")
    }
    WbModule {
      visible: Sys.updatesText !== ""
      minChars: 2
      padL: 0
      padR: 4
      text: Sys.updatesText
      tip: Sys.updatesTip.replace(/\n/g, "<br>")
      onClicked: m => {
        if (m.button === Qt.RightButton)
        Sys.checkUpdates();
        else
        bar.sh("ghostty -e " + bar.scripts + "update");
      }
    }
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

    WbModule {
      visible: bar.player !== null
      underline: false
      marginsOn: false
      minWidth: 0
      padL: 12
      padR: 12
      bold: false
      text: bar.player ? (bar.player.isPlaying ? "󰐊 " : "󰏤 ") + (bar.player.trackTitle || bar.player.identity) : ""
      tip: bar.player ? [bar.player.identity, bar.player.trackArtist, bar.player.trackTitle].filter(s => s).join(" - ") : ""
      onClicked: bar.player?.togglePlaying()
      onWheel: d => d > 0 ? bar.player?.next() : bar.player?.previous()
    }

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
        x: 5
        opacity: pulse.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        height: parent.height
        marginsOn: false
        minChars: 7
        readonly property real vol: bar.source?.audio?.volume ?? 0
        text: (bar.source?.audio?.muted ? "󰍭" : "󰍬") + ` ${Math.round(vol * 100)}%`
        tip: `<b>Input Device</b>: ${bar.source?.description ?? ""}`
        onClicked: bar.sh(bar.scripts + "volume input mute")
        onWheel: d => bar.sh(bar.scripts + "volume input " + (d > 0 ? "raise" : "lower"))
      }

      WbModule {
        id: output
        anchors.right: parent.right
        anchors.rightMargin: 5
        height: parent.height
        marginsOn: false
        minChars: 7
        readonly property real vol: bar.sink?.audio?.volume ?? 0
        readonly property bool muted: bar.sink?.audio?.muted ?? false
        readonly property string form: bar.sink?.properties["device.form-factor"] ?? ""
        text: (form === "headphone" ? (muted ? "󰟎" : "󰋋")
          : form === "headset" ? (muted ? "󰋐" : "󰋎")
          : muted ? "󰝟" : bar.icon(["󰕿", "󰖀", "󰕾"], vol * 100)) + ` ${Math.round(vol * 100)}%`
        tip: `<b>Output Device</b>: ${bar.sink?.description ?? ""}`
        onClicked: bar.sh(bar.scripts + "volume output mute")
        onWheel: d => bar.sh(bar.scripts + "volume output " + (d > 0 ? "raise" : "lower"))
      }
    }

    WbModule {
      minChars: 7
      text: bar.icon(["\ue38d", "\ue3d3", "\ue3d1", "\ue3cf", "\ue3ce", "\ue3cd", "\ue3ca", "\ue3c8", "\ue39b"], Sys.brightness) + ` ${Sys.brightness}%`
      onWheel: d => Sys.setBrightness(Sys.brightness + (d > 0 ? 1 : -1))
    }

    WbModule {
      id: batt
      visible: bar.battery?.isPresent ?? false
      minChars: 7
      readonly property int pct: {
        const p = bar.battery?.percentage ?? 0;
        return Math.round(p <= 1 ? p * 100 : p);
      }
      readonly property bool charging: bar.battery?.state === UPowerDeviceState.Charging
      readonly property bool discharging: bar.battery?.state === UPowerDeviceState.Discharging
      text: (charging ? "󰉁" : bar.icon(["󰂎", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"], pct)) + ` ${pct}%`
      color: charging ? Theme.green : discharging && pct <= 10 ? Theme.red : discharging && pct <= 20 ? Theme.yellow : Theme.wbFg
      tip: {
        const b = bar.battery;
        if (!b) return "";
        const t = charging ? b.timeToFull : b.timeToEmpty;
        return t > 0 ? `${Math.floor(t / 3600)}h ${Math.floor(t % 3600 / 60)}min` : `${pct}%`;
      }

      property int lastLevel: 100
      onPctChanged: {
        const n = (msg, icon) => bar.sh(`hyprctl notify -1 5000 'rgb(0, 253, 255)' '${msg}' -u critical -i '${icon}' -h string:x-canonical-private-synchronous:battery`);
        if (discharging && pct <= 10 && lastLevel > 10)
        n("Battery Critical (10%)", "battery-010");
        else if (discharging && pct <= 20 && lastLevel > 20)
        n("Battery Low (20%)", "battery-020");
        else if (charging && pct === 100 && lastLevel < 100)
        n("Battery Full (100%)", "battery-100-charged");
        lastLevel = pct;
      }
    }
  }
}
