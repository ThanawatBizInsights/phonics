#!/usr/bin/env python3
"""Parses every Swift file with tree-sitter and reports syntax errors.

This is a structural check only (it is not the Swift compiler): it catches unbalanced
braces, malformed declarations and similar mistakes on machines without Xcode.
Requires: pip install tree-sitter tree-sitter-language-pack
"""
import os, sys
from tree_sitter_language_pack import get_parser

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
parser = get_parser("swift")
bad = 0
count = 0
for base in ("PhonicsPond/PhonicsPond", "PhonicsPond/PhonicsPondTests", "PhonicsPond/PhonicsPondUITests"):
    for path, _, files in os.walk(os.path.join(ROOT, base)):
        for f in sorted(files):
            if not f.endswith(".swift"):
                continue
            count += 1
            full = os.path.join(path, f)
            src = open(full, "rb").read()
            tree = parser.parse(src)
            errors = []
            def walk(node):
                if node.type == "ERROR" or node.is_missing:
                    errors.append(node)
                for child in node.children:
                    walk(child)
            walk(tree.root_node)
            if errors:
                bad += 1
                rel = os.path.relpath(full, ROOT)
                for e in errors[:5]:
                    line = e.start_point[0] + 1
                    snippet = src.splitlines()[e.start_point[0]].decode("utf-8", "replace").strip()
                    print(f"{rel}:{line}: {'missing ' + e.type if e.is_missing else 'syntax error'}: {snippet[:100]}")
print(f"{count} Swift files parsed, {bad} with syntax errors")
sys.exit(1 if bad else 0)
