#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
import argparse
import re
import os
from os.path import expandvars as os_expandvars
from typing import Dict, List

TITLE_REGEX = "#+!"
COMMENT_BIND_PATTERN = "#/#"

parser = argparse.ArgumentParser(description="Nvim keybind reader")
parser.add_argument(
    "--path",
    type=str,
    default="$HOME/.config/nvim/keybinds.config",
    help="path to nvim keybinds file",
)

args = parser.parse_args()
content_lines = []
reading_line = 0


class KeyBinding(dict):
    def __init__(self, key, label) -> None:
        self["key"] = key
        self["label"] = label


class Section(dict):
    def __init__(self, children, keybinds, name) -> None:
        self["children"] = children
        self["keybinds"] = keybinds
        self["name"] = name


def read_content(path: str) -> str:
    if not os.access(os.path.expanduser(os.path.expandvars(path)), os.R_OK):
        return "error"
    with open(os.path.expanduser(os.path.expandvars(path)), "r") as file:
        return file.read()


def get_keybind_at_line(line_number, line_start=0):
    global content_lines
    line = content_lines[line_number]
    match = re.search(r"![KC]\s*=\s*(.*?)\s*!D\s*=\s*(.*)", line)

    if match:
        key = match.group(1).strip()
        label = match.group(2).strip()
        return KeyBinding(key, label)

    return None


def get_binds_recursive(current_content, scope):
    global content_lines
    global reading_line

    # print(
    # "get_binds_recursive({0}, {1}) [@L{2}]".format(
    #    current_content, scope, reading_line + 1
    # )
    # )

    while reading_line < len(content_lines):
        line = content_lines[reading_line]
        heading_search_result = re.search(TITLE_REGEX, line)
        if (heading_search_result != None) and (heading_search_result.start() == 0):
            # Found Title
            heading_scope = line.find("!")
            # print("scope: {0} line {1}".format(heading_scope, line))
            if heading_scope <= scope:
                # print("heading_scope: {0} scope {1}".format(heading_scope, scope))
                reading_line -= 1
                return current_content
            section_name = line[(heading_scope + 1) :].strip()
            # print("Section Name {0}".format(section_name))
            reading_line += 1
            current_content["children"].append(
                get_binds_recursive(Section([], [], section_name), heading_scope)
            )
        else:
            keybind = get_keybind_at_line(reading_line)
            if keybind != None:
                current_content["keybinds"].append(keybind)

        reading_line += 1

    return current_content


def parse_keys(path: str) -> Dict[str, List[KeyBinding]]:
    global content_lines
    content_lines = read_content(path).splitlines()
    if content_lines[0] == "error":
        return {}
    return get_binds_recursive(Section([], [], ""), 0)


if __name__ == "__main__":
    import json

    ParseKeys = parse_keys(args.path)
    print(json.dumps(ParseKeys))
