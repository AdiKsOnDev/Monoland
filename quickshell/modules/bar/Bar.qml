pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.calendar
import qs.modules.launcher
import qs.modules.sidebar

Scope {
    property var primaryLauncher: null
    property var primaryPowerMenu: null
    property var primaryClockPopup: null
    property var primarySidebar: null

    IpcHandler {
        target: "launcher"
        function open() { primaryLauncher?.open() }
    }

    IpcHandler {
        target: "powermenu"
        function open() { primaryPowerMenu?.open() }
    }

    IpcHandler {
        target: "clock"
        function toggle() { primaryClockPopup?.toggle() }
    }

    IpcHandler {
        target: "sidebar"
        function toggle() { primarySidebar?.toggle() }
    }

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            required property var modelData

            BarWindow {
                id: barWindow
                screen: modelData
                onArchClicked: appLauncher.item.open()
                onCenterClicked: clockPopup.item.toggle()
                onRightClicked: notificationSidebar.item.toggle()
            }

            LazyLoader {
                id: notificationSidebar
                loading: true

                NotificationSidebar {
                    screen: modelData
                    onWallpaperPickerRequested: wallpaperPicker.item.open()
                    onPowerMenuRequested: powerMenu.item.open()
                    Component.onCompleted: {
                        if (!primarySidebar) primarySidebar = this
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

                WallpaperPicker {}
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


        }
    }
}
