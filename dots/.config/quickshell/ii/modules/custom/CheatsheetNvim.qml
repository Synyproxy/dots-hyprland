pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import qs.services.custom

Item {
    id: root
    readonly property var keybinds: NVimKeybinds.keybinds
    property real spacing: 20
    property real titleSpacing: 7
    property real padding: 4
    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: row.implicitHeight + padding * 2
    property var symbolMap: ({
            "[ld]": "󱁐",
            "[ctrl]": "^",
            "[shift]": "⇧",
            "Key_left": "←",
            "Key_right": "→",
            "Key_up": "↑",
            "Key_down": "↓",
            "[term]": "[term]"
        })
    Row {
        id: row
        spacing: root.spacing

        Repeater {
            model: keybinds.children

            delegate: Column {
                //Keybind Sections
                spacing: root.spacing
                required property var modelData
                anchors.top: row.top

                Repeater {
                    model: modelData.children

                    delegate: Item {
                        //Section with real keybinds
                        id: keybindSection
                        required property var modelData
                        implicitWidth: sectionColumn.implicitWidth
                        implicitHeight: sectionColumn.implicitHeight

                        Column {
                            id: sectionColumn
                            anchors.centerIn: parent
                            spacing: root.titleSpacing

                            StyledText {
                                id: sectionTitle
                                font {
                                    family: Appearance.font.family.title
                                    pixelSize: Appearance.font.pixelSize.title
                                    variableAxes: Appearance.font.variableAxes.title
                                }
                                color: Appearance.colors.colOnLayer0
                                text: keybindSection.modelData.name
                            }

                            GridLayout {
                                id: keybindGrid
                                columns: 2
                                columnSpacing: 4
                                rowSpacing: 4

                                Repeater {
                                    model: {
                                        var result = [];
                                        for (var i = 0; i < keybindSection.modelData.keybinds.length; i++) {
                                            const keybind = keybindSection.modelData.keybinds[i];

                                            let finalKeys = [];
                                            // Regex: Matches "[text]" OR any non-space character
                                            // \[.*?\]  -> Matches brackets and everything inside
                                            // |        -> OR
                                            // [^\s]    -> Any character that isn't a space
                                            let regex = /\[.*?\]|[^\s]/g;
                                            let matches = keybind.key.match(regex) || [];

                                            matches.forEach(match => {
                                                // Check if the match (like [ld] or [term]) is in our symbol map
                                                if (root.symbolMap[match]) {
                                                    finalKeys.push(root.symbolMap[match]);
                                                } else {
                                                    // If it's [term] and not in map, it stays "[term]"
                                                    // If it's "/", it stays "/"
                                                    finalKeys.push(match);
                                                }
                                            });

                                            // 2. Process Label (Swap arrows in descriptions)
                                            var cleanLabel = keybind.label || "";
                                            // We use a simple for-in loop for better compatibility with older QML engines
                                            for (var sym in root.symbolMap) {
                                                if (cleanLabel.indexOf(sym) !== -1) {
                                                    // This replaces all occurrences of the symbol (e.g., Key_left) with the icon (←)
                                                    cleanLabel = cleanLabel.split(sym).join(root.symbolMap[sym]);
                                                }
                                            }
                                            result.push({
                                                "type": "key",
                                                "keys": finalKeys
                                            });
                                            result.push({
                                                "type": "comment",
                                                "label": cleanLabel
                                            });
                                        }
                                        return result;
                                    }
                                    delegate: Item {
                                        required property var modelData
                                        implicitWidth: keybindLoader.implicitWidth
                                        implicitHeight: keybindLoader.implicitHeight
                                        Loader {
                                            id: keybindLoader
                                            sourceComponent: (modelData.type === "key") ? keysComponent : commentComponent
                                        }

                                        Component {
                                            id: keysComponent
                                            Row {
                                                spacing: 4

                                                Repeater {
                                                    model: modelData.keys
                                                    delegate: KeyboardKey {
                                                        required property var modelData
                                                        key: modelData
                                                        pixelSize: Config.options.cheatsheet.fontSize.key
                                                    }
                                                }

                                                /*
                                                StyledText {
                                                    id: keybindPlus
                                                    //visible: Config.options.cheatsheet.splitButtons && !keyBlacklist.includes(modelData.key) && modelData.mods.length > 0
                                                    text: modelData.key
                                                  }
                                                  */
                                                /*
                                                KeyboardKey {
                                                    id: keybindKey
                                                    //visible: Config.options.cheatsheet.splitButtons && !keyBlacklist.includes(modelData.key)
                                                    key: modelData.key
                                                    pixelSize: Config.options.cheatsheet.fontSize.key
                                                    color: Appearance.colors.colOnLayer0
                                                  }
                                                  */
                                            }
                                        }
                                        Component {
                                            id: commentComponent
                                            Item {
                                                id: commentItem
                                                implicitWidth: commentText.implicitWidth + 8 * 2
                                                implicitHeight: commentText.implicitHeight

                                                StyledText {
                                                    id: commentText
                                                    anchors.centerIn: parent
                                                    font.pixelSize: Config.options.cheatsheet.fontSize.comment
                                                    text: modelData.label
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
