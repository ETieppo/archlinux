//@ pragma NativeTextRendering
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Wayland
import qs
import qs.lock

ShellRoot {
    id: root

    property string buffer: ""
    property bool busy: false
    property bool failed: false
    property int fails: 0
    property var users: []
    property int userIndex: 0
    property string hostname: ""
    readonly property string user: users[userIndex] ?? ""
    readonly property var session: ["start-hyprland >/dev/null 2>&1"]

    function submit() {
        if (busy || buffer === "" || user === "")
            return;
        busy = true;
        failed = false;
        Greetd.createSession(user);
    }

    function nextUser() {
        if (users.length > 1)
            userIndex = (userIndex + 1) % users.length;
    }

    function fail() {
        busy = false;
        buffer = "";
        failed = true;
        fails++;
    }

    onBufferChanged: if (buffer !== "") failed = false

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired)
                Greetd.respond(root.buffer);
            else if (error)
                root.fail();
        }
        function onAuthFailure(message) {
            root.fail();
        }
        function onError(error) {
            root.fail();
        }
        function onReadyToLaunch() {
            root.buffer = "";
            Greetd.launch(root.session);
        }
    }

    FileView {
        path: "/etc/passwd"
        onLoaded: root.users = text().split("\n").map(l => l.split(":")).filter(f => {
            const uid = Number(f[2]);
            return uid >= 1000 && uid < 60000 && f[6] && !/(nologin|false)$/.test(f[6]);
        }).map(f => f[0])
    }

    FileView {
        path: "/etc/hostname"
        onLoaded: root.hostname = text().trim()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "black"

            LockSurface {
                lock: root
                wallpaper: Quickshell.shellPath("wallpaper")
                userName: root.user + (root.users.length > 1 ? "  󰁔" : "")
                hint: "****"
            }
        }
    }
}
