import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

SideButton {
    id: root

    icon: KbdLight.bright > 0 ? "󰌌" : "󰥻"
    iconColor: KbdLight.bright > 0 ? KbdLight.color : Theme.muted
    active: pop.visible
    tip: pop.visible ? "" : `Keyboard light · ${KbdLight.sleeping ? "sleep mode" : KbdLight.mode === "sky" ? "following the sky" : "fixed color"} · ${KbdLight.bright}/${KbdLight.max}\n󰒭 scroll adjusts brightness`

    readonly property bool open: pop.visible

    Keys.onEscapePressed: pop.visible = false
    onClicked: pop.visible = !pop.visible
    onWheel: d => KbdLight.setBright(KbdLight.bright + (d > 0 ? 1 : -1))

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
        implicitHeight: col.implicitHeight + 28
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

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Label {
                        Layout.fillWidth: true
                        text: "Keyboard light"
                        color: Theme.accent
                    }
                    Label {
                        text: KbdLight.bright === 0 ? "off" : (KbdLight.sleeping ? "󰒲 sleep · " : KbdLight.mode === "sky" ? "sky · " : "") + `${KbdLight.bright}/${KbdLight.max}`
                        color: Theme.dim
                        font.pixelSize: 12
                    }
                }

                RowLayout {
                    spacing: 5
                    Repeater {
                        model: KbdLight.max + 1
                        Rectangle {
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 8
                            color: index === 0 ? (KbdLight.bright === 0 ? Theme.surface2 : Theme.surface)
                                : index <= KbdLight.bright ? Qt.alpha(KbdLight.color, 0.25 + 0.75 * index / KbdLight.max) : Theme.surface
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Icon {
                                anchors.centerIn: parent
                                visible: parent.index === 0
                                text: "󰥻"
                                font.pixelSize: 13
                                color: Theme.dim
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KbdLight.setBright(parent.index)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 10
                    color: Theme.surface
                    border.width: KbdLight.mode === "sky" ? 2 : 0
                    border.color: Theme.fg

                    SkyBar {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 70
                        anchors.rightMargin: 12
                        vertical: false
                        thickness: 6
                    }
                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖨 Sky"
                        color: KbdLight.mode === "sky" ? Theme.accent : Theme.dim
                        font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: KbdLight.followSky()
                    }
                }

                GridLayout {
                    columns: 5
                    rowSpacing: 8
                    columnSpacing: 8
                    Repeater {
                        model: KbdLight.presets
                        Rectangle {
                            required property var modelData
                            readonly property bool on: KbdLight.mode === "fixed" && Qt.colorEqual(KbdLight.fixedColor, modelData.c)
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: 17
                            color: modelData.c
                            border.width: on ? 3 : 0
                            border.color: Theme.fg
                            scale: sm.containsMouse ? 1.12 : 1
                            Behavior on scale { NumberAnimation { duration: 120 } }
                            MouseArea {
                                id: sm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KbdLight.setColor(parent.modelData.c)
                            }
                        }
                    }
                }
            }
        }
    }
}
