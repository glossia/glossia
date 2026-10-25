import plistlib
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class ExtractionTests(unittest.TestCase):
    def test_check_detects_source_changes_without_writing_catalogs_or_translations(self):
        with tempfile.TemporaryDirectory(prefix="glossia-extraction-test-") as directory:
            root = Path(directory)
            script = root / "tools/extract_localizations.py"
            script.parent.mkdir()
            shutil.copyfile(Path(__file__).with_name("extract_localizations.py"), script)
            swift = root / "ios/Sources/Example.swift"
            kotlin = root / "android/src/Example.kt"
            swift.parent.mkdir(parents=True)
            kotlin.parent.mkdir(parents=True)
            swift.write_text('import SwiftUI\nstruct Example: View { var body: some View { Text("Review translation") } }\n')
            kotlin.write_text('fun example() { nativeText("Choose a language") }\n')
            info = root / "ios/Info.plist"
            info.write_bytes(plistlib.dumps({"NSMicrophoneUsageDescription": "Dictate your message."}))
            catalogs = [
                root / "ios/Resources/en.lproj/Localizable.strings",
                root / "ios/Resources/en.lproj/InfoPlist.strings",
                root / "android/res/values/strings.xml",
            ]
            translations = [
                root / "ios/Resources/es.lproj/Localizable.strings",
                root / "locales/es/android/strings.xml",
            ]
            for translated in translations:
                translated.parent.mkdir(parents=True)
                translated.write_bytes(b"preserve translated content")

            def run(*args):
                return subprocess.run([sys.executable, "-B", str(script), *args], capture_output=True, text=True)

            missing = run("--check")
            self.assertNotEqual(missing.returncode, 0, missing.stdout + missing.stderr)
            self.assertTrue(all(not catalog.exists() for catalog in catalogs))
            extracted = run()
            self.assertEqual(extracted.returncode, 0, extracted.stdout + extracted.stderr)
            original = {path: (path.read_bytes(), path.stat().st_mtime_ns) for path in catalogs + translations}
            self.assertEqual(run("--check").returncode, 0)

            swift.write_text(swift.read_text().replace("Review translation", "Discuss translation"))
            kotlin.write_text(kotlin.read_text().replace("Choose a language", "Choose fluent languages"))
            info.write_bytes(plistlib.dumps({"NSMicrophoneUsageDescription": "Dictate an editable draft."}))
            stale = run("--check")
            self.assertNotEqual(stale.returncode, 0, stale.stdout + stale.stderr)
            for catalog in catalogs:
                self.assertIn(str(catalog.relative_to(root)), stale.stderr)
            for path, expected in original.items():
                self.assertEqual((path.read_bytes(), path.stat().st_mtime_ns), expected)

            refreshed = run()
            self.assertEqual(refreshed.returncode, 0, refreshed.stdout + refreshed.stderr)
            self.assertEqual(run("--check").returncode, 0)
            for catalog in catalogs:
                self.assertNotEqual(catalog.read_bytes(), original[catalog][0])
            for translated in translations:
                self.assertEqual(translated.read_bytes(), original[translated][0])


if __name__ == "__main__":
    unittest.main()
