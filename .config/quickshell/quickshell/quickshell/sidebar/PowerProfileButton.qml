import QtQuick
import Quickshell.Services.UPower
import qs

SideButton {
    readonly property int p: PowerProfiles.profile

    icon: p === PowerProfile.PowerSaver ? "󰌪" : p === PowerProfile.Performance ? "󰓅" : "󰾅"
    iconColor: p === PowerProfile.PowerSaver ? Theme.green : p === PowerProfile.Performance ? Theme.red : Theme.fg
    tip: "Power profile: " + (p === PowerProfile.PowerSaver ? "power saver" : p === PowerProfile.Performance ? "performance" : "balanced")
        + "\n󰍽 right-click goes back"

    onClicked: m => Ui.cycleProfile(m.button === Qt.RightButton)
}
