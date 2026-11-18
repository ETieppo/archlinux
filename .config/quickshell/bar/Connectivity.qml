import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs

RowLayout {
  spacing: 0

  WbModule {
    minChars: 2
    padL: 0
    padR: 4
    text: !Sys.wifiEnabled && Sys.netType !== "ethernet" ? "󰤮" : Sys.netType === "ethernet" ? "󰈀" : Sys.netType === "wifi" ? BarKit.icon(["󰤟", "󰤢", "󰤥", "󰤨"], Sys.netSignal) : "󰤯"
    tip: Sys.netType === "ethernet" ? `<b>Interface</b>: ${Sys.netIf}`
      : Sys.netType === "wifi" ? `<b>Network</b>: ${Sys.netName}<br><b>IP Addr</b>: ${Sys.netIp}<br><b>Strength</b>: ${Sys.netSignal}%<br><b>Frequency</b>: ${Sys.netFreq.toFixed(1)} GHz`
      : Sys.wifiEnabled ? "Wi-Fi Disconnected" : "Wi-Fi Disabled"
    onClicked: m => {
      if (m.button === Qt.RightButton)
        BarKit.sh(BarKit.scripts + "network off");
      else
        BarKit.sh("xdg-terminal-exec " + BarKit.scripts + "network");
      Sys.refreshNet();
    }
  }
  WbModule {
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
    minChars: 2
    padL: 1
    text: !BarKit.bluetooth || !BarKit.bluetooth.enabled ? "󰂲" : connected.length ? "󰂱" : "󰂰"
    tip: !BarKit.bluetooth || !BarKit.bluetooth.enabled ? "Bluetooth Off" : connected.length ? connected.map(d => `Device: ${d.name}` + (d.batteryAvailable ? `\nBattery: ${Math.round(d.battery * 100)}%` : "")).join("\n") : "Bluetooth Disconnected"
    onClicked: m => {
      if (m.button === Qt.RightButton) {
        if (BarKit.bluetooth) {
          BarKit.bluetooth.enabled = false;
          Notifs.send("Bluetooth", "Bluetooth Off", "", "normal", "network-bluetooth-inactive");
        }
      } else {
        BarKit.sh("xdg-terminal-exec " + BarKit.scripts + "bluetooth");
      }
    }
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
        BarKit.sh("xdg-terminal-exec " + BarKit.scripts + "update");
    }
  }
}
