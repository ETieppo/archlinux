import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

PopupWindow {
    id: root

    required property Item target
    property date shown: new Date()

    anchor.item: target
    anchor.rect.x: target.width / 2
    anchor.rect.y: target.height + 8
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.gravity: Edges.Bottom
    color: "transparent"
    implicitWidth: 280
    implicitHeight: col.implicitHeight + 28

    onVisibleChanged: if (visible) shown = new Date()

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.bgSolid
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.35)

        WheelHandler {
            onWheel: e => root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() + (e.angleDelta.y > 0 ? -1 : 1), 1)
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Icon {
                    text: "󰅁"
                    color: Theme.dim
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() - 1, 1)
                    }
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale("pt_BR").standaloneMonthName(root.shown.getMonth()) + " " + root.shown.getFullYear()
                    color: Theme.accent
                    font.capitalization: Font.Capitalize
                }
                Icon {
                    text: "󰅂"
                    color: Theme.dim
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() + 1, 1)
                    }
                }
            }

            DayOfWeekRow {
                Layout.fillWidth: true
                locale: Qt.locale("pt_BR")
                delegate: Label {
                    required property string shortName
                    text: shortName.slice(0, 3)
                    color: Theme.dim
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            MonthGrid {
                Layout.fillWidth: true
                month: root.shown.getMonth()
                year: root.shown.getFullYear()
                locale: Qt.locale("pt_BR")
                delegate: Item {
                    required property var model
                    readonly property bool today: model.today
                    implicitWidth: 32
                    implicitHeight: 28

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: parent.today ? Theme.accent : "transparent"
                    }
                    Label {
                        anchors.centerIn: parent
                        text: parent.model.day
                        font.pixelSize: 13
                        color: parent.today ? Theme.bgSolid : parent.model.month === root.shown.getMonth() ? Theme.fg : Theme.muted
                    }
                }
            }
        }
    }
}
