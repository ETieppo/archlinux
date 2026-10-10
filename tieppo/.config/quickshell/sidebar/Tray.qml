import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

ColumnLayout {
    id: root

    required property var window

    spacing: 2
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        SideButton {
            id: btn
            required property SystemTrayItem modelData
            implicitHeight: 34
            tip: modelData.tooltipTitle || modelData.title || modelData.id

            onClicked: m => {
                if (m.button === Qt.LeftButton && !modelData.onlyMenu) {
                    modelData.activate();
                } else if (m.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (modelData.hasMenu) {
                    const p = btn.mapToItem(null, btn.width + 14, 0);
                    modelData.display(root.window, p.x, p.y);
                }
            }
            onWheel: d => modelData.scroll(d, false)

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: btn.modelData.icon
            }
        }
    }

    Sep {}
}
