pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    Process {
        id: vpnStatusProcess
        command: ["sh", "-c", "ip addr show wg0 | grep -q 'state UP\\|state UNKNOWN'"]
        running: true
        onExited: exitCode => {
            root.active = (exitCode === 0);
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            vpnStatusProcess.running = false;
            vpnStatusProcess.running = true;
        }
    }

    function toggle() {
        const action = root.active ? "down" : "up";
        Quickshell.execDetached(["nmcli", "connection", action, "wg0"]);
    }
}
