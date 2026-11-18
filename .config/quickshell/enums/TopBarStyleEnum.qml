pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string classic: "classic"
    readonly property string notch: "notch"
    readonly property var all: [classic, notch]
}
