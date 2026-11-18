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
import qs.enums

ShellRoot {
    Variants {
        model: Ui.topBarStyle === TopBarStyleEnum.classic ? Quickshell.screens : []
        TopBar {}
    }

    Variants {
        model: Quickshell.screens
        SideBar {}
    }

    Variants {
        model: Ui.topBarStyle === TopBarStyleEnum.notch ? Quickshell.screens : []
        NotchBar {}
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

    LazyLoader {
        active: Ui.launcherStyle === LauncherStyleEnum.lava
        Launcher {}
    }

    LazyLoader {
        active: Ui.launcherStyle === LauncherStyleEnum.edge
        EdgeLauncher {}
    }

    LazyLoader {
        active: Ui.launcherStyle === LauncherStyleEnum.orbit
        OrbitLauncher {}
    }

    LazyLoader {
        active: Ui.launcherStyle === LauncherStyleEnum.drum
        DrumLauncher {}
    }

    LazyLoader {
        active: Ui.launcherStyle === LauncherStyleEnum.reticle
        ReticleLauncher {}
    }

    Osd {}
    PolkitDialog {}
    Lock {}
    Night {}
}
