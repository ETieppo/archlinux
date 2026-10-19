pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property var popups: []
    readonly property var all: server.trackedNotifications.values

    function hide(n) {
        popups = popups.filter(p => p !== n);
    }

    function send(appName, summary, body, urgency) {
        Quickshell.execDetached(["notify-send", "-a", appName, "-u", urgency || "normal", summary, body || ""]);
    }

    function clearAll() {
        for (const n of [...all])
            n.dismiss();
        popups = [];
    }

    NotificationServer {
        id: server
        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n, ...root.popups].slice(0, 5);
            n.closed.connect(() => root.hide(n));
        }
    }

    IpcHandler {
        target: "notifs"
        function dnd(): void {
            root.dnd = !root.dnd;
        }
        function clear(): void {
            root.clearAll();
        }
        function send(appName: string, summary: string, body: string): void {
            root.send(appName, summary, body, "normal");
        }
        function sendCritical(appName: string, summary: string, body: string): void {
            root.send(appName, summary, body, "critical");
        }
    }
}
