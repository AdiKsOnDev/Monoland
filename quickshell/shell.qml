import Quickshell
import qs.modules.bar
import qs.modules.frame
import qs.modules.lockscreen

ShellRoot {
    // Frames first: the frame-shadow window must map before the panel windows
    // so panels attached to the frame stack above the shadow
    Frames {}

    Bar {}

    LockScreen {}
}
