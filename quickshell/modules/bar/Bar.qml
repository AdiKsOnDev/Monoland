pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.calendar
import qs.modules.sidebar

Scope {
    Variants {
        model: Quickshell.screens

        delegate: Scope {
            required property var modelData

            BarWindow {
                id: barWindow
                screen: modelData
                onArchClicked: wallpaperPicker.item.open()
                onCenterClicked: clockPopup.item.toggle()
                onRightClicked: notificationSidebar.item.toggle()
            }

            LazyLoader {
                id: notificationSidebar
                loading: true

                NotificationSidebar {
                    screen: modelData
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
                }
            }

            LazyLoader {
                id: wallpaperPicker
                loading: true

                WallpaperPicker {}
            }


        }
    }
}
