import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs
import qs.components

Rectangle {
    id: root

    required property var modelData
    property bool popup: true
    readonly property var n: modelData
    readonly property bool critical: n.urgency === NotificationUrgency.Critical
    readonly property int timeout: n.expireTimeout > 0 ? n.expireTimeout : critical ? 0 : 6000

    implicitWidth: 340
    implicitHeight: body.implicitHeight + 24
    radius: 14
    color: Theme.bgSolid
    border.width: 1
    border.color: critical ? Theme.red : Qt.alpha(Theme.accent, ma.containsMouse ? 0.6 : 0.3)
    Behavior on border.color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            const def = root.n.actions.find(a => a.identifier === "default");
            if (m.button === Qt.LeftButton && def)
                def.invoke();
            else if (root.popup && m.button === Qt.LeftButton)
                Notifs.hide(root.n);
            else
                root.n.dismiss();
        }
    }

    RowLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 42
            implicitHeight: 42
            radius: 10
            color: Theme.surface
            visible: img.status === Image.Ready || appIcon.status === Image.Ready

            Image {
                id: img
                anchors.fill: parent
                source: root.n.image
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(84, 84)
                asynchronous: true
            }
            IconImage {
                id: appIcon
                anchors.centerIn: parent
                implicitSize: 28
                visible: img.status !== Image.Ready
                source: root.n.appIcon ? (root.n.appIcon.startsWith("/") || root.n.appIcon.includes("://") ? root.n.appIcon : Quickshell.iconPath(root.n.appIcon, true)) : ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: root.n.appName || "Notification"
                    color: root.critical ? Theme.red : Theme.accent
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                Icon {
                    text: "󰅖"
                    font.pixelSize: 14
                    color: close.containsMouse ? Theme.red : Theme.dim
                    MouseArea {
                        id: close
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.n.dismiss()
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                text: root.n.summary
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.n.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                font.bold: false
                font.pixelSize: 13
                color: Theme.dim
            }
            RowLayout {
                Layout.topMargin: 6
                visible: actions.count > 0
                spacing: 6
                Repeater {
                    id: actions
                    model: root.n.actions.filter(a => a.identifier !== "default")
                    Rectangle {
                        required property var modelData
                        implicitWidth: al.implicitWidth + 18
                        implicitHeight: 24
                        radius: 8
                        color: am.containsMouse ? Theme.surface2 : Theme.surface
                        Label {
                            id: al
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: am
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: progress
        visible: root.popup && root.timeout > 0
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 1
        anchors.leftMargin: 14
        height: 2
        radius: 1
        color: Qt.alpha(Theme.accent, 0.5)
        width: root.width - 28

        NumberAnimation on width {
            id: countdown
            running: progress.visible
            paused: ma.containsMouse
            to: 0
            duration: root.timeout
            onFinished: Notifs.hide(root.n)
        }
    }
}
