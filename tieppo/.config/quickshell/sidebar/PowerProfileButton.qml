import QtQuick
import Quickshell.Services.UPower
import qs

SideButton {
    readonly property int p: PowerProfiles.profile

    icon: p === PowerProfile.PowerSaver ? "󰌪" : p === PowerProfile.Performance ? "󰓅" : "󰾅"
    iconColor: p === PowerProfile.PowerSaver ? Theme.green : p === PowerProfile.Performance ? Theme.red : Theme.fg
    tip: "Perfil de energia: " + (p === PowerProfile.PowerSaver ? "economia" : p === PowerProfile.Performance ? "desempenho" : "equilibrado")
        + "\n󰍽 direito volta"

    onClicked: m => Ui.cycleProfile(m.button === Qt.RightButton)
}
