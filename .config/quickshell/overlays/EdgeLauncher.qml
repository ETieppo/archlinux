import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components

PanelWindow {
    id: root

    readonly property bool open: Ui.launcherOpen
    readonly property int slots: 9
    readonly property int slotHeight: 60
    readonly property int iconSize: 40
    readonly property int drawerWidth: 92
    readonly property int queryHeight: 44
    readonly property int heroHeight: 34
    readonly property var results: engine.results
    readonly property int appOffset: results.length && results[0].kind !== "app" ? 1 : 0
    readonly property var hero: appOffset ? results[0] : null
    readonly property var appResults: results.slice(appOffset)
    readonly property var current: results[currentIndex] ?? null
    readonly property bool noMatch: query.trim() !== "" && results.length === 0
    readonly property int selectedSlot: currentIndex - appOffset
    property real reveal: open ? 1 : 0
    property string query: ""
    property int currentIndex: 0
    property bool normalMode: false

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: reveal > 0

    Behavior on reveal { NumberAnimation { duration: root.open ? 240 : 170; easing.type: root.open ? Easing.OutCubic : Easing.InCubic } }

    onOpenChanged: if (open) prepare()
    Component.onCompleted: if (open) prepare()

    function prepare() {
        input.text = "";
        currentIndex = 0;
        normalMode = false;
        input.forceActiveFocus();
    }
    onQueryChanged: currentIndex = 0

    function close() {
        Ui.launcherOpen = false;
    }

    function activate(item) {
        engine.activate(item);
        close();
    }

    function move(delta) {
        if (results.length)
            currentIndex = Math.max(0, Math.min(results.length - 1, currentIndex + delta));
    }

    function cycle(delta) {
        if (results.length)
            currentIndex = (currentIndex + delta + results.length) % results.length;
    }

    function navigateByKey(key) {
        if (key === Qt.Key_Down || key === Qt.Key_Right)
            move(1);
        else if (key === Qt.Key_Up || key === Qt.Key_Left)
            move(-1);
        else if (key === Qt.Key_Tab)
            cycle(1);
        else if (key === Qt.Key_Backtab)
            cycle(-1);
        else if (key === Qt.Key_Return || key === Qt.Key_Enter)
            activate(current);
        else
            return false;
        return true;
    }

    function handleInsertKey(key) {
        if (key === Qt.Key_Escape) {
            normalMode = true;
            return true;
        }
        return navigateByKey(key);
    }

    function handleNormalKey(key) {
        if (key === Qt.Key_Escape)
            close();
        else if (key === Qt.Key_J || key === Qt.Key_L)
            move(1);
        else if (key === Qt.Key_K || key === Qt.Key_H)
            move(-1);
        else if (key === Qt.Key_I || key === Qt.Key_A || key === Qt.Key_Slash)
            normalMode = false;
        else
            navigateByKey(key);
        return true;
    }

    function magnification(slotIndex) {
        const distance = Math.abs(slotIndex - selectedSlot);
        return distance === 0 ? 1.3 : distance === 1 ? 1.08 : 1;
    }

    LauncherEngine {
        id: engine
        query: root.query
        limit: root.slots
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.open && root.visible
        onCleared: root.close()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: drawer
        readonly property real contentHeight: root.queryHeight + (root.hero ? root.heroHeight : 0) + Math.max(1, root.appResults.length) * root.slotHeight + 18

        width: root.drawerWidth
        height: contentHeight + 2 * Theme.fillet
        x: parent.width - width * root.reveal
        anchors.verticalCenter: parent.verticalCenter
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        EdgeShape {
            anchors.fill: parent
            edge: "right"
            fillet: Theme.fillet
            radius: 22
            fill: Theme.bgSolid
            stroke: Qt.alpha(Theme.accent, 0.55)
            layer.enabled: true
            layer.effect: NeonGlow {
                strength: 0.45
            }
        }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Repeater {
                model: Math.max(0, Math.floor((drawer.height - 2 * Theme.fillet - 40) / 9))

                Rectangle {
                    required property int index
                    width: index % 5 === 0 ? 6 : 3
                    height: 1
                    anchors.right: parent.right
                    color: Qt.alpha(Theme.accent, index % 5 === 0 ? 0.45 : 0.18)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: Theme.fillet
            anchors.bottomMargin: Theme.fillet
            onClicked: input.forceActiveFocus()
        }

        Item {
            id: queryBox
            x: 10
            y: Theme.fillet + 10
            width: parent.width - 20
            height: root.queryHeight - 10

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Qt.alpha(Theme.accent, 0.05)
                border.width: 1
                border.color: root.noMatch ? Qt.alpha(Theme.red, 0.7) : Qt.alpha(Theme.accent, input.text ? 0.8 : 0.35)
                Behavior on border.color { ColorAnimation { duration: 160 } }
                layer.enabled: true
                layer.effect: NeonGlow {
                    glowColor: root.noMatch ? Theme.red : Theme.accent
                    strength: input.text ? 0.6 : 0.25
                }
            }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: contentWidth > width ? TextInput.AlignRight : TextInput.AlignHCenter
                clip: true
                color: root.noMatch ? Theme.red : Theme.accent
                selectionColor: Qt.alpha(Theme.accent, 0.35)
                font.family: Theme.font
                font.pixelSize: 13
                font.bold: true
                focus: true
                readOnly: root.normalMode
                onTextChanged: root.query = text

                cursorDelegate: Rectangle {
                    width: root.normalMode ? 8 : 2
                    height: 16
                    radius: 1
                    color: Theme.accent

                    SequentialAnimation on opacity {
                        running: !root.normalMode && root.open
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.15; duration: 520; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutSine }
                    }
                }

                Keys.onPressed: e => {
                    if (e.key === Qt.Key_S && e.modifiers & Qt.ControlModifier) {
                        Ui.cycleLauncherStyle();
                        e.accepted = true;
                        return;
                    }
                    e.accepted = root.normalMode ? root.handleNormalKey(e.key) : root.handleInsertKey(e.key);
                }
            }
        }

        Rectangle {
            x: 10
            y: queryBox.y + queryBox.height + 6
            width: parent.width - 20
            height: root.heroHeight - 8
            visible: root.hero !== null
            radius: 10
            color: root.currentIndex === 0 && root.hero ? Qt.alpha(Theme.accent, 0.18) : Theme.surface
            Behavior on color { ColorAnimation { duration: 140 } }

            Label {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                horizontalAlignment: Text.AlignHCenter
                text: root.hero?.kind === "calc" ? root.hero.name : "↵"
                color: Theme.accent
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activate(root.hero)
            }
        }

        Column {
            id: dock
            x: 0
            y: Theme.fillet + root.queryHeight + (root.hero ? root.heroHeight : 0) + 8
            width: parent.width

            Repeater {
                model: root.appResults

                Item {
                    id: slot
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.selectedSlot
                    readonly property string iconPath: engine.iconFor(modelData?.entry?.icon ?? "")
                    property real entrance: 0

                    width: dock.width
                    height: root.slotHeight
                    opacity: entrance

                    SequentialAnimation on entrance {
                        running: true
                        PauseAnimation { duration: slot.index * 20 }
                        NumberAnimation { from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 4
                        width: 4
                        height: slot.selected ? 22 : 4
                        radius: 2
                        color: Theme.accent
                        opacity: slot.selected ? 1 : 0
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        layer.enabled: true
                        layer.effect: NeonGlow {
                            strength: 1
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (1 - slot.entrance) * 20 - (slot.selected ? 4 : 0)
                        width: root.iconSize
                        height: root.iconSize
                        scale: root.magnification(slot.index)
                        layer.enabled: slot.selected
                        layer.effect: NeonGlow {
                            strength: 0.55
                        }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        IconImage {
                            anchors.fill: parent
                            visible: slot.iconPath !== ""
                            source: slot.iconPath
                            asynchronous: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: slot.iconPath === ""
                            radius: 12
                            color: Theme.surface2

                            Label {
                                anchors.centerIn: parent
                                text: (slot.modelData?.name ?? "").charAt(0).toUpperCase()
                                color: Theme.accent
                                font.pixelSize: 17
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.currentIndex = slot.index + root.appOffset
                        onClicked: root.activate(slot.modelData)
                    }
                }
            }
        }
    }

    Rectangle {
        id: nameTag
        readonly property bool shown: root.current?.kind === "app" && root.reveal > 0.9

        x: drawer.x - width - 10
        y: drawer.y + dock.y + root.selectedSlot * root.slotHeight + (root.slotHeight - height) / 2
        width: nameText.implicitWidth + 24
        height: 30
        radius: 12
        color: Theme.bgSolid
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.6)
        opacity: shown ? 1 : 0
        layer.enabled: true
        layer.effect: NeonGlow {
            strength: 0.5
        }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140 } }

        Label {
            id: nameText
            anchors.centerIn: parent
            text: root.current?.kind === "app" ? root.current.name : ""
            color: Theme.accent
            font.pixelSize: 12
        }
    }
}
