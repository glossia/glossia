"""Prepare Toki's transparent poses and articulated rig for both native apps.

Run with Pillow: python3 mobile/native/resources/prepare_toki.py
Builds consume checked-in images and do not need Python or an image service.
"""

import json
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
POSES = ("wave", "curious", "delighted", "focused", "languages", "globe")


def write(pose, canvas):
    name = "Toki" + "".join(word.title() for word in pose.split("_"))
    directory = ROOT / f"ios/Resources/Assets.xcassets/{name}.imageset"
    directory.mkdir(parents=True, exist_ok=True)
    canvas.save(directory / f"{name}.png", optimize=True)
    (directory / "Contents.json").write_text(json.dumps({
        "images": [{"filename": f"{name}.png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")
    android = ROOT / "android/res/drawable-nodpi"
    android.mkdir(parents=True, exist_ok=True)
    canvas.save(android / f"toki_{pose}.png", optimize=True)


with Image.open(Path(__file__).with_name("toki-sheet.png")) as sheet:
    assert sheet.mode == "RGBA" and sheet.getchannel("A").getextrema()[0] == 0
    for index, pose in enumerate(POSES):
        column, row = index % 3, index // 3
        cell = sheet.crop((column * sheet.width // 3, row * sheet.height // 2,
                           (column + 1) * sheet.width // 3, (row + 1) * sheet.height // 2))
        bounds = cell.getchannel("A").point(lambda value: 255 if value > 16 else 0).getbbox()
        sprite = ImageOps.contain(cell.crop(bounds), (352, 352), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (384, 384))
        canvas.alpha_composite(sprite, ((384 - sprite.width) // 2, (384 - sprite.height) // 2))
        write(pose, canvas)


# Like Atlas's Pip, the runtime moves transparent painted limbs around shoulder
# pivots, rather than rotating a photograph. All layers share a 512px canvas.
with Image.open(Path(__file__).with_name("toki-rig-sheet.png")) as sheet:
    assert sheet.mode == "RGBA" and sheet.getchannel("A").getextrema()[0] == 0
    layers = {}
    for name, bounds, size, position in (
        ("body", (0, 0, 715, 1024), (264, 360), None),
        ("left_arm", (720, 300, 1090, 800), (108, 146), (42, 244)),
        ("right_arm", (1120, 300, 1536, 800), (108, 146), (363, 244)),
    ):
        part = sheet.crop(bounds)
        alpha = part.getchannel("A")
        bounds = alpha.point(lambda value: 255 if value >= 32 else 0).getbbox()
        assert bounds is not None, name
        part = ImageOps.contain(part.crop(bounds), size, Image.Resampling.LANCZOS)
        part.putalpha(part.getchannel("A").point(lambda value: min(255, round(value * 255 / 254))))
        canvas = Image.new("RGBA", (512, 512))
        canvas.alpha_composite(part, position or ((512 - part.width) // 2, 76))
        layers[name] = canvas
        write(name, canvas)

    for pose, left, right in (
        ("curious", 0, 0), ("wave", 8, -115),
        ("delighted", 115, -115), ("focused", -6, 6),
    ):
        canvas = Image.new("RGBA", (512, 512))
        for name, angle, pivot in (
            ("left_arm", left, (137, 250)), ("right_arm", right, (375, 250)),
        ):
            canvas.alpha_composite(layers[name].rotate(-angle, Image.Resampling.BICUBIC, center=pivot))
        canvas.alpha_composite(layers["body"])
        write(pose, canvas)
