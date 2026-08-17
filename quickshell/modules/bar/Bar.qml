pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.modules.calendar
import qs.modules.frame
import qs.modules.launcher
import qs.modules.settings
import qs.modules.sidebar

Scope {
    property var primaryLauncher: null
    property var primaryPowerMenu: null
    property var primaryClockPopup: null
    property var primarySidebar: null
    property var primaryWallpaperPicker: null
    property var primarySettings: null

    IpcHandler {
        target: "launcher"
        function open() { primaryLauncher?.open() }
        function close() { primaryLauncher?.close() }
    }

    IpcHandler {
        target: "powermenu"
        function open() { primaryPowerMenu?.open() }
        function close() { primaryPowerMenu?.close() }
    }

    IpcHandler {
        target: "clock"
        function toggle() { primaryClockPopup?.toggle() }
    }

    IpcHandler {
        target: "sidebar"
        function toggle() { primarySidebar?.toggle() }
    }

    IpcHandler {
        target: "wallpapers"
        function open() { primaryWallpaperPicker?.open() }
        function close() { primaryWallpaperPicker?.close() }
    }

    IpcHandler {
        target: "settings"
        function open(section: string) { primarySettings?.open(section) }
        function close() { primarySettings?.close() }
        function toggle(section: string) { primarySettings?.toggle(section) }
    }

    // set-wallpaper.sh calls this after wal regenerates the palette, so the
    // shell recolors in place instead of being killed and restarted.
    IpcHandler {
        target: "colors"
        function reload() { Colors.reload() }
    }

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            required property var modelData

            LazyLoader {
                id: notificationSidebar
                loading: true

                NotificationSidebar {
                    screen: modelData
                    onWallpaperPickerRequested: wallpaperPicker.item.open()
                    onPowerMenuRequested: powerMenu.item.open()
                    onSettingsRequested: (section) => {
                        settingsWindow.item.open(section)
                        isOpen = false   // close the sidebar behind the settings window
                    }
                    Component.onCompleted: {
                        if (!primarySidebar) primarySidebar = this
                    }
                }
            }

            LazyLoader {
                id: settingsWindow
                loading: true

                SettingsWindow {
                    screen: modelData
                    Component.onCompleted: {
                        if (!primarySettings) primarySettings = this
                    }
                }
            }

            NotificationToast {
                screen: modelData
                sidebarOpen: notificationSidebar.item?.isOpen ?? false
            }

            OsdToast {
                screen: modelData
                sidebarOpen: notificationSidebar.item?.isOpen ?? false
            }

            LazyLoader {
                id: clockPopup
                loading: true

                ClockPopup {
                    screen: modelData
                    Component.onCompleted: {
                        if (!primaryClockPopup) primaryClockPopup = this
                    }
                }
            }

            LazyLoader {
                id: wallpaperPicker
                loading: true

                WallpaperPicker {
                    screen: modelData
                    Component.onCompleted: {
                        if (!primaryWallpaperPicker) primaryWallpaperPicker = this
                    }
                }
            }

            LazyLoader {
                id: powerMenu
                loading: true

                PowerMenu {
                    screen: modelData
                    Component.onCompleted: {
                        if (!primaryPowerMenu) primaryPowerMenu = this
                    }
                }
            }

            LazyLoader {
                id: appLauncher
                loading: true

                AppLauncher {
                    screen: modelData
                    Component.onCompleted: {
                        if (!primaryLauncher) primaryLauncher = this
                    }
                }
            }

            // Last: the bar must map above the panel windows so panels slide
            // out from behind it (the emerge animation hides them under the bar)
            BarWindow {
                id: barWindow
                screen: modelData
                onArchClicked: appLauncher.item.open()
                onCenterClicked: clockPopup.item.toggle()
                onRightClicked: notificationSidebar.item.toggle()
            }

            // Very last: the frame bands sit on the same Top layer as the bar
            // and everything else — fullscreen windows cover them naturally —
            // so map order alone must put them above the sliding panels
            ScreenFrame { screen: modelData }
        }
    }
}
