import Quickshell
import QtQuick

// Per-screen frame instantiation, mirroring Bar.qml's Variants pattern.
Scope {
    Variants {
        model: Quickshell.screens

        delegate: Scope {
            required property var modelData

            // Shadow first: it must map below the panel windows (Top layer,
            // map order), while ScreenFrame's bands sit above them on Overlay
            FrameShadow { screen: modelData }
            ScreenFrame { screen: modelData }
            FrameExclusions { screen: modelData }
        }
    }
}
