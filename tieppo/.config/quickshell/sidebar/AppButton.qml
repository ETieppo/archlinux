import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs

SideButton {
    id: root

    required property string modelData
    readonly property var entry: {
        const id = modelData.toLowerCase();
        return DesktopEntries.applications.values.find(e => e.startupClass?.toLowerCase() === id || e.id.toLowerCase() === id)
            ?? DesktopEntries.heuristicLookup(modelData)
            ?? DesktopEntries.applications.values.find(e => e.id.toLowerCase().startsWith(id.split(/[-.]/)[0]));
    }
    readonly property var wins: ToplevelManager.toplevels.values.filter(t => t.appId === modelData)
    readonly property bool focused: wins.some(w => w.activated)

    tip: (entry?.name ?? modelData) + (wins.length > 1 ? `  ·  ${wins.length} janelas` : "")
    active: focused

    scale: 0
    Component.onCompleted: scale = 1
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

    onClicked: m => {
        if (m.button === Qt.MiddleButton) {
            entry?.execute();
            return;
        }
        const i = wins.findIndex(w => w.activated);
        if (m.button === Qt.RightButton)
            (wins[i] ?? wins[wins.length - 1])?.close();
        else
            wins[(i + 1) % wins.length]?.activate();
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 26
        source: root.entry ? Quickshell.iconPath(root.entry.icon, "application-x-executable") : ""
        scale: root.pressed ? 0.82 : root.hovered ? 1.12 : 1
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
    }

    Column {
        x: -8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        visible: !root.focused
        Repeater {
            model: Math.min(3, root.wins.length)
            Rectangle {
                width: 3
                height: 3
                radius: 1.5
                color: Theme.fg
            }
        }
    }
    Rectangle {
        x: -8
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: root.focused ? 22 : 0
        radius: 1.5
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
    }
}
