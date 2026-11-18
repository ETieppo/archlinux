pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property var temperatureRuleProps: [
    { name: "CPU package", device: /^coretemp$/, label: /^Package id 0$/, reduce: "max", cpu: true },
    { name: "Hottest core", device: /^coretemp$/, label: /^Core /, reduce: "max", cpu: true },
    { name: "CPU", device: /^k10temp$/, label: /^Tctl$/, reduce: "max", cpu: true },
    { name: "CPU die", device: /^macsmc_hwmon$/, label: /^CPU Die Max$/, reduce: "max", cpu: true },
    { name: "P-cluster", device: /^macsmc_hwmon$/, label: /^P-cluster/, reduce: "max", cpu: true },
    { name: "E-cluster", device: /^macsmc_hwmon$/, label: /^E-cluster/, reduce: "max", cpu: true },
    { name: "SSD", device: /^nvme$/, label: /^Composite$/, reduce: "each", cpu: false },
    { name: "Wi-Fi", device: /^iwlwifi/, label: /.*/, reduce: "first", cpu: false },
    { name: "Ethernet", device: /^r8169/, label: /.*/, reduce: "first", cpu: false },
    { name: "Battery", device: /battery/, label: /.*/, reduce: "first", cpu: false },
    { name: "Board", device: /^acpitz$/, label: /.*/, reduce: "first", cpu: false }
  ]

  property bool ready: false
  property string backlightPath: ""
  readonly property string backlightName: backlightPath.split("/").pop()
  property string keyboardLightPath: ""
  property bool keyboardLightRgb: false
  property int keyboardLightMax: 0
  property var temperatureSourceProps: []

  function groupSensors(sensors, rule) {
    const matches = sensors.filter(s => rule.device.test(s.device) && rule.label.test(s.label)).map(s => s.path);
    if (!matches.length)
      return [];
    if (rule.reduce === "each")
      return matches.map((path, i) => ({ name: matches.length > 1 ? `${rule.name} ${i + 1}` : rule.name, paths: [path] }));
    return [{ name: rule.name, paths: rule.reduce === "first" ? [matches[0]] : matches }];
  }

  function applyProbe(text) {
    const sensors = [];
    for (const line of text.trim().split("\n")) {
      const [kind, ...fields] = line.split("|");
      if (kind === "backlight") {
        root.backlightPath = fields[0];
      } else if (kind === "keyboard") {
        root.keyboardLightPath = fields[0];
        root.keyboardLightRgb = fields[1] === "rgb";
        root.keyboardLightMax = Number(fields[2]);
      } else if (kind === "temperature") {
        sensors.push({ device: fields[0], label: fields[1], path: fields[2] });
      }
    }
    root.temperatureSourceProps = root.temperatureRuleProps.reduce((sources, rule) => sources.concat(root.groupSensors(sensors, rule).map(source => Object.assign(source, { cpu: rule.cpu }))), []);
    root.ready = true;
  }

  Process {
    running: true
    command: [Quickshell.shellPath("scripts/hardware-probe")]
    stdout: StdioCollector {
      onStreamFinished: root.applyProbe(this.text)
    }
  }
}
