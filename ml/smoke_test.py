"""End-to-end smoke test of the pipeline on a tiny synthetic dataset.

It does NOT produce a usable model. It only proves that prepare -> train ->
export -> evaluate run and that the files they write fit together. The
export is flagged ``release_ready: false`` so the app refuses it in release
builds.

Usage:
    python smoke_test.py --work /tmp/genderlens-smoke
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
RACES = ["White", "Black", "East Asian", "Indian"]


def make_fake_fairface(root: Path, n_train: int, n_val: int) -> None:
    rng = np.random.default_rng(0)
    for split, n in (("train", n_train), ("val", n_val)):
        (root / split).mkdir(parents=True, exist_ok=True)
        rows = ["file,age,gender,race,service_test"]
        for i in range(n):
            gender = "Male" if i % 2 else "Female"
            base = np.array([40, 60, 200] if gender == "Male" else [200, 60, 40], np.float32)
            img = np.clip(base + rng.normal(0, 25, (64, 64, 3)), 0, 255).astype(np.uint8)
            rel = f"{split}/{i}.jpg"
            Image.fromarray(img).save(root / rel, quality=90)
            rows.append(f"{rel},20-29,{gender},{RACES[i % len(RACES)]},True")
        (root / f"fairface_label_{split}.csv").write_text("\n".join(rows) + "\n")


def run(*cmd: str) -> None:
    print("+", " ".join(cmd), flush=True)
    subprocess.run([sys.executable, *cmd], cwd=HERE, check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", type=Path, required=True)
    args = ap.parse_args()
    w = args.work.resolve()

    make_fake_fairface(w / "fairface", 160, 40)
    run("prepare_fairface.py", "--fairface-dir", str(w / "fairface"), "--out", str(w / "splits"))
    run("train.py", "--splits", str(w / "splits"), "--out", str(w / "run"), "--arch", "small",
        "--weights", "none", "--batch", "16", "--head-epochs", "1", "--epochs", "1")
    run("export_tflite.py", "--model", str(w / "run/best.keras"), "--splits", str(w / "splits"),
        "--out", str(w / "run"), "--allow-untrained", "--max-diff", "0.05")
    run("evaluate.py", "--tflite", str(w / "run/gender_classifier.tflite"), "--splits", str(w / "splits"),
        "--out", str(w / "run"))

    meta = json.loads((w / "run/model_meta.json").read_text())
    assert meta["release_ready"] is False
    assert meta["output"]["labels"] == ["female", "male"]
    print("smoke test OK")


if __name__ == "__main__":
    main()
