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
    property var layout: []
    property int maxColumns: 0
    property real groupGap: 6
    property real barHeight: 18
    property real warn: 0.75
    property real hot: 0.9
    property string tip: ""
    property int hover: -1
    property var _bars: ({})
    readonly property int count: values.length
    readonly property var groups: (layout.length ? layout : [split(Array.from({ length: count }, (_, i) => i), rows)]).map(g => g.reduce((rows, r) => rows.concat(wrap(r)), []))
    readonly property int cols: Math.max(1, ...groups.reduce((lengths, g) => lengths.concat(g.map(r => r.length)), []))
    readonly property real gap: cols > 8 ? 1.5 : 3
    readonly property real barWidth: Math.min(5, (Theme.sideButton - 4 - (cols - 1) * gap) / cols)

    function split(items, parts) {
        const per = Math.max(1, Math.ceil(items.length / Math.max(1, parts)));
        return Array.from({ length: Math.ceil(items.length / per) }, (_, i) => items.slice(i * per, (i + 1) * per));
    }

    function wrap(row) {
        return maxColumns > 0 && row.length > maxColumns ? split(row, Math.ceil(row.length / maxColumns)) : [row];
    }

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

        Column {
            id: bars
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 5
            spacing: root.groupGap

            Repeater {
                model: root.groups

                Column {
                    id: group
                    required property var modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3

                    Repeater {
                        model: group.modelData

                        Row {
                            id: line
                            required property var modelData
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: root.gap

                            Repeater {
                                model: line.modelData

                                Item {
                                    id: bar
                                    required property int modelData
                                    readonly property int slot: modelData
                                    readonly property real v: Math.max(0, Math.min(1, root.values[slot] ?? 0))

                                    width: root.barWidth
                                    height: root.barHeight
                                    Component.onCompleted: root._bars[slot] = bar
                                    Component.onDestruction: {
                                        if (root._bars[slot] === bar)
                                            delete root._bars[slot];
                                    }

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
                                        opacity: root.hover < 0 || root.hover === bar.slot ? 1 : 0.35
                                        Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                    }
                                }
                            }
                        }
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
            const slack = root.gap / 2;
            const hit = Object.entries(root._bars).find(([, b]) => {
                const p = b.mapFromItem(ma, m.x, m.y);
                return p.x >= -slack && p.x < b.width + slack && p.y >= -slack && p.y < b.height + slack;
            });
            root.hover = hit ? Number(hit[0]) : -1;
        }
        onExited: root.hover = -1
    }

    Tooltip {
        target: root
        shown: ma.containsMouse && root.tip !== ""
        text: root.tip
    }
}
