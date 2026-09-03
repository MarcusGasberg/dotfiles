pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire

// Facade over the default sink/source. PwObjectTracker is required: without
// binding the nodes they are not kept live and their properties read stale.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property int percent: Math.round(volume * 100)

    readonly property bool micMuted: source?.audio?.muted ?? true

    readonly property string icon: {
        if (muted) return "volume_off";
        if (percent < 33) return "volume_mute";
        if (percent < 66) return "volume_down";
        return "volume_up";
    }

    function setVolume(v: real): void {
        if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function step(delta: int): void {
        setVolume(volume + delta / 100);
    }
    function toggleMute(): void {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker { objects: [root.sink, root.source] }
}
