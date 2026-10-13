import QtQuick
import qs
import qs.components

Item {
    id: root

    property string icon: ""
    property string tip: ""
    property color iconColor: Theme.fg
    property bool active: false
    readonly property alias hovered: ma.containsMouse
    readonly property alias pressed: ma.pressed
    default property alias extra: holder.data

    signal clicked(var mouse)
    signal wheel(int delta)

    implicitWidth: Theme.sideButton
    implicitHeight: Theme.sideButton

    Rectangle {
        anchors.fill: parent
        radius: Theme.sideRadius
        color: root.active ? Qt.alpha(Theme.accent, 0.14) : Theme.surface
        opacity: root.active || ma.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Icon {
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? Theme.accent : root.iconColor
        font.pixelSize: 18
        scale: ma.pressed ? 0.85 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Item {
        id: holder
        anchors.fill: parent
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheel(w.angleDelta.y)
    }

    Tooltip {
        target: root
        text: root.tip
        shown: ma.containsMouse
    }
}
