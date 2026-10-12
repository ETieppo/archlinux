import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

Item {
    id: root

    implicitWidth: 40
    implicitHeight: col.implicitHeight + 8

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.surface
        opacity: hover.hovered ? 0.8 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    ColumnLayout {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4
        spacing: 0

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(Sky.now, "HH")
            font.pixelSize: 17
            color: Theme.fg
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -4
            text: Qt.formatTime(Sky.now, "mm")
            font.pixelSize: 17
            color: Sky.body
            Behavior on color { ColorAnimation { duration: 1000 } }
        }

        SkyBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            implicitHeight: 74
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Math.floor(Sky.progress * 100) + "%"
            font.pixelSize: 10
            color: Theme.dim
        }
    }

    Tooltip {
        target: root
        shown: hover.hovered
        text: Sky.now.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM")
            + `\n${Math.floor(Sky.progress * 100)}% do dia já foi`
            + `\n󰖜 ${Sky.fmt(Sky.sunrise)}   󰖛 ${Sky.fmt(Sky.sunset)}`
            + (Sky.isDay ? `\n☀ faltam ${Sky.fmt(Sky.sunset - Sky.progress)} de sol` : "")
    }
}
