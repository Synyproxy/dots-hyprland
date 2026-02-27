pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * A service that provies nvim keybinds
 * Run the get_nvim_keybinds.py to get the keybinds in json
 */

Singleton {
    id: root
    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/custom/get_nvim_keybinds.py`)
    property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/nvim/keybinds.config`)

    property var defaultKeybinds: {
        "children": []
    }
    property var keybinds: ({
            "children": defaultKeybinds.children ?? []
        })

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreload") {
                getDefaultKeybinds.running = false;
            }
        }
    }

    Component.onCompleted: {
        console.error("Loaded");
    }

    Process {
        id: getDefaultKeybinds
        running: true
        command: ["python3", root.keybindParserPath, "--path", root.defaultKeybindConfigPath]

        stdout: SplitParser {
            onRead: data => {
                try {
                    console.error("Read File");
                    root.defaultKeybinds = JSON.parse(data);
                } catch (e) {
                    console.error("[Nvim CheatsheetKeybinds] Error Parsing: ", e);
                }
            }
        }
    }
}
