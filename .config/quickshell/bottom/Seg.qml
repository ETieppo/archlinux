import QtQuick
import qs
import qs.components

Item {
    id: root

    property real progress: 0
    property color tint: Theme.accent
    property real fillOpacity: 1
    property bool busy: false
    property bool knob: false
    property string tip: ""
    readonly property alias track: track
    readonly property alias hovered: hover.hovered
    default property alias content: line.data

    implicitHeight: Theme.bottomHeight

    HoverHandler {
        id: hover
    }

    Item {
        id: line
        x: 0
        y: 4
        width: parent.width
        height: 17
    }

    Item {
        id: track
        x: 0
        y: 24
        width: parent.width
        height: 3

        Rectangle {
            anchors.fill: parent
            radius: 1.5
            color: Theme.surface2
        }

        Rectangle {
            id: fill
            width: parent.width * Math.max(0, Math.min(1, root.progress))
            height: parent.height
            radius: 1.5
            color: root.tint
            opacity: root.fillOpacity
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 400 } }
            Behavior on opacity { NumberAnimation { duration: 800 } }
        }

        Item {
            anchors.fill: parent
            clip: true
            visible: root.busy

            Rectangle {
                id: glint
                width: Math.max(40, parent.width * 0.3)
                height: parent.height
                radius: 1.5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.alpha(root.tint, 0.9) }
                    GradientStop { position: 1; color: "transparent" }
                }

                NumberAnimation on x {
                    running: root.busy
                    loops: Animation.Infinite
                    from: -glint.width
                    to: track.width
                    duration: 1400
                    easing.type: Easing.InOutSine
                }
            }
        }

        Rectangle {
            x: fill.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: root.knob && root.hovered ? 9 : 0
            height: width
            radius: width / 2
            color: root.tint
            Behavior on width { NumberAnimation { duration: 140 } }
        }
    }

    Tooltip {
        target: root
        text: root.tip
        shown: root.hovered
        above: true
    }
}
