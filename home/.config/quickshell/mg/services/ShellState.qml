pragma Singleton
import Quickshell
import Quickshell.Io

// Cross-surface open/closed flags plus the shell's IPC surface.
// IpcHandler requires explicitly annotated argument and return types or the
// function is silently not registered - hence the `: void` / `: bool`.
Singleton {
    id: root
    property bool launcherOpen: false
    property bool notifCentreOpen: false

    function toggleLauncher(): void { root.launcherOpen = !root.launcherOpen; }
    function closeLauncher(): void { root.launcherOpen = false; }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggleLauncher(); }
        function open(): void { root.launcherOpen = true; }
        function close(): void { root.closeLauncher(); }
        function isOpen(): bool { return root.launcherOpen; }
    }

    IpcHandler {
        target: "theme"
        // retheme calls this as belt-and-braces; Colours already watches the
        // file itself, so a failure here is harmless.
        function reload(): void { Colours.reloadNow(); }
        function currentSource(): string { return Colours.source; }
    }
}
