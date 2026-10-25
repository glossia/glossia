#!/usr/bin/env python3
"""Extract native English resources without translating server/user content.

Apple's extractor owns SwiftUI and String(localized:) format strings. Android's
programmatic Views use nativeText for static copy and nativeFormat for arguments.
Keep the generated English tables in version control; translated outputs are owned
by Glossia and are never overwritten here.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def resource_name(value):
    return "native_" + hashlib.sha256(value.encode()).hexdigest()[:16]


def android_strings():
    entries = {value: {"android/res/menu", "android/res/layout"} for value in ["Glossia", "Toki", "Translations", "Analytics", "Profile", "Compose", "Choose workspace", "Refresh", "Loading workspace"]}
    # These count labels deliberately remain lowercase in their format template.
    for value in ["checked", "planned", "up to date", "running", "queued", "awaiting linguistic input", "failed", "cancelled"]:
        entries[value] = {"android/src/ai/glossia/mobile/FeatureViews.kt"}
    for path in sorted((ROOT / "android/src").rglob("*.kt")):
        source = path.read_text()
        for match in re.finditer(r'"(?:\\.|[^"\\])*"', source):
            literal = match.group()
            if re.search(r"(?<!\\)\$", literal):
                continue
            try:
                value = json.loads(literal.replace("\\$", "$"))
            except ValueError:
                continue
            explicit = re.search(r"(?:nativeText|nativeFormat)\(\s*$", source[max(0, match.start() - 50):match.start()])
            if not explicit and (not re.match(r"[A-Z][A-Za-z0-9]*(?:[ ,.!?…:]|$)|or$", value) or re.search(r"[._/=:]", value.split(" ")[0])):
                continue
            entries.setdefault(value, set()).add(str(path.relative_to(ROOT)))
    table = ET.Element("resources")
    for value, origins in sorted(entries.items()):
        table.append(ET.Comment(" " + ", ".join(sorted(origins)) + " "))
        item = ET.SubElement(table, "string", {"name": resource_name(value), "formatted": "false"})
        # Android's quoted form preserves whitespace and apostrophes.
        item.text = '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    ET.indent(table, space="    ")
    output = ROOT / "android/res/values/strings.xml"
    ET.ElementTree(table).write(output, encoding="utf-8", xml_declaration=True)
    print(f"Android: {len(entries)} source strings → {output.relative_to(ROOT)}")


def apple_strings():
    sources = sorted((ROOT / "ios/Sources").glob("*.swift")) + sorted((ROOT / "ios/LiveActivity").glob("*.swift"))
    with tempfile.TemporaryDirectory(prefix="glossia-strings-") as directory:
        staged = []
        for source in sources:
            path = Path(directory) / source.name
            # genstrings predates Swift's braced Unicode escapes.
            path.write_text(re.sub(r"\\u\{([0-9a-fA-F]+)\}", lambda m: chr(int(m[1], 16)), source.read_text()))
            staged.append(str(path))
        result = subprocess.run(["xcrun", "extractLocStrings", "-u", "-SwiftUI", "-o", directory, *staged], capture_output=True, text=True, check=True)
        diagnostics = result.stderr.splitlines()
        if any("Argument is not a literal string" not in line for line in diagnostics):
            raise RuntimeError(result.stderr)
        output = ROOT / "ios/Resources/en.lproj/Localizable.strings"
        output.parent.mkdir(parents=True, exist_ok=True)
        extracted = (Path(directory) / "Localizable.strings").read_text(encoding="utf-16")
        # Dynamic UIKit/model strings and String(localized:) are outside the old
        # genstrings SwiftUI recognizer. Include their static source copy too.
        supplemental = {"An update is ready. Open Glossia to view it.": "Fixed notification alert; available for future APNs loc-key payloads"}
        for path in sources:
            for match in re.finditer(r'"(?:\\.|[^"\\])*"', path.read_text()):
                literal = match.group()
                if "\\(" in literal:
                    continue
                try:
                    value = json.loads(literal)
                except ValueError:
                    continue
                if re.match(r"[A-Z][a-z]|[A-Z]{2,} |or$", value) and not re.search(r"[._/=:]", value.split(" ")[0]):
                    supplemental[value] = path.name
        for value, origin in sorted(supplemental.items()):
            key = json.dumps(value, ensure_ascii=False)
            if re.search(r"^" + re.escape(key) + r"\s*=", extracted, re.MULTILINE):
                continue
            extracted += f"\n/* {origin}: static UI/model copy */\n{key} = {key};\n"
        output.write_text(extracted)
        subprocess.run(["plutil", "-lint", str(output)], check=True)
        print(f"iOS: SwiftUI + static UI/model copy → {output.relative_to(ROOT)} ({len(diagnostics)} dynamic expressions skipped)")


if __name__ == "__main__":
    android_strings()
    apple_strings()
