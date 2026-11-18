import QtQuick
import QtQuick.Layouts
import qs

RowLayout {
  spacing: 0

  WbModule {
    minChars: 7
    text: (Sys.disk >= 75 ? "󰀧" : "󰋊") + ` ${Sys.disk}%`
    tip: `<b>Disk</b>: ${Sys.diskInfo}`
  }
  WbModule {
    readonly property bool critical: Sys.temp >= 90
    minChars: 8
    text: (critical ? "󰀦" : BarKit.icon(["󱃃", "󰔏", "󱃂"], Sys.temp, 90)) + ` ${Sys.temp}°C`
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
    visible: Sys.gpuAvailable
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
}
