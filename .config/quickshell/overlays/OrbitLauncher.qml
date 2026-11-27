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
    readonly property int maxApps: 10
    readonly property real orbitRadius: 168
    readonly property real coreRadius: 84
    readonly property int iconSize: 40
    readonly property var results: engine.results
    readonly property var hero: results.length && results[0].kind !== "app" ? results[0] : null
    readonly property var appResults: results.filter(r => r.kind === "app")
    readonly property int appCount: appResults.length
    readonly property real step: appCount ? 360 / appCount : 0
    readonly property int selectedIndex: appCount ? ((turn % appCount) + appCount) % appCount : -1
    readonly property var selectedApp: appResults[selectedIndex] ?? null
    readonly property var current: hero ?? selectedApp
    readonly property bool noMatch: query.trim() !== "" && results.length === 0
    property real reveal: open ? 1 : 0
    readonly property real presence: Math.max(0, Math.min(1, reveal))
    property string query: ""
    property int turn: 0
    property real spin: turn
    property bool instantSpin: false
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

    Behavior on reveal { NumberAnimation { duration: root.open ? 320 : 180; easing.type: root.open ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.1 } }
    Behavior on spin {
        enabled: !root.instantSpin
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    onOpenChanged: if (open) prepare()
    Component.onCompleted: if (open) prepare()

    function prepare() {
        input.text = "";
        resetSpin();
        normalMode = false;
        input.forceActiveFocus();
    }
    onQueryChanged: resetSpin()

    function resetSpin() {
        instantSpin = true;
        turn = 0;
        instantSpin = false;
    }

    function close() {
        Ui.launcherOpen = false;
    }

    function activate(item) {
        engine.activate(item);
        close();
    }

    function rotate(delta) {
        if (appCount > 1)
            turn += delta;
    }

    function navigateByKey(key) {
        if (key === Qt.Key_Right || key === Qt.Key_Down || key === Qt.Key_Tab)
            rotate(1);
        else if (key === Qt.Key_Left || key === Qt.Key_Up || key === Qt.Key_Backtab)
            rotate(-1);
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
            rotate(1);
        else if (key === Qt.Key_H || key === Qt.Key_K)
            rotate(-1);
        else if (key === Qt.Key_I || key === Qt.Key_A || key === Qt.Key_Slash)
            normalMode = false;
        else
            navigateByKey(key);
        return true;
    }

    function accentRgba(alpha) {
        return `rgba(${Math.round(Theme.accent.r * 255)}, ${Math.round(Theme.accent.g * 255)}, ${Math.round(Theme.accent.b * 255)}, ${alpha})`;
    }

    function offsetFromTop(index) {
        const raw = index - spin;
        return raw - Math.round(raw / appCount) * appCount;
    }

    LauncherEngine {
        id: engine
        query: root.query
        limit: root.maxApps
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.open && root.visible
        onCleared: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bgSolid, 0.35 * root.presence)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
            onWheel: w => root.rotate(w.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Item {
        id: orbit
        anchors.centerIn: parent
        width: 2 * (root.orbitRadius + root.iconSize)
        height: width
        opacity: root.presence
        scale: 0.85 + 0.15 * root.reveal

        Rectangle {
            anchors.centerIn: parent
            width: 2 * root.orbitRadius
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.4)
            rotation: (1 - root.reveal) * -40
            layer.enabled: true
            layer.effect: NeonGlow {
                strength: 0.5
            }
        }

        Canvas {
            id: ticks
            anchors.centerIn: parent
            width: 2 * root.orbitRadius - 18
            height: width
            rotation: (1 - root.reveal) * 50
            onPaint: {
                const ctx = getContext("2d"), c = width / 2;
                ctx.reset();
                for (let i = 0; i < 72; i++) {
                    const a = i * Math.PI / 36, major = i % 6 === 0, inner = c - (major ? 9 : 4);
                    ctx.strokeStyle = root.accentRgba(major ? 0.5 : 0.2);
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(c + inner * Math.cos(a), c + inner * Math.sin(a));
                    ctx.lineTo(c + c * Math.cos(a), c + c * Math.sin(a));
                    ctx.stroke();
                }
            }
        }

        Canvas {
            id: arcs
            anchors.centerIn: parent
            width: 2 * root.orbitRadius + 2 * root.iconSize + 4
            height: width
            onPaint: {
                const ctx = getContext("2d"), c = width / 2, r = c - 2;
                ctx.reset();
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                for (const [start, length, alpha] of [[0.1, 0.55, 0.7], [Math.PI + 0.4, 0.3, 0.45], [Math.PI * 1.55, 0.12, 0.6]]) {
                    ctx.strokeStyle = root.accentRgba(alpha);
                    ctx.beginPath();
                    ctx.arc(c, c, r, start, start + length);
                    ctx.stroke();
                }
            }
            layer.enabled: true
            layer.effect: NeonGlow {
                strength: 0.9
            }

            RotationAnimation on rotation {
                running: root.visible
                from: 0
                to: 360
                duration: 30000
                loops: Animation.Infinite
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 - root.orbitRadius - root.iconSize * 0.95 - height
            width: 6
            height: 6
            radius: 3
            color: Theme.accent
            visible: root.appCount > 0
            layer.enabled: true
            layer.effect: NeonGlow {
                strength: 1
            }
        }

        Repeater {
            model: root.appResults

            Item {
                id: planet
                required property var modelData
                required property int index
                readonly property real offset: root.offsetFromTop(index)
                readonly property real nearness: Math.max(0, 1 - Math.abs(offset))
                readonly property real angle: (offset * root.step - 90 - (1 - root.reveal) * 60) * Math.PI / 180
                readonly property real distance: root.orbitRadius * (0.55 + 0.45 * root.presence)
                readonly property string iconPath: engine.iconFor(modelData?.entry?.icon ?? "")

                width: root.iconSize
                height: root.iconSize
                x: orbit.width / 2 + distance * Math.cos(angle) - width / 2
                y: orbit.height / 2 + distance * Math.sin(angle) - height / 2
                scale: (hover.containsMouse ? 1.12 : 1) + 0.38 * nearness
                opacity: 0.55 + 0.45 * Math.max(nearness, hover.containsMouse ? 1 : 0)
                z: nearness
                Behavior on scale { NumberAnimation { duration: 140 } }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 14
                    height: width
                    radius: width / 2
                    color: Qt.alpha(Theme.accent, 0.1 * planet.nearness)
                    border.width: 0
                    border.color: Qt.alpha(Theme.accent, 0.8 * planet.nearness)
                    layer.enabled: planet.nearness > 0.5
                    layer.effect: NeonGlow {
                        strength: 0.8
                    }
                }

                IconImage {
                    anchors.fill: parent
                    visible: planet.iconPath !== ""
                    source: planet.iconPath
                    asynchronous: true
                }
                Rectangle {
                    anchors.fill: parent
                    visible: planet.iconPath === ""
                    radius: width / 2
                    color: Theme.surface2

                    Label {
                        anchors.centerIn: parent
                        text: (planet.modelData?.name ?? "").charAt(0).toUpperCase()
                        color: Theme.accent
                        font.pixelSize: 17
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(planet.modelData)
                }
            }
        }

        Rectangle {
            id: core
            anchors.centerIn: parent
            width: 2 * root.coreRadius
            height: width
            radius: width / 2
            color: Theme.bgSolid
            border.width: 1
            border.color: root.noMatch ? Qt.alpha(Theme.red, 0.7) : Qt.alpha(Theme.accent, input.text ? 0.85 : 0.45)
            Behavior on border.color { ColorAnimation { duration: 160 } }
            layer.enabled: true
            layer.effect: NeonGlow {
                glowColor: root.noMatch ? Theme.red : Theme.accent
                strength: input.text ? 0.7 : 0.4
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.current ? root.activate(root.current) : input.forceActiveFocus()
                onWheel: w => root.rotate(w.angleDelta.y > 0 ? -1 : 1)
            }

            TextInput {
                id: input
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -10
                width: parent.width - 36
                horizontalAlignment: contentWidth > width ? TextInput.AlignRight : TextInput.AlignHCenter
                clip: true
                color: root.noMatch ? Theme.red : Theme.fg
                selectionColor: Qt.alpha(Theme.accent, 0.35)
                font.family: Theme.font
                font.pixelSize: 16
                font.bold: true
                focus: true
                readOnly: root.normalMode
                onTextChanged: root.query = text
                Behavior on color { ColorAnimation { duration: 160 } }

                cursorDelegate: Rectangle {
                    width: root.normalMode ? 9 : 2
                    height: 18
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

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: input.bottom
                anchors.topMargin: 8
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                text: root.hero?.kind === "calc" ? `= ${root.hero.name}` : root.hero?.kind === "run" ? "↵" : root.selectedApp?.name ?? ""
                color: Theme.accent
                font.pixelSize: root.hero?.kind === "calc" ? 15 : 12
                elide: Text.ElideRight
            }
        }
    }
}
