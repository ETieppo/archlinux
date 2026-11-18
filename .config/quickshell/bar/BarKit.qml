pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

Singleton {
  id: root

  readonly property string scripts: Quickshell.shellPath("scripts") + "/"
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property var bluetooth: Bluetooth.defaultAdapter
  readonly property date now: clock.date

  function icon(list, value, max = 100) {
    const step = Math.floor(max / list.length);
    return list[Math.max(0, Math.min(list.length - 1, Math.floor(Math.round(value) / step)))];
  }

  function sh(cmd) {
    Quickshell.execDetached(["sh", "-c", cmd]);
  }

  function toggleMute(node) {
    if (node?.audio)
      node.audio.muted = !node.audio.muted;
  }

  function changeVolume(node, delta) {
    if (node?.audio)
      node.audio.volume = Math.max(0, Math.min(100, Math.round(node.audio.volume * 100) + delta)) / 100;
  }

  PwObjectTracker {
    objects: [root.sink, root.source]
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
