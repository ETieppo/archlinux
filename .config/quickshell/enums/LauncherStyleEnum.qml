pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string lava: "lava"
    readonly property string edge: "edge"
    readonly property string orbit: "orbit"
    readonly property string drum: "drum"
    readonly property string reticle: "reticle"
    readonly property var all: [lava, edge, orbit, drum, reticle]
}
