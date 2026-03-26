#!/usr/bin/env python3
import json
import sys


def dig(obj, path):
    cur = obj
    for key in path:
        if not isinstance(cur, dict):
            return ""
        cur = cur.get(key)
    return cur if isinstance(cur, str) else ""


def parse_file_path(text):
    file_path = ""
    stripped = text.strip()

    try:
        data = json.loads(stripped)
        if isinstance(data, dict):
            candidates = [
                ["tool_input", "file_path"],
                ["tool_input", "path"],
                ["file_path"],
                ["path"],
                ["params", "file_path"],
                ["params", "path"],
                ["event", "tool_input", "file_path"],
                ["event", "tool_input", "path"],
                ["event", "file_path"],
                ["event", "path"],
            ]
            for path in candidates:
                value = dig(data, path)
                if value:
                    file_path = value
                    break
    except Exception:
        if stripped.startswith("/"):
            file_path = stripped

    return file_path


if __name__ == "__main__":
    raw = sys.stdin.read()
    print(parse_file_path(raw))
