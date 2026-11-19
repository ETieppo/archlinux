pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Services.UPower

Singleton {
  id: root

  readonly property var device: UPower.displayDevice
  readonly property bool present: device?.isPresent ?? false
  readonly property int pct: {
    const p = device?.percentage ?? 0;
    return Math.round(p <= 1 ? p * 100 : p);
  }
  readonly property bool charging: device?.state === UPowerDeviceState.Charging
  readonly property bool discharging: device?.state === UPowerDeviceState.Discharging
  readonly property real timeLeft: charging ? (device?.timeToFull ?? 0) : (device?.timeToEmpty ?? 0)
  property int lastLevel: 100

  onPctChanged: {
    if (discharging && pct <= 10 && lastLevel > 10)
      Notifs.send("Battery", "Battery Critical (10%)", "", "critical", "battery-010");
    else if (discharging && pct <= 20 && lastLevel > 20)
      Notifs.send("Battery", "Battery Low (20%)", "", "critical", "battery-020");
    else if (charging && pct === 100 && lastLevel < 100)
      Notifs.send("Battery", "Battery Full - 100%", "", "normal", "battery-100-charged");
    lastLevel = pct;
  }

  SoundEffect {
    id: chargerConnectedSound
    source: `file://${Quickshell.env("HOME")}/.local/share/sounds/charging.wav`
  }

  Connections {
    target: UPower
    function onOnBatteryChanged() {
      if (!UPower.onBattery)
        chargerConnectedSound.play();
    }
  }
}
