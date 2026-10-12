import QtQuick
import Quickshell
import qs

LazyLoader {
    id: root

    required property Item target
    property string text: ""
    property bool shown: false
    property bool below: false

    active: shown && text !== ""

    PopupWindow {
        anchor.item: root.target
        anchor.rect.x: root.below ? root.target.width / 2 : root.target.width + 14
        anchor.rect.y: root.below ? root.target.height + 8 : root.target.height / 2
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.gravity: root.below ? Edges.Bottom : Edges.Right
        visible: true
        color: "transparent"
        implicitWidth: label.implicitWidth + (root.below ? 12 : 22)
        implicitHeight: label.implicitHeight + 14

        Rectangle {
            anchors.fill: parent
            radius: root.below ? 10 : 9
            color: root.below ? Theme.slate1 : Theme.bgSolid
            border.width: root.below ? 0 : 1
            border.color: Qt.alpha(Theme.accent, 0.35)

            Text {
                id: label
                anchors.centerIn: parent
                text: root.text
                color: root.below ? Theme.wbFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: root.below ? 16 : 13
                lineHeight: 1.15
            }
        }
    }
}
