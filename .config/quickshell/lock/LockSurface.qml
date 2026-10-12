import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

Item {
    id: root

    required property var lock
    property string wallpaper: ""
    property string userName: ""
    property string status: ""
    property string hint: "Digite sua senha"

    anchors.fill: parent
    focus: true

    Keys.onPressed: e => {
        if (root.lock.busy)
            return;
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            root.lock.submit();
        else if (e.key === Qt.Key_Tab && root.lock.nextUser)
            root.lock.nextUser();
        else if (e.key === Qt.Key_Escape)
            root.lock.buffer = "";
        else if (e.key === Qt.Key_Backspace)
            root.lock.buffer = e.modifiers & Qt.ControlModifier ? "" : root.lock.buffer.slice(0, -1);
        else if (e.text && e.text.charCodeAt(0) >= 32)
            root.lock.buffer += e.text;
        e.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Image {
        id: wall
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blur: 0.35
        blurMax: 48
        brightness: -0.2
        opacity: 0
        NumberAnimation on opacity { to: 1; duration: 700; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.14
        spacing: 6

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            Label {
                text: Qt.formatTime(Sky.now, "HH")
                font.pixelSize: 132
                color: Theme.fg
            }
            Label {
                text: ":"
                font.pixelSize: 132
                color: Theme.muted
                opacity: Sky.now.getSeconds() % 2 ? 0.4 : 1
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }
            Label {
                text: Qt.formatTime(Sky.now, "mm")
                font.pixelSize: 132
                color: Sky.body
            }
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            readonly property string d: Sky.now.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM")
            text: d.charAt(0).toUpperCase() + d.slice(1)
            font.pixelSize: 20
            font.bold: false
            color: Theme.dim
        }

        SkyBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 22
            vertical: false
            thickness: 6
            implicitWidth: 420
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 420
            Label { text: "00h"; font.pixelSize: 11; color: Theme.muted }
            Item { Layout.fillWidth: true }
            Label { text: `󰖜 ${Sky.fmt(Sky.sunrise)}  ·  ${Math.floor(Sky.progress * 100)}% do dia  ·  󰖛 ${Sky.fmt(Sky.sunset)}`; font.pixelSize: 11; color: Theme.dim }
            Item { Layout.fillWidth: true }
            Label { text: "24h"; font.pixelSize: 11; color: Theme.muted }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.12
        spacing: 12

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.userName
            font.pixelSize: 15
            color: Theme.dim
        }

        Rectangle {
            id: field
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 320
            implicitHeight: 52
            radius: 26
            color: Qt.alpha(Theme.bgSolid, 0.85)
            border.width: 1.5
            border.color: root.lock.failed ? Theme.red : root.lock.busy ? Theme.yellow : Qt.alpha(Theme.accent, 0.6)
            Behavior on border.color { ColorAnimation { duration: 200 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: Math.min(root.lock.buffer.length, 24)
                    Rectangle {
                        width: 9
                        height: 9
                        radius: 4.5
                        color: Theme.accent
                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                    }
                }
            }
            Label {
                anchors.centerIn: parent
                visible: root.lock.buffer.length === 0
                text: root.lock.busy ? "Verificando…" : root.lock.failed ? "Senha incorreta" : root.hint
                font.bold: false
                color: root.lock.failed ? Theme.red : Theme.muted
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 14; duration: 70 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -8; duration: 60 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
            }
            Connections {
                target: root.lock
                function onFailsChanged() {
                    shake.restart();
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            text: root.status
            font.pixelSize: 12
            font.bold: false
            color: Theme.dim
        }
    }
}
