import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components

Scope {
    id: root

    PolkitAgent {
        id: agent
    }

    readonly property var flow: agent.flow

    PanelWindow {
        id: win

        visible: agent.isActive && root.flow !== null
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-polkit"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: Qt.rgba(0, 0, 0, 0.55)

        onVisibleChanged: if (visible) {
            pass.text = "";
            pass.forceActiveFocus();
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 440
            height: col.implicitHeight + 48
            radius: 20
            color: Theme.bgSolid
            border.width: 1
            border.color: Qt.alpha(root.flow?.failed ? Theme.red : Theme.accent, 0.4)

            scale: win.visible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                RowLayout {
                    spacing: 14
                    Rectangle {
                        implicitWidth: 46
                        implicitHeight: 46
                        radius: 14
                        color: Qt.alpha(Theme.accent, 0.12)
                        IconImage {
                            id: pkIcon
                            anchors.centerIn: parent
                            implicitSize: 28
                            source: root.flow?.iconName ? Quickshell.iconPath(root.flow.iconName, true) : ""
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: pkIcon.status !== Image.Ready
                            text: "󰌾"
                            color: Theme.accent
                            font.pixelSize: 22
                        }
                    }
                    ColumnLayout {
                        spacing: 2
                        Label {
                            text: "Authentication required"
                            color: Theme.accent
                            font.pixelSize: 16
                        }
                        Label {
                            text: root.flow?.actionId ?? ""
                            color: Theme.muted
                            font.pixelSize: 11
                            font.bold: false
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: root.flow?.message ?? ""
                    wrapMode: Text.Wrap
                    font.bold: false
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 12
                    color: Theme.surface
                    border.width: 1
                    border.color: pass.activeFocus ? Qt.alpha(Theme.accent, 0.5) : "transparent"

                    TextInput {
                        id: pass
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 15
                        enabled: root.flow?.isResponseRequired ?? false
                        onAccepted: if (root.flow?.isResponseRequired) {
                            root.flow.submit(text);
                            text = "";
                        }
                        Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                        Text {
                            visible: !pass.text
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.flow?.inputPrompt || "Password").replace(/:\s*$/, "")
                            color: Theme.muted
                            font: pass.font
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.flow?.failed ? "Senha incorreta, tente de novo" : (root.flow?.supplementaryMessage ?? "")
                    color: root.flow?.failed || root.flow?.supplementaryIsError ? Theme.red : Theme.dim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8
                    Repeater {
                        model: [
                            { label: "Cancel", primary: false },
                            { label: "Authenticate", primary: true }
                        ]
                        Rectangle {
                            required property var modelData
                            implicitWidth: bl.implicitWidth + 28
                            implicitHeight: 34
                            radius: 10
                            color: modelData.primary ? Theme.accent : bm.containsMouse ? Theme.surface2 : Theme.surface
                            Label {
                                id: bl
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                color: parent.modelData.primary ? Theme.bgSolid : Theme.fg
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: bm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: parent.modelData.primary ? pass.accepted() : root.flow?.cancelAuthenticationRequest()
                            }
                        }
                    }
                }
            }
        }
    }
}
