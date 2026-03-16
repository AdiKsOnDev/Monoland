pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import qs.services

Scope {
    id: root

    IpcHandler {
        target: "lockscreen"
        function lock() { root.lock() }
    }

    // Shared PAM context — only one auth session runs at a time across all surfaces
    property string password: ""
    property bool authFailed: false
    property bool authPending: false

    function lock() {
        password = ""
        authFailed = false
        sessionLock.locked = true
    }

    function unlock() {
        sessionLock.locked = false
    }

    function authenticate() {
        if (authPending) return
        authFailed = false
        authPending = true
        pam.start()
    }

    PamContext {
        id: pam
        config: "system-auth"

        onPamMessage: { if (responseRequired) respond(root.password) }

        onCompleted: (result) => {
            root.authPending = false
            if (result === PamResult.Success) {
                root.unlock()
            } else {
                root.authFailed = true
                root.password = ""
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        LockSurface {
            password: root.password
            authFailed: root.authFailed
            authPending: root.authPending

            onPasswordEdited: (p) => root.password = p
            onSubmitted: root.authenticate()
        }
    }
}
