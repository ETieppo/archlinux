import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components

Item {
    id: root

    readonly property var apps: [...new Set(ToplevelManager.toplevels.values.map(t => t.appId).filter(id => id))]
    readonly property string focused: ToplevelManager.activeToplevel?.appId ?? ""

    function entry(id) {
        const l = id.toLowerCase();
        return DesktopEntries.applications.values.find(e => e.startupClass?.toLowerCase() === l || e.id.toLowerCase() === l)
            ?? DesktopEntries.heuristicLookup(id)
            ?? DesktopEntries.applications.values.find(e => e.id.toLowerCase().startsWith(l.split(/[-.]/)[0]));
    }

    visible: apps.length > 0
    Layout.leftMargin: 5
    Layout.rightMargin: 5
    implicitHeight: Theme.wbHeight
    implicitWidth: row.implicitWidth + 24

    Underline {
        anchors.fill: parent
    }

    Row {
        id: row
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        spacing: 8

        Repeater {
            model: root.apps

            Item {
                id: app
                required property string modelData
                readonly property bool active: root.focused === modelData

                width: 16
                height: 16

                IconImage {
                    anchors.fill: parent
                    source: Quickshell.iconPath(root.entry(app.modelData)?.icon ?? "", "application-x-executable")
                    opacity: app.active ? 1 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 2
                    width: app.active ? 8 : 0
                    height: 2
                    radius: 1
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
            }
        }
    }

    HoverHandler {
        id: hover
    }

    Tooltip {
        target: root
        shown: hover.hovered
        below: true
        text: root.apps.map(id => root.entry(id)?.name ?? id).join("  ·  ")
    }
}
