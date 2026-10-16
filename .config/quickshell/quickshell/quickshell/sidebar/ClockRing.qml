import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

Item {
    id: root
    implicitWidth: Theme.sideButton
    implicitHeight: col.implicitHeight + 8

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.sideRadius
        color: Theme.surface
        opacity: hover.hovered ? 1 : 0
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
            font.bold: true
            color: Theme.fg
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(Sky.now, "mm")
            font.pixelSize: 17
            font.bold: true
            color: Theme.accent
        }

        SkyBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.bottomMargin: 6
            implicitHeight: 70
            thickness: 4
            knob: 10
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Math.floor(Sky.progress * 100) + "%"
            font.pixelSize: 10
            font.bold: true
            color: Theme.dim
        }
    }

    Tooltip {
        target: root
        shown: hover.hovered
        text: Sky.now.toLocaleDateString(Qt.locale("en_US"), "dddd, MMMM d")
            + `\n${Math.floor(Sky.progress * 100)}% of the day gone`
            + `\n󰖜 ${Sky.fmt(Sky.sunrise)}   󰖛 ${Sky.fmt(Sky.sunset)}`
            + (Sky.isDay ? `\n☀ ${Sky.fmt(Sky.sunset - Sky.progress)} of sunlight left` : "")
    }
}
