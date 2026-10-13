import QtQuick
import Quickshell.Services.Notifications
import qs
import qs.components

Seg {
    id: root

    readonly property var list: Notifs.all
    readonly property var latest: list.length ? list[list.length - 1] : null
    property real at: 0
    property real now: Date.now()
    readonly property real age: now - at

    onLatestChanged: at = Date.now()

    progress: Notifs.dnd || !latest ? 0 : Math.max(0, 1 - age / 60000)
    tint: latest?.urgency === NotificationUrgency.Critical ? Theme.red : latest?.urgency === NotificationUrgency.Low ? Theme.dim : Theme.accent
    tip: (Notifs.dnd ? "Do not disturb is on\n\n" : "") + (list.length ? list.slice(-5).reverse().map(n => `${n.appName || "app"} · ${n.summary}`).join("\n") : "No notifications") + "\n\n󰐊 click: do not disturb · 󰍽 right-click: clear"

    Timer {
        interval: 1000
        repeat: true
        running: root.latest !== null && root.age < 61000
        onTriggered: root.now = Date.now()
    }

    Icon {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: Notifs.dnd ? "󰂛" : root.latest ? "󰂚" : "󰂜"
        font.pixelSize: 14
        color: Notifs.dnd ? Theme.muted : root.latest ? root.tint : Theme.muted
    }

    Label {
        anchors.left: glyph.right
        anchors.leftMargin: 8
        anchors.right: count.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        font.pixelSize: 12
        textFormat: Text.StyledText
        color: root.latest && !Notifs.dnd ? Theme.fg : Theme.dim
        text: Notifs.dnd ? "do not disturb" : root.latest ? `${root.latest.appName || "app"}<font color="${Theme.dim}"> · ${root.latest.summary}</font>` : "no notifications"
    }

    Label {
        id: count
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 11
        color: Theme.dim
        text: root.list.length > 1 ? `${root.list.length}` : ""
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => m.button === Qt.RightButton ? Notifs.clearAll() : Notifs.dnd = !Notifs.dnd
    }
}
