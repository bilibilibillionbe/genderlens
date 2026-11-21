"""Shared constants for the GenderLens training pipeline.

Everything the mobile app needs to know about the model (input size, value
range, label order, crop scale) is written to ``model_meta.json`` by
``export_tflite.py``. The app reads that file at runtime, so changing a value
here and re-exporting is enough to keep both sides consistent.
"""

from __future__ import annotations

import json
from pathlib import Path

IMG_SIZE = 224
# Index order of the softmax output. Do not reorder without re-training.
LABELS = ("female", "male")
# FairFace "padding=0.25" crops are the detector box grown by 25% on every
# side, i.e. 1.5x the box. The app grows the ML Kit box by the same factor.
CROP_SCALE = 1.5
# Keras MobileNetV3 with include_preprocessing=True expects raw 0..255 floats.
INPUT_RANGE = (0.0, 255.0)

# FairFace metadata used for the fairness breakdown in evaluate.py.
RACE_COLUMN = "race"
AGE_COLUMN = "age"
GENDER_COLUMN = "gender"
FILE_COLUMN = "file"


def gender_to_index(value: str) -> int:
    v = value.strip().lower()
    if v not in LABELS:
        raise ValueError(f"unknown gender label: {value!r}")
    return LABELS.index(v)


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
