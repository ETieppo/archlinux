import QtQuick
import qs
import qs.components

Seg {
    id: root

    readonly property int hold: 3600000
    readonly property var items: [
        { name: "Screen brightness", at: Ui.screenManualAt },
        { name: "Night light", at: Ui.nightOffAt },
        { name: "Keyboard light", at: KbdLight.since }
    ]
    readonly property var manual: items.filter(i => i.at > 0)
    property real now: Date.now()
    readonly property real remaining: manual.length ? Math.max(0, Math.min(...manual.map(i => i.at + hold)) - now) : 0

    progress: manual.length ? remaining / hold : 1
    tint: manual.length ? Theme.yellow : Theme.accent
    fillOpacity: manual.length ? 1 : 0.35
    tip: items.map(i => `${i.name} · ` + (i.at > 0 ? `manual, auto again in ${Term.fmt(Math.max(0, i.at + hold - now))}` : "auto")).join("\n") + (manual.length ? "\n\n󰐊 click: back to auto now" : "")

    Timer {
        interval: 1000
        repeat: true
        running: root.manual.length > 0
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    Icon {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: root.manual.length ? "\u{f0a4f}" : "󰁪"
        font.pixelSize: 14
        color: root.tint
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Label {
        anchors.left: glyph.right
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 12
        color: root.manual.length ? Theme.yellow : Theme.dim
        text: root.manual.length ? Term.fmt(root.remaining) : "auto"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.manual.length ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: Ui.restoreAuto()
    }
}
