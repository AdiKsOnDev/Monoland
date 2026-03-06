pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs.services

AnimatedPopup {
    id: root

    popupWidth: 350
    alignRight: true

    SliderRow {
        icon: Audio.muted ? "󰖁" : "󰕾"
        value: Audio.volumePercent
        onMoved: (percent) => {
            if (Audio.sink?.audio)
                Audio.sink.audio.volume = percent / 100
        }
    }

    SliderRow {
        icon: "󰃞"
        value: Brightness.brightnessPercent
        onMoved: (percent) => Brightness.setBrightnessPercent(percent)
    }

    Item { implicitHeight: 8 }

    Item {
        implicitWidth: parent?.width ?? 0
        implicitHeight: 44

        ToggleButton {
            id: wifiBtn
            icon: Wifi.enabled ? "󰤨" : "󰤭"
            active: Wifi.enabled
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            onClicked: Wifi.toggle()
        }

        ToggleButton {
            icon: Bluetooth.enabled ? "󰂯" : "󰂲"
            active: Bluetooth.enabled
            x: (parent.width - implicitWidth) / 3
            anchors.verticalCenter: parent.verticalCenter
            onClicked: Bluetooth.toggle()
        }

        ToggleButton {
            icon: Audio.muted ? "󰖁" : "󰕾"
            active: !Audio.muted
            x: (parent.width - implicitWidth) * 2 / 3
            anchors.verticalCenter: parent.verticalCenter
            onClicked: Audio.toggleMute()
        }

        ToggleButton {
            icon: Audio.micMuted ? "󰍭" : "󰍬"
            active: !Audio.micMuted
            x: parent.width - implicitWidth
            anchors.verticalCenter: parent.verticalCenter
            onClicked: Audio.toggleMicMute()
        }
    }
}
