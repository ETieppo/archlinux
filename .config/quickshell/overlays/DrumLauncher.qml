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
    readonly property int maxResults: 11
    readonly property int visibleSpan: 4
    readonly property real drumRadius: 220
    readonly property real stepAngle: 0.34
    readonly property real bandHeight: 64
    readonly property var results: engine.results
    readonly property var current: results[currentIndex] ?? null
    readonly property bool noMatch: query.trim() !== "" && results.length === 0
    readonly property real presence: Math.max(0, Math.min(1, reveal))
    property real reveal: open ? 1 : 0
    property string query: ""
    property int currentIndex: 0
    property real spin: currentIndex
    property bool instantSpin: false
    property bool normalMode: false
    property real selectedWidth: 160

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

    Behavior on reveal { NumberAnimation { duration: root.open ? 260 : 170; easing.type: root.open ? Easing.OutCubic : Easing.InCubic } }
    Behavior on spin {
        enabled: !root.instantSpin
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
    }
    Behavior on selectedWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    onOpenChanged: if (open) prepare()
    Component.onCompleted: if (open) prepare()
    onQueryChanged: resetSpin()

    function prepare() {
        input.text = "";
        resetSpin();
        normalMode = false;
        input.forceActiveFocus();
    }

    function resetSpin() {
        instantSpin = true;
        currentIndex = 0;
        instantSpin = false;
    }

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

    function navigateByKey(key) {
        if (key === Qt.Key_Down || key === Qt.Key_Right || key === Qt.Key_Tab)
            move(1);
        else if (key === Qt.Key_Up || key === Qt.Key_Left || key === Qt.Key_Backtab)
            move(-1);
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

    function labelFor(item) {
        return item.kind === "calc" ? `= ${item.name}` : item.kind === "run" ? `$ ${item.name}` : item.name;
    }

    LauncherEngine {
        id: engine
        query: root.query
        limit: root.maxResults
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.open && root.visible
        onCleared: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bgSolid, 0.6 * root.presence)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
            onWheel: w => root.move(w.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: root.presence

        Item {
            id: band
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: root.bandHeight

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.alpha(Theme.accent, 0.07) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            Repeater {
                model: [0, 1]

                Rectangle {
                    required property int modelData
                    y: modelData ? band.height - 1 : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.6 * root.presence
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.alpha(Theme.accent, 0.5) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
            }

            Label {
                x: parent.width / 2 - root.selectedWidth / 2 - width - 18
                anchors.verticalCenter: parent.verticalCenter
                visible: root.results.length > 0
                text: "["
                color: Theme.accent
                font.pixelSize: 34
                font.bold: false
                layer.enabled: true
                layer.effect: NeonGlow {
                    strength: 1
                }
            }

            Label {
                x: parent.width / 2 + root.selectedWidth / 2 + 18
                anchors.verticalCenter: parent.verticalCenter
                visible: root.results.length > 0
                text: "]"
                color: Theme.accent
                font.pixelSize: 34
                font.bold: false
                layer.enabled: true
                layer.effect: NeonGlow {
                    strength: 1
                }
            }
        }

        Repeater {
            model: root.results

            Item {
                id: row
                required property var modelData
                required property int index
                readonly property real offset: index - root.spin
                readonly property real angle: offset * root.stepAngle
                readonly property real nearness: Math.max(0, 1 - Math.abs(offset))
                readonly property string iconPath: modelData?.kind === "app" ? engine.iconFor(modelData.entry?.icon ?? "") : ""

                visible: Math.abs(offset) <= root.visibleSpan && Math.cos(angle) > 0
                width: content.width
                height: content.height
                x: stage.width / 2 - width / 2
                y: stage.height / 2 + Math.sin(angle) * root.drumRadius - height / 2
                scale: 0.5 + 0.5 * Math.cos(angle)
                opacity: Math.pow(Math.max(0, Math.cos(angle)), 2.5) * (0.45 + 0.55 * nearness)
                z: nearness

                transform: Rotation {
                    origin.x: row.width / 2
                    origin.y: row.height / 2
                    axis { x: 1; y: 0; z: 0 }
                    angle: -row.angle * 180 / Math.PI
                }

                Binding {
                    target: root
                    property: "selectedWidth"
                    value: row.width
                    when: row.index === root.currentIndex
                }

                Row {
                    id: content
                    spacing: 16

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        height: 34
                        visible: row.modelData?.kind === "app"

                        IconImage {
                            anchors.fill: parent
                            visible: row.iconPath !== ""
                            source: row.iconPath
                            asynchronous: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: row.iconPath === ""
                            radius: 10
                            color: Theme.surface2

                            Label {
                                anchors.centerIn: parent
                                text: (row.modelData?.name ?? "").charAt(0).toUpperCase()
                                color: Theme.accent
                                font.pixelSize: 16
                            }
                        }
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData ? root.labelFor(row.modelData) : ""
                        color: row.nearness > 0.5 ? Theme.accent : Theme.fg
                        font.pixelSize: 26
                        layer.enabled: row.nearness > 0.5
                        layer.effect: NeonGlow {
                            strength: 0.85
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.index === root.currentIndex ? root.activate(row.modelData) : root.currentIndex = row.index
                }
            }
        }

        Item {
            id: prompt
            anchors.horizontalCenter: parent.horizontalCenter
            y: stage.height / 2 - root.drumRadius - 70 + (1 - root.presence) * 20
            width: Math.max(220, promptRow.width + 60)
            height: 40
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Row {
                id: promptRow
                anchors.centerIn: parent
                spacing: 10

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.normalMode ? "■" : "›"
                    color: root.noMatch ? Theme.red : Theme.accent
                    font.pixelSize: root.normalMode ? 12 : 22
                    layer.enabled: true
                    layer.effect: NeonGlow {
                        glowColor: root.noMatch ? Theme.red : Theme.accent
                        strength: 1
                    }
                }

                TextInput {
                    id: input
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(2, contentWidth + 2)
                    color: root.noMatch ? Theme.red : Theme.fg
                    selectionColor: Qt.alpha(Theme.accent, 0.35)
                    font.family: Theme.font
                    font.pixelSize: 20
                    font.bold: true
                    focus: true
                    readOnly: root.normalMode
                    onTextChanged: root.query = text

                    cursorDelegate: Rectangle {
                        width: 2
                        height: 22
                        color: Theme.accent
                        visible: !root.normalMode

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
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 2
                radius: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: root.noMatch ? Theme.red : Theme.accent }
                    GradientStop { position: 1; color: "transparent" }
                }
                layer.enabled: true
                layer.effect: NeonGlow {
                    glowColor: root.noMatch ? Theme.red : Theme.accent
                    strength: 0.9
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: input.forceActiveFocus()
            }
        }
    }
}
