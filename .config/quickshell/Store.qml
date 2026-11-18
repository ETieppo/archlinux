pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias usage: adapter.usage
    property alias kbd: adapter.kbd
    property alias nightSaved: adapter.nightSaved
    property alias runs: adapter.runs
    property alias launcherStyle: adapter.launcherStyle
    property alias topBarStyle: adapter.topBarStyle
    property alias notchPhysicalWidth: adapter.notchPhysicalWidth
    property alias notchPhysicalHeight: adapter.notchPhysicalHeight

    function bump(id) {
        const u = Object.assign({}, usage);
        u[id] = (u[id] ?? 0) + 1;
        usage = u;
    }

    FileView {
        path: Quickshell.statePath("state.json")
        watchChanges: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property var usage: ({})
            property var kbd: ({})
            property int nightSaved: -1
            property var runs: ({})
            property string launcherStyle: ""
            property string topBarStyle: ""
            property int notchPhysicalWidth: 0
            property int notchPhysicalHeight: 0
        }
    }
}
