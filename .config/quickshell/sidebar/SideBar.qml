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
  WlrLayershell.keyboardFocus: kbd.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
      id: cpuMeter
      readonly property var topology: Sys.cpuTopology
      readonly property var kinds: [...new Set(topology.map(t => t.kind))]
      readonly property var kindNames: ({ P: "P-cores", E: "E-cores", C: "Cores" })
      readonly property int hottest: Sys.cores.reduce((best, v, i) => v > (Sys.cores[best] ?? -1) ? i : best, 0)

      function mean(list) {
        return list.length ? list.reduce((a, b) => a + b, 0) / list.length : 0;
      }

      function rowsOf(kind) {
        const threads = topology.filter(t => t.kind === kind);
        const ranks = Math.max(0, ...threads.map(t => t.rank)) + 1;
        return Array.from({ length: ranks }, (_, r) => threads.filter(t => t.rank === r).sort((a, b) => a.core - b.core).map(t => t.id)).filter(row => row.length);
      }

      function kindSummary(kind) {
        const threads = topology.filter(t => t.kind === kind);
        const ids = threads.map(t => t.id);
        const cores = new Set(threads.map(t => t.core)).size;
        const load = Math.round(mean(ids.map(i => Sys.cores[i] ?? 0)));
        const ghz = (mean(ids.map(i => Sys.coreFreqs[i] ?? 0)) / 1000).toFixed(1);
        return `${kindNames[kind]} · ${cores}c/${ids.length}t · ${load}% · ${ghz} GHz`;
      }

      title: "CPU"
      summary: `${Sys.cpu}%`
      values: Sys.cores.map(v => v / 100)
      labels: Sys.cores.map(v => `${v}%`)
      names: Sys.cores.map((v, i) => topology[i]?.name ?? `T${i}`)
      layout: kinds.map(k => rowsOf(k))
      maxColumns: 6
      rows: 2
      barHeight: topology.length ? 12 : 18
      tip: [
        `CPU · ${Sys.cpu}% across ${Sys.cores.length} threads`,
        ...kinds.map(k => kindSummary(k)),
        `hottest · ${topology[hottest]?.name ?? `T${hottest}`} · ${Sys.cores[hottest] ?? 0}%`,
        `load · ${Sys.loadAvg}`
      ].join("\n")
    }

    MeterBlock {
      readonly property var dgpu: Sys.dgpu
      readonly property var igpu: Sys.igpu
      readonly property var meters: [
        ...(dgpu ? [
          { name: "GPU", ratio: dgpu.util / 100, label: `${dgpu.util}%` },
          { name: "MEM", ratio: dgpu.memUtil / 100, label: `${dgpu.memUtil}%` },
          dgpu.enc === null ? null : { name: "ENC", ratio: dgpu.enc / 100, label: `${dgpu.enc}%` },
          dgpu.dec === null ? null : { name: "DEC", ratio: dgpu.dec / 100, label: `${dgpu.dec}%` },
          dgpu.vramTotal > 0 ? { name: "VRAM", ratio: dgpu.vramUsed / dgpu.vramTotal, label: `${Math.round(100 * dgpu.vramUsed / dgpu.vramTotal)}%` } : null
        ] : []),
        igpu ? { name: "iGPU", ratio: igpu.freq / igpu.maxFreq, label: `${(igpu.freq / 1000).toFixed(1)}G` } : null
      ].filter(Boolean)

      visible: meters.length > 0
      title: "GPU"
      summary: dgpu ? `${dgpu.util}%` : Sys.dgpuState === "suspended" ? "off" : "–"
      values: meters.map(m => m.ratio)
      labels: meters.map(m => m.label)
      names: meters.map(m => m.name)
      tip: [
        ...(dgpu ? [
          `${dgpu.name} · ${dgpu.pstate}`,
          `util ${dgpu.util}% · memory controller ${dgpu.memUtil}%`,
          dgpu.enc === null ? "" : `encoder ${dgpu.enc}% · decoder ${dgpu.dec ?? 0}%`,
          `VRAM ${dgpu.vramUsed} / ${dgpu.vramTotal} MiB`,
          [`${dgpu.clock} MHz`, `${dgpu.temp}°C`, dgpu.power === null ? "" : `${dgpu.power.toFixed(1)} W`].filter(Boolean).join(" · ")
        ] : Sys.dgpuState === "suspended" ? ["dGPU suspended"] : []),
        igpu ? `iGPU · ${igpu.freq} / ${igpu.maxFreq} MHz` : ""
      ].filter(Boolean).join("\n")
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
    KbdButton {
      id: kbd
    }
    PowerProfileButton {}

    Sep {}

    PowerDrawer {}
  }
}
