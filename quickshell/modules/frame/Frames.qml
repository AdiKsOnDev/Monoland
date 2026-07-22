import Quickshell
import QtQuick

// Per-screen frame shadow + space reservation, mirroring Bar.qml's Variants
// pattern. Instantiated before Bar {} in shell.qml so the shadow maps below
// the panel windows. The frame bands (ScreenFrame) are NOT here — Bar.qml
// instantiates them after BarWindow so they map above bar and panels.
Scope {
    Variants {
        model: Quickshell.screens

        delegate: Scope {
            required property var modelData

            FrameShadow { screen: modelData }
            FrameExclusions { screen: modelData }
        }
    }
}
