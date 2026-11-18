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
    readonly property int maxResults: 12
    readonly property real spacing: 112
    readonly property int iconSize: 44
    readonly property real reticleSize: 96
    readonly property string scrambleGlyphs: "▓▒░<>/\\|=+*#01"
    readonly property int scrambleFrames: 9
    readonly property var results: engine.results
    readonly property var current: results[currentIndex] ?? null
    readonly property bool noMatch: query.trim() !== "" && results.length === 0
    readonly property real presence: Math.max(0, Math.min(1, reveal))
    readonly property real beamY: height * 0.42
    property real reveal: open ? 1 : 0
    property string query: ""
    property int currentIndex: 0
    property real spin: currentIndex
    property bool instantSpin: false
    property bool normalMode: false
    property string decodedName: ""
    property int scrambleFrame: 0
    property real lockPulse: 0

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
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    onOpenChanged: if (open) prepare()
    Component.onCompleted: if (open) prepare()
    onQueryChanged: resetSpin()
    onCurrentChanged: decode()

    function prepare() {
        input.text = "";
        resetSpin();
        normalMode = false;
        input.forceActiveFocus();
        decode();
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

    function labelFor(item) {
        if (!item)
            return "";
        return (item.kind === "calc" ? `= ${item.name}` : item.kind === "run" ? `$ ${item.name}` : item.name).toUpperCase();
    }

    function decode() {
        scrambleFrame = 0;
        lockPulseAnimation.restart();
        scrambleTimer.restart();
        renderScramble();
    }

    function renderScramble() {
        const target = labelFor(current);
        const settled = Math.floor(target.length * scrambleFrame / scrambleFrames);
        let out = target.slice(0, settled);
        for (let i = settled; i < target.length; i++)
            out += target[i] === " " ? " " : scrambleGlyphs[Math.floor(Math.random() * scrambleGlyphs.length)];
        decodedName = out;
    }

    function navigateByKey(key) {
        if (key === Qt.Key_Right || key === Qt.Key_Down || key === Qt.Key_Tab)
            move(1);
        else if (key === Qt.Key_Left || key === Qt.Key_Up || key === Qt.Key_Backtab)
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
        else if (key === Qt.Key_L || key === Qt.Key_J)
            move(1);
        else if (key === Qt.Key_H || key === Qt.Key_K)
            move(-1);
        else if (key === Qt.Key_I || key === Qt.Key_A || key === Qt.Key_Slash)
            normalMode = false;
        else
            navigateByKey(key);
        return true;
    }

    function accentRgba(alpha) {
        return `rgba(${Math.round(Theme.accent.r * 255)}, ${Math.round(Theme.accent.g * 255)}, ${Math.round(Theme.accent.b * 255)}, ${alpha})`;
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

    Timer {
        id: scrambleTimer
        interval: 32
        repeat: true
        onTriggered: {
            root.scrambleFrame++;
            root.renderScramble();
            if (root.scrambleFrame >= root.scrambleFrames)
                stop();
        }
    }

    NumberAnimation {
        id: lockPulseAnimation
        target: root
        property: "lockPulse"
        from: 1
        to: 0
        duration: 320
        easing.type: Easing.OutCubic
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bgSolid, 0.62 * root.presence)

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

        Rectangle {
            id: beam
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.beamY
            width: parent.width * root.presence
            height: 1
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

        Canvas {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.beamY - 6
            width: parent.width * 0.7
            height: 13
            onPaint: {
                const ctx = getContext("2d"), mid = width / 2;
                ctx.reset();
                for (let x = 0; x <= mid; x += 14) {
                    const major = Math.round(x / 14) % 5 === 0, fade = 1 - x / mid, length = major ? 6 : 3;
                    ctx.strokeStyle = root.accentRgba((major ? 0.5 : 0.22) * fade);
                    ctx.lineWidth = 1;
                    for (const px of x === 0 ? [mid] : [mid - x, mid + x]) {
                        ctx.beginPath();
                        ctx.moveTo(px, 6 - length);
                        ctx.lineTo(px, 7 + length);
                        ctx.stroke();
                    }
                }
            }
        }

        Repeater {
            model: root.results

            Item {
                id: target
                required property var modelData
                required property int index
                readonly property real offset: index - root.spin
                readonly property real nearness: Math.max(0, 1 - Math.abs(offset))
                readonly property bool isApp: modelData?.kind === "app"
                readonly property string iconPath: isApp ? engine.iconFor(modelData.entry?.icon ?? "") : ""

                width: root.iconSize
                height: root.iconSize
                x: stage.width / 2 + offset * root.spacing - width / 2
                y: root.beamY - height / 2
                visible: Math.abs(offset) < 7
                scale: 1 + 0.45 * nearness
                opacity: (0.3 + 0.7 * nearness) * Math.max(0, 1 - Math.abs(offset) / 7)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -6
                    radius: 10
                    color: Theme.bgSolid
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent, 0.15 + 0.25 * target.nearness)
                }

                IconImage {
                    anchors.fill: parent
                    visible: target.iconPath !== ""
                    source: target.iconPath
                    asynchronous: true
                }
                Label {
                    anchors.centerIn: parent
                    visible: target.iconPath === ""
                    text: target.isApp ? (target.modelData?.name ?? "").charAt(0).toUpperCase() : target.modelData?.kind === "calc" ? "=" : "$"
                    color: Theme.accent
                    font.pixelSize: 20
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: target.index === root.currentIndex ? root.activate(target.modelData) : root.currentIndex = target.index
                }
            }
        }

        Item {
            id: reticle
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.beamY - height / 2
            width: root.reticleSize
            height: root.reticleSize
            visible: root.results.length > 0
            scale: (1 + 0.16 * root.lockPulse) * (0.7 + 0.3 * root.presence)
            rotation: 45 * root.lockPulse
            layer.enabled: true
            layer.effect: NeonGlow {
                strength: 1
            }

            Repeater {
                model: 4

                Item {
                    required property int index
                    readonly property bool onRight: index % 2 === 1
                    readonly property bool onBottom: index > 1

                    x: onRight ? reticle.width - width : 0
                    y: onBottom ? reticle.height - height : 0
                    width: 18
                    height: 18

                    Rectangle {
                        y: parent.onBottom ? parent.height - 2 : 0
                        width: parent.width
                        height: 2
                        color: Theme.accent
                    }
                    Rectangle {
                        x: parent.onRight ? parent.width - 2 : 0
                        width: 2
                        height: parent.height
                        color: Theme.accent
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.beamY + root.reticleSize / 2 + 26
            text: root.decodedName
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 7
            layer.enabled: true
            layer.effect: NeonGlow {
                strength: 0.8
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.beamY - root.reticleSize / 2 - 64
            spacing: 4

            TextInput {
                id: input
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(2, contentWidth + 2)
                color: root.noMatch ? Theme.red : Theme.fg
                selectionColor: Qt.alpha(Theme.accent, 0.35)
                font.family: Theme.font
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 4
                font.capitalization: Font.AllUppercase
                focus: true
                readOnly: root.normalMode
                onTextChanged: root.query = text

                cursorDelegate: Rectangle {
                    width: 10
                    height: 18
                    color: Theme.accent
                    opacity: root.normalMode ? 0.9 : 0.75

                    SequentialAnimation on opacity {
                        running: !root.normalMode && root.open
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 480; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.75; duration: 480; easing.type: Easing.InOutSine }
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
    }
}
