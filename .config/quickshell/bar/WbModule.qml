import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property string text: ""
    property int minChars: 0
    property int padL: 3
    property int padR: 0
    property int minWidth: 50
    property bool underline: true
    property bool bold: true
    property color color: Theme.wbFg
    property string tip: ""
    property bool marginsOn: true
    readonly property alias hovered: ma.containsMouse

    signal clicked(var mouse)
    signal wheel(int delta)

    Layout.leftMargin: marginsOn ? 5 : 0
    Layout.rightMargin: marginsOn ? 5 : 0
    implicitHeight: Theme.wbHeight
    implicitWidth: padL + padR + Math.max(minWidth, minChars * Math.ceil(fm.advanceWidth("0")), label.implicitWidth)

    FontMetrics {
        id: fm
        font: label.font
    }

    Underline {
        anchors.fill: parent
        visible: root.underline
    }

    Text {
        id: label
        x: root.padL + (root.width - root.padL - root.padR - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.color
        font.family: Theme.font
        font.pixelSize: 16
        font.bold: root.bold
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheel(w.angleDelta.y)
    }

    Tooltip {
        target: root
        text: root.tip
        shown: ma.containsMouse
        below: true
    }
}
