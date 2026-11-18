pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property int refreshInterval: 3000
  readonly property list<string> byteUnits: ["B", "K", "M", "G", "T"]
  readonly property list<string> categories: ["cpu", "gpu", "memory", "disk"]
  readonly property real leaderSwitchRatio: 1.25
  readonly property real leaderHoldRatio: 0.5
  readonly property var leaderSwitchMargins: ({
      cpu: 10,
      gpu: 10,
      memory: 256 * 1024 * 1024,
      disk: 1024 * 1024
    })
  property var rankings: ({})
  property var leaders: ({})
  property bool gpuSupported: false

  function formatBytes(bytes) {
    let value = bytes;
    let unitIndex = 0;
    while (value >= 1024 && unitIndex < root.byteUnits.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return `${value >= 10 || unitIndex === 0 ? Math.round(value) : value.toFixed(1)}${root.byteUnits[unitIndex]}`;
  }

  function formatPercent(percent) {
    return `${Math.round(percent)}%`;
  }

  function formatRate(bytesPerSecond) {
    return `${root.formatBytes(bytesPerSecond)}/s`;
  }

  function chooseLeader(category, ranking) {
    const challenger = ranking[0] ?? null;
    const holdMinimum = root.leaderSwitchMargins[category] * root.leaderHoldRatio;
    const current = ranking.find(entry => entry.name === root.leaders[category]?.name && entry.value >= holdMinimum) ?? null;
    if (!challenger)
      return null;
    const switchThreshold = (current?.value ?? 0) * root.leaderSwitchRatio + root.leaderSwitchMargins[category];
    return challenger.value >= switchThreshold ? challenger : current;
  }

  function applySample(sample) {
    const nextRankings = {};
    const nextLeaders = {};
    for (const category of root.categories) {
      nextRankings[category] = sample[category] ?? [];
      nextLeaders[category] = root.chooseLeader(category, nextRankings[category]);
    }
    root.rankings = nextRankings;
    root.leaders = nextLeaders;
    root.gpuSupported = sample.gpu_supported ?? root.gpuSupported;
  }

  Timer {
    interval: root.refreshInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!sampler.running)
        sampler.running = true;
    }
  }

  Process {
    id: sampler
    command: [Quickshell.shellPath("scripts/top-processes")]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.applySample(JSON.parse(this.text));
        } catch (error) {
          root.applySample({});
        }
      }
    }
  }
}
