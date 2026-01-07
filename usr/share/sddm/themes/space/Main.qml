import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import QtQuick.Particles 2.15

Item {
    id: root
    width: 1920
    height: 1080

    property bool loginFailed: false

    Image {
        id: background
        anchors.fill: parent
        source: "491593.jpg"
        fillMode: Image.PreserveAspectCrop

        FastBlur {
            anchors.fill: parent
            source: background
            radius: blurSlider.value
            opacity: 0.7

            Behavior on radius {
                NumberAnimation {
                    duration: 1000
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: "#000000"
                }
            }
            opacity: 0.6
        }
    }

    Rectangle {
        id: loginPanel
        width: 450
        height: 400
        anchors.centerIn: parent
        color: "#101010"
        radius: 20
        opacity: 0.95

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 0
            radius: 20
            samples: 41
            color: loginFailed ? "#40ff0000" : "#4000ffff"
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 2
            border.color: loginFailed ? "#ff0000" : "#00ffff"

            Behavior on border.color {
                ColorAnimation {
                    duration: 300
                }
            }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: !loginFailed
                NumberAnimation {
                    to: 0.1
                    duration: 2000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: 1
                    duration: 6000
                    easing.type: Easing.InOutQuad
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width * 0.8
            spacing: 30

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Text {
                    text: "󰣇"
                    font.pixelSize: 60
                    color: "#00ffff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    id: usernameText
                    text: (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser.charAt(0).toUpperCase() + userModel.lastUser.slice(1).toLowerCase() : "User"
                    font.pixelSize: 18
                    color: "#fff"
                    font.bold: true
                    font.family: "Monospace"
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ColumnLayout {
                spacing: 5
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true

                Text {
                    text: "SENHA"
                    font.pixelSize: 12
                    color: "#888"
                    font.family: "Monospace"
                    Layout.alignment: Qt.AlignHCenter
                }

                TextField {
                    id: passwordField
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 50
                    Layout.alignment: Qt.AlignHCenter
                    placeholderText: "Digite sua senha..."
                    echoMode: TextInput.Password
                    font.pixelSize: 16
                    font.family: "Monospace"
                    color: "#fff"
                    selectionColor: "#00ffff"
                    selectedTextColor: "#000"

                    background: Rectangle {
                        color: "#1a1a1a"
                        border.width: 1
                        border.color: passwordField.activeFocus ? "#00ffff" : "#444"
                        radius: 8
                    }

                    onTextChanged: {
                        typingEffect.restart();
                        loginFailed = false;
                    }

                    Keys.onReturnPressed: {
                        if (text.length > 0) {
                            loginButton.clicked();
                        }
                    }

                    Keys.onEnterPressed: {
                        if (text.length > 0) {
                            loginButton.clicked();
                        }
                    }

                    Component.onCompleted: {
                        forceActiveFocus();
                    }
                }

                Rectangle {
                    id: typingEffect
                    Layout.preferredWidth: passwordField.width
                    Layout.preferredHeight: 2
                    Layout.alignment: Qt.AlignHCenter
                    color: "#00ffff"
                    scale: 0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    function restart() {
                        scale = 1;
                        scale = 0;
                    }
                }
            }

            Button {
                id: loginButton
                Layout.preferredWidth: 300
                Layout.preferredHeight: 50
                Layout.alignment: Qt.AlignHCenter
                text: "LOGIN"
                font.pixelSize: 16
                font.bold: true
                font.family: "Monospace"

                background: Rectangle {
                    color: loginButton.down ? "#008888" : "#00aaaa"
                    radius: 8
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: loginButton.down ? "#008888" : "#00aaaa"
                        }
                        GradientStop {
                            position: 4.0
                            color: loginButton.down ? "#006666" : "#008888"
                        }
                    }
                }

                contentItem: Text {
                    text: loginButton.text
                    font: loginButton.font
                    color: "#fff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.background.radius
                    color: "#4000ffff"
                    opacity: loginButton.hovered ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }

                onClicked: {
                    if (typeof sddm === "undefined") {
                        return;
                    }
                    sddm.login(userModel.lastUser, passwordField.text, sessionModel.lastIndex);
                }
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                text: "Arch Linux • " + Qt.formatDateTime(new Date(), "hh:mm:ss")
                font.pixelSize: 10
                color: "#666"
                font.family: "Monospace"

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {
                        parent.text = "Arch Linux • " + Qt.formatDateTime(new Date(), "hh:mm:ss");
                    }
                }
            }
        }
    }

    Slider {
        id: blurSlider
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 20
        }
        width: 200
        from: 0
        to: 100
        value: 30
        visible: false

        background: Rectangle {
            color: "#40000000"
            radius: 5
        }

        handle: Rectangle {
            x: blurSlider.leftPadding + blurSlider.visualPosition * (blurSlider.availableWidth - width)
            y: blurSlider.topPadding + blurSlider.availableHeight / 2 - height / 2
            width: 20
            height: 20
            radius: 10
            color: "#00ffff"
        }
    }

    SequentialAnimation {
        id: loginAnimation
        PropertyAnimation {
            target: loginPanel
            property: "scale"
            to: 0.95
            duration: 100
        }
        PropertyAnimation {
            target: loginPanel
            property: "scale"
            to: 1
            duration: 100
        }
        PropertyAnimation {
            target: loginPanel
            property: "opacity"
            to: 0
            duration: 300
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            loginFailed = true;
            passwordField.clear();
            passwordField.forceActiveFocus();
        }
    }
}
