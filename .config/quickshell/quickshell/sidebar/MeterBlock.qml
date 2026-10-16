import QtQuick
import qs
import qs.components

Item {
    id: root

    property string title: ""
    property string summary: ""
    property var values: []
    property var labels: []
    property var names: []
    property int rows: 1
    property real barHeight: 18
    property real warn: 0.75
    property real hot: 0.9
    property string tip: ""
    property int hover: -1
    readonly property int cols: Math.max(1, Math.ceil(values.length / rows))
    readonly property real gap: cols > 8 ? 1.5 : 3
    readonly property real barWidth: Math.min(5, (Theme.sideButton - 4 - (cols - 1) * gap) / cols)

    function tone(v) {
        return v >= hot ? Theme.red : v >= warn ? Theme.yellow : Theme.accent;
    }

    implicitWidth: Theme.sideButton
    implicitHeight: col.implicitHeight + 12

    Rectangle {
        anchors.fill: parent
        radius: Theme.sideRadius
        color: Theme.surface
        opacity: ma.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        y: 6
        spacing: 1

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hover >= 0 ? root.names[root.hover] ?? root.title : root.title
            color: Theme.dim
            font.pixelSize: 9
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hover >= 0 ? root.labels[root.hover] ?? "" : root.summary
            color: Theme.fg
            font.pixelSize: 11
        }

        Grid {
            id: grid
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 5
            columns: root.cols
            columnSpacing: root.gap
            rowSpacing: 3

            Repeater {
                model: root.values.length

                Item {
                    id: bar
                    required property int index
                    readonly property real v: Math.max(0, Math.min(1, root.values[index] ?? 0))

                    width: root.barWidth
                    height: root.barHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.surface2
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(width, parent.height * bar.v)
                        radius: width / 2
                        color: root.tone(bar.v)
                        opacity: root.hover < 0 || root.hover === bar.index ? 1 : 0.35
                        Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: m => {
            const p = mapToItem(grid, m.x, m.y);
            const c = Math.floor(p.x / (root.barWidth + root.gap));
            const r = Math.floor((p.y - grid.topPadding) / (root.barHeight + grid.rowSpacing));
            const i = r * root.cols + c;
            root.hover = c >= 0 && c < root.cols && r >= 0 && r < root.rows && i < root.values.length ? i : -1;
        }
        onExited: root.hover = -1
    }

    Tooltip {
        target: root
        shown: ma.containsMouse && root.tip !== ""
        text: root.tip
    }
}
