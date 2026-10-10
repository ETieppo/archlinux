import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

PanelWindow {
    id: side

    required property ShellScreen modelData

    screen: modelData
    anchors {
        left: true
        top: true
        bottom: true
    }
    implicitWidth: Theme.sideWidth
    color: "transparent"

    EdgeShape {
        id: shape
        anchors.fill: parent
        edge: "left"
        fillet: Theme.fillet
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Theme.fillet + 8
        anchors.bottomMargin: Theme.fillet + 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 5

        ClockRing {}

        Sep {}

        Repeater {
            model: ScriptModel {
                values: [...new Set(ToplevelManager.toplevels.values.map(t => t.appId).filter(id => id && id !== "claude-panel"))]
            }
            AppButton {}
        }

        Sep {}

        Vinyl {}
        Pomodoro {}

        Sep {}

        SideButton {
            icon: "󰈊"
            tip: Ui.lastColor ? `Último: ${Ui.lastColor}\n󰍽 direito: copiar de novo` : "Conta-gotas"
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
            tip: "Screenshot de região\n󰍽 direito: tela inteira"
            onClicked: m => Ui.screenshot(m.button !== Qt.RightButton)
        }
        SideButton {
            icon: "󱩌"
            tip: Ui.nightLight ? "Luz noturna: ligada" : "Luz noturna: desligada"
            active: Ui.nightLight
            iconColor: Theme.yellow
            onClicked: Ui.toggleNightLight()
        }
        KbdButton {}
        PowerProfileButton {}
        SideButton {
            icon: "󰚩"
            tip: "Claude  (ALT + /)"
            iconColor: "#d97757"
            active: Ui.claudeOpen
            onClicked: Ui.toggleClaude()
        }

        Item {
            Layout.fillHeight: true
        }

        Tray {
            window: side
        }

        PowerDrawer {}
    }
}
