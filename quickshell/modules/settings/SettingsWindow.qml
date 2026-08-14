pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.modules.common

// Centered Material settings window. Right-clicking a sidebar toggle deep-links
// straight to that section; the nav rail then moves between them.
PanelWindow {
    id: root

    required property var screen

    property bool isOpen: false
    property string section: "wifi"

    readonly property var sections: [
        { id: "wifi",       icon: "󰤨", label: "Wi-Fi" },
        { id: "bluetooth",  icon: "󰂯", label: "Bluetooth" },
        { id: "sound",      icon: "󰕾", label: "Sound" },
        { id: "mic",        icon: "󰍬", label: "Mic" },
        { id: "display",    icon: "󰃠", label: "Display" },
        { id: "notifs",     icon: "󰂚", label: "Alerts" },
        { id: "appearance", icon: "󰏘", label: "Theme" },
    ]

    function open(target) {
        if (target) section = target
        // A close() still inside its hide delay would otherwise unmap the
        // window we are about to show
        hideTimer.stop()
        visible = true
        isOpen = true
        // Escape only reaches the card once it holds focus within the window
        card.forceActiveFocus()
    }

    function close() {
        isOpen = false
        hideTimer.start()
    }

    function toggle(target) {
        if (isOpen) close()
        else open(target)
    }

    // Start unmapped; open()/hideTimer manage visibility around the animation
    visible: false

    anchors { top: true; left: true; right: true; bottom: true }

    exclusiveZone: -1
    color: "transparent"
    focusable: isOpen
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region { item: root.isOpen ? catcher : emptyRegion }

    Item { id: emptyRegion; width: 0; height: 0 }

    readonly property rect inner: Frame.innerRect(root.screen)

    // Fullscreen click-catcher and mask source. The scrim is inset to the
    // workspace hole so the frame stays bright, matching PowerMenu.
    Item {
        id: catcher
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            anchors {
                fill: parent
                topMargin: Frame.barHeight
                leftMargin: Frame.thickness
                rightMargin: Frame.thickness
                bottomMargin: Frame.thickness
            }
            color: Qt.rgba(0, 0, 0, 0.55)
            opacity: root.isOpen ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Md.durMedium; easing.type: Md.easingStandard } }
        }
    }

    Rectangle {
        id: card

        width: Math.min(900, root.inner.width - 64)
        // Tall enough for the full nav rail; it scrolls if the screen is shorter
        height: Math.min(740, root.inner.height - 64)
        x: root.inner.x + (root.inner.width - width) / 2
        y: root.inner.y + (root.inner.height - height) / 2

        radius: Md.cornerXl
        color: Md.surface
        border.width: 1
        border.color: Md.outlineVariant

        Behavior on color { ColorAnimation { duration: Md.durMedium } }

        Keys.onEscapePressed: root.close()

        // Swallow clicks so they don't reach the catcher behind
        MouseArea { anchors.fill: parent }

        // ── Top app bar ──────────────────────────────────────────────────
        Item {
            id: appBar
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 84

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 32
                    verticalCenter: parent.verticalCenter
                }
                text: "Settings"
                color: Md.textOnSurface
                font.family: Md.fontFamily
                font.pixelSize: Md.headlineSmall
                font.weight: Font.Bold
            }

            MdIconButton {
                anchors {
                    right: parent.right
                    rightMargin: 24
                    verticalCenter: parent.verticalCenter
                }
                icon: "󰅖"
                size: 40
                onClicked: root.close()
            }
        }

        // ── Navigation rail ──────────────────────────────────────────────
        MdNavRail {
            id: rail
            anchors {
                top: appBar.bottom
                left: parent.left
                bottom: parent.bottom
                leftMargin: 20
                bottomMargin: 24
            }
            width: 96
            sections: root.sections
            current: root.section
            onSelected: (id) => root.section = id
        }

        // ── Content ──────────────────────────────────────────────────────
        Rectangle {
            id: contentPane
            anchors {
                top: appBar.bottom
                left: rail.right
                right: parent.right
                bottom: parent.bottom
                leftMargin: 16
                rightMargin: 20
                bottomMargin: 24
            }
            radius: Md.cornerXl
            color: Md.surfaceContainerLowest

            Behavior on color { ColorAnimation { duration: Md.durMedium } }

            Loader {
                id: pageLoader
                anchors {
                    fill: parent
                    margins: 20
                }
                sourceComponent: root.section === "wifi" ? wifiComp
                    : root.section === "bluetooth" ? bluetoothComp
                    : root.section === "sound" ? soundComp
                    : root.section === "mic" ? micComp
                    : root.section === "display" ? displayComp
                    : root.section === "notifs" ? notifsComp
                    : root.section === "appearance" ? appearanceComp
                    : null

                // Cross-fade between sections so switching doesn't snap
                opacity: 0
                onLoaded: fadeIn.restart()

                NumberAnimation {
                    id: fadeIn
                    target: pageLoader
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Md.durMedium
                    easing.type: Md.easingStandard
                }
            }
        }
    }

    Component { id: wifiComp;       WifiSection {} }
    Component { id: bluetoothComp;  BluetoothSection {} }
    Component { id: soundComp;      SoundSection {} }
    Component { id: micComp;        MicSection {} }
    Component { id: displayComp;    DisplaySection {} }
    Component { id: notifsComp;     NotificationsSection {} }
    Component { id: appearanceComp; AppearanceSection {} }

    Timer {
        id: hideTimer
        interval: Md.durLong
        repeat: false
        onTriggered: root.visible = false
    }

    Reveal {
        target: card
        shown: root.isOpen
        motion: "scale"
        inDuration: 320
        outDuration: 180
    }
}
