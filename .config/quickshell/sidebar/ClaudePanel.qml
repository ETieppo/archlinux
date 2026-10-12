import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components

PanelWindow {
    id: root

    readonly property int header: 36
    readonly property int pad: Ui.claudePad
    property real reveal: Ui.claudeOpen ? 1 : 0

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
        right: true
        top: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-claude"
    implicitWidth: Ui.claudeWidth + 2 * pad
    color: "transparent"
    visible: reveal > 0

    Behavior on reveal { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    mask: Region {
        item: body
        Region {
            item: hole
            intersection: Intersection.Subtract
        }
    }

    Item {
        id: body
        width: parent.width
        height: parent.height
        x: (1 - root.reveal) * width

        EdgeShape {
            anchors.fill: parent
            edge: "right"
            fillet: Theme.fillet
            fill: Theme.bgSolid
            hole: Qt.rect(hole.x, hole.y, hole.width, hole.height)
        }

        Item {
            id: hole
            x: root.pad
            y: Theme.fillet + root.header
            width: Ui.claudeWidth
            height: parent.height - 2 * Theme.fillet - root.header - root.pad
        }

        RowLayout {
            x: root.pad + 6
            y: Theme.fillet
            width: Ui.claudeWidth - 12
            height: root.header

            Text {
                text: "✻"
                color: "#d97757"
                font.pixelSize: 20
                font.bold: true
            }
            Label {
                Layout.fillWidth: true
                text: "Claude"
                font.pixelSize: 15
            }
            Label {
                text: "ALT + /"
                color: Theme.muted
                font.pixelSize: 12
            }
            Icon {
                text: "󰅖"
                font.pixelSize: 16
                color: closeMa.containsMouse ? Theme.red : Theme.dim
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Ui.toggleClaude()
                }
            }
        }
    }
}
