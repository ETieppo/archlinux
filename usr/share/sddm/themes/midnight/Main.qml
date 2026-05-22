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
    property string currentUser: {
        if (typeof userModel === "undefined")
            return "";
        if (userModel.lastUser && userModel.lastUser.length > 0)
            return userModel.lastUser;
        if (userModel.count > 0)
            return userModel.data(userModel.index(0, 0), Qt.UserRole + 1);
        return "";
    }

    Image {
        id: background
        anchors.fill: parent
        source: "1337139.png"
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

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 30

        ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true

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
                    color: "transparent"
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
                    color: "transparent"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.background.radius
                    color: "transparent"
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
                    sddm.login(root.currentUser, passwordField.text, sessionModel.lastIndex);
                }
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
            }
        }
    }

    TextField {
        id: passwordField
        anchors.bottom: root.bottom
        anchors.bottomMargin: 50
        anchors.horizontalCenter: root.horizontalCenter
        width: 400
        height: 50
        cursorVisible: false
        cursorDelegate: Item {}
        cursorPosition: 0
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        echoMode: TextInput.Password
        font.pixelSize: 16
        font.family: "Monospace"
        color: "#fff"
        selectionColor: "#00ffff"
        selectedTextColor: "#000"

        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 0
            radius: 20
            samples: 41
            color: loginFailed ? "#40ff0000" : "#4000ffff"
        }

        background: Rectangle {
            color: "transparent"
            radius: 8
        }

        Rectangle {
            color: "#1a1a1a"
            border.width: 1
            height: 1
            width: 400
            border.color: passwordField.activeFocus ? "#00ffff" : "#444"
            radius: 8
        }

        onTextChanged: {
            if (typeof typingEffect !== "undefined") {
                typingEffect.restart();
            }
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
