pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: sink?.audio.muted
    readonly property real volume: sink?.audio.volume

    function setVolume(volume: real): void {
        console.log(sink?.id);
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = volume;
        }
    }

    PwObjectTracker {
        objects: [sink, source]
    }
}