import QtQuick
import qs
import qs.components

Seg {
  id: root

  readonly property var resourceProps: [
    { category: "cpu", title: "CPU", glyph: "\u{f0ee0}", color: Theme.accent, format: TopProcesses.formatPercent },
    { category: "gpu", title: "GPU", glyph: "\u{f08ae}", color: Theme.mauve, format: TopProcesses.formatPercent },
    { category: "memory", title: "RAM", glyph: "\u{f035b}", color: Theme.green, format: TopProcesses.formatBytes },
    { category: "disk", title: "Disk", glyph: "\u{f02ca}", color: Theme.yellow, format: TopProcesses.formatRate }
  ]
  readonly property var resources: resourceProps.filter(resource => resource.category !== "gpu" || TopProcesses.gpuSupported)
  readonly property int chipSpacing: 16
  readonly property real chipWidth: (width - chipSpacing * (resources.length - 1)) / resources.length
  readonly property int separatorSize: 3
  readonly property int glyphSpacing: 5
  readonly property int tooltipRankingSize: 3

  function describeEntry(resource, entry) {
    return `  ${entry.name} · ${resource.format(entry.value)}` + (entry.count > 1 ? ` (${entry.count} processes)` : "");
  }

  function describeResource(resource) {
    const ranking = (TopProcesses.rankings[resource.category] ?? []).slice(0, root.tooltipRankingSize);
    const lines = ranking.map(entry => root.describeEntry(resource, entry));
    return [`${resource.glyph} ${resource.title}`, ...(lines.length ? lines : ["  idle"])].join("\n");
  }

  trackVisible: false
  tip: resources.map(resource => root.describeResource(resource)).join("\n\n")

  component ResourceChip: Item {
    id: chip

    required property var resource
    readonly property var leader: TopProcesses.leaders[resource.category] ?? null

    width: root.chipWidth
    height: parent.height

    Row {
      anchors.centerIn: parent
      spacing: root.glyphSpacing

      Icon {
        id: chipGlyph
        anchors.verticalCenter: parent.verticalCenter
        text: chip.resource.glyph
        font.pixelSize: 16
        color: chip.leader ? chip.resource.color : Theme.muted
        Behavior on color {
          ColorAnimation {
            duration: 400
          }
        }
      }

      Label {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, chip.width - chipGlyph.implicitWidth - root.glyphSpacing)
        clip: true
        font.pixelSize: 13
        color: chip.leader ? Theme.fg : Theme.dim
        text: chip.leader?.name ?? "idle"
      }
    }
  }

  Row {
    anchors.fill: parent
    spacing: root.chipSpacing

    Repeater {
      model: root.resources.length
      ResourceChip {
        required property int index
        resource: root.resources[index]
      }
    }
  }

  Repeater {
    model: root.resources.length - 1
    Rectangle {
      required property int index
      x: (index + 1) * root.chipWidth + index * root.chipSpacing + (root.chipSpacing - width) / 2
      anchors.verticalCenter: parent.verticalCenter
      width: root.separatorSize
      height: root.separatorSize
      radius: root.separatorSize / 2
      color: Theme.muted
    }
  }
}
