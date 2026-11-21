#!/usr/bin/env python3
"""Pre-release checks. Run before every store build:

    python3 scripts/check_release.py

Fails (exit 1) when something would get the build rejected or ship a
broken / non-compliant app.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"
PLACEHOLDER_ID = "com.yourcompany.genderlens"

errors: list[str] = []
warnings: list[str] = []


def check_model() -> None:
    model = APP / "assets/models/gender_classifier.tflite"
    meta_path = APP / "assets/models/model_meta.json"
    if not model.exists() or not meta_path.exists():
        errors.append("model missing: train it (see ml/README.md) and copy both files to app/assets/models/")
        return
    meta = json.loads(meta_path.read_text())
    if not meta.get("release_ready"):
        errors.append("model_meta.json has release_ready=false (smoke-test model?)")
    digest = hashlib.sha256(model.read_bytes()).hexdigest()
    if meta.get("sha256") != digest:
        errors.append("model_meta.json sha256 does not match gender_classifier.tflite (files from different runs?)")
    size_mb = model.stat().st_size / 1e6
    if size_mb > 20:
        warnings.append(f"model is {size_mb:.1f} MB; consider --quant int8")


def check_legal() -> None:
    for f in sorted((APP / "assets/legal").glob("*.md")):
        left = sorted(set(re.findall(r"\[[A-Z_]{4,}\]", f.read_text(encoding="utf-8"))))
        if left:
            errors.append(f"{f.relative_to(ROOT)} still has placeholders: {', '.join(left)}")
    for f in sorted((ROOT / "store").rglob("*.txt")):
        if re.search(r"\[[A-Z_]{4,}\]", f.read_text(encoding="utf-8")):
            errors.append(f"{f.relative_to(ROOT)} still has placeholders")


def check_ids() -> None:
    for f in (APP / "android/app/build.gradle.kts", APP / "ios/Runner.xcodeproj/project.pbxproj"):
        if PLACEHOLDER_ID in f.read_text():
            errors.append(f"{f.relative_to(ROOT)} still uses the placeholder id {PLACEHOLDER_ID}")


def check_android_signing() -> None:
    if not (APP / "android/key.properties").exists():
        warnings.append("android/key.properties not found; release build needs ANDROID_KEYSTORE_* env vars")


def check_version() -> None:
    m = re.search(r"^version:\s*(\S+)", (APP / "pubspec.yaml").read_text(), re.M)
    if not m or "+" not in m.group(1):
        errors.append("pubspec.yaml version must look like 1.2.3+45 (name+build number)")


def main() -> None:
    check_model()
    check_legal()
    check_ids()
    check_android_signing()
    check_version()
    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"ERROR:   {e}")
    if errors:
        print(f"\n{len(errors)} problem(s); not ready for release.")
        sys.exit(1)
    print("release checks passed")


if __name__ == "__main__":
    main()
