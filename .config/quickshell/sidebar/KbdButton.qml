import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

SideButton {
    id: root

    readonly property bool open: pop.visible

    visible: KbdLight.present
    icon: KbdLight.bright > 0 ? "󰌌" : "󰥻"
    iconColor: KbdLight.bright > 0 ? KbdLight.color : Theme.muted
    active: pop.visible
    tip: pop.visible ? "" : `Keyboard light · ${KbdLight.sleeping ? "sleep mode · " : ""}${KbdLight.levelText}\n󰒭 scroll adjusts brightness`

    Keys.onEscapePressed: pop.visible = false
    onClicked: pop.visible = !pop.visible
    onWheel: d => KbdLight.stepBright(d > 0 ? 1 : -1)

    PanelWindow {
        screen: root.QsWindow.window?.screen ?? null
        visible: pop.visible
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-dismiss"
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: pop.visible = false
        }
    }

    PopupWindow {
        id: pop
        anchor.item: root
        anchor.rect.x: root.width + 16
        anchor.rect.y: root.height / 2
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.gravity: Edges.Right
        color: "transparent"
        implicitWidth: 236
        implicitHeight: panel.implicitHeight + 28
        onVisibleChanged: if (visible) root.forceActiveFocus()

        HyprlandFocusGrab {
            windows: [pop]
            active: pop.visible
            onCleared: pop.visible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.bgSolid
            border.width: 1
            border.color: Qt.alpha(KbdLight.color, 0.45)
            Behavior on border.color { ColorAnimation { duration: 250 } }

            KbdPanel {
                id: panel
                anchors.fill: parent
                anchors.margins: 14
            }
        }
    }
}
