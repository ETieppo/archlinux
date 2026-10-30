//@ pragma UseQApplication
//@ pragma NativeTextRendering
import QtQuick
import Quickshell
import qs
import qs.bar
import qs.bottom
import qs.sidebar
import qs.notifications
import qs.overlays
import qs.lock

ShellRoot {
    Variants {
        model: Quickshell.screens
        TopBar {}
    }

    Variants {
        model: Quickshell.screens
        SideBar {}
    }

    Variants {
        model: Quickshell.screens
        BottomBar {}
    }

    Popups {}

    LazyLoader {
        active: Ui.selecting
        RegionSelector {}
    }

    Launcher {}
    Osd {}
    PolkitDialog {}
    Lock {}
    Night {}
}
