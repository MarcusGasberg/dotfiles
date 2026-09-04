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
        function currentSource(): string { return Colours.schemeSource; }
        // Report real palette values so the pipeline can be verified by
        // data. Looking at a screenshot is not enough: the bar is
        // translucent, so a wallpaper change alters its apparent colour even
        // when the palette has not loaded at all.
        function surface(): string { return String(Colours.palette.surface); }
        function primary(): string { return String(Colours.palette.primary); }
        function loaded(): bool { return Colours.schemeSource !== ""; }
    }
}
