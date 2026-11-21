"""Export the trained Keras model to TFLite and write model_meta.json.

Default is float16 weights (about half the float32 size, accuracy unchanged,
runs on the CPU and on the GPU/Core ML delegates). ``--quant int8`` produces
a smaller dynamic-range model using a representative dataset.

The script checks that the TFLite output matches Keras on real validation
images before writing anything, then optionally copies both files into the
Flutter app's assets folder.

Usage:
    python export_tflite.py --model runs/v1/best.keras --splits data/splits \
        --out runs/v1 --install ../app/assets/models
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf

from common import CROP_SCALE, IMG_SIZE, INPUT_RANGE, LABELS, write_json
from train import make_dataset

MODEL_FILE = "gender_classifier.tflite"
META_FILE = "model_meta.json"


def convert(model: tf.keras.Model, quant: str, rep_df: pd.DataFrame) -> bytes:
    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    if quant == "float16":
        conv.optimizations = [tf.lite.Optimize.DEFAULT]
        conv.target_spec.supported_types = [tf.float16]
    elif quant == "int8":
        def representative():
            for x, _ in make_dataset(rep_df, 1, False, 0).take(300):
                yield [x]
        conv.optimizations = [tf.lite.Optimize.DEFAULT]
        conv.representative_dataset = representative
        # Integer kernels inside, float32 input/output so the app code is identical.
    elif quant != "float32":
        raise ValueError(quant)
    return conv.convert()


def tflite_predict(model_bytes: bytes, batch: np.ndarray) -> np.ndarray:
    interp = tf.lite.Interpreter(model_content=model_bytes)
    interp.allocate_tensors()
    inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
    res = []
    for x in batch:
        interp.set_tensor(inp["index"], x[None].astype(np.float32))
        interp.invoke()
        res.append(interp.get_tensor(out["index"])[0])
    return np.stack(res)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--model", type=Path, required=True)
    ap.add_argument("--splits", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--quant", choices=["float32", "float16", "int8"], default="float16")
    ap.add_argument("--version", default=datetime.now(timezone.utc).strftime("%Y.%m.%d"))
    ap.add_argument("--max-diff", type=float, default=0.03,
                    help="max allowed |p_keras - p_tflite| on the parity batch")
    ap.add_argument("--install", type=Path, help="copy the exported files into this directory")
    ap.add_argument("--allow-untrained", action="store_true",
                    help="smoke tests only: mark the export as NOT for release")
    args = ap.parse_args()

    model = tf.keras.models.load_model(args.model)
    val_df = pd.read_csv(args.splits / "val.csv")
    blob = convert(model, args.quant, val_df)

    xs = np.concatenate([x.numpy() for x, _ in make_dataset(val_df.head(64), 16, False, 0)])
    diff = float(np.abs(model.predict(xs, verbose=0) - tflite_predict(blob, xs)).max())
    print(f"parity check on {len(xs)} images: max |diff| = {diff:.5f}")
    if diff > args.max_diff:
        print(f"parity check failed (> {args.max_diff}); not exporting", file=sys.stderr)
        sys.exit(1)

    args.out.mkdir(parents=True, exist_ok=True)
    model_path = args.out / MODEL_FILE
    model_path.write_bytes(blob)
    meta = {
        "schema": 1,
        "name": "genderlens-gender-classifier",
        "version": args.version,
        "release_ready": not args.allow_untrained,
        "input": {"width": IMG_SIZE, "height": IMG_SIZE, "channels": 3, "order": "RGB",
                  "range": list(INPUT_RANGE)},
        "output": {"type": "softmax", "labels": list(LABELS)},
        "face_crop_scale": CROP_SCALE,
        "uncertain_below": 0.70,
        "quantization": args.quant,
        "sha256": hashlib.sha256(blob).hexdigest(),
        "training_data": "FairFace (CC BY 4.0), https://github.com/joojs/fairface",
    }
    write_json(args.out / META_FILE, meta)
    print(f"wrote {model_path} ({len(blob) / 1e6:.2f} MB) and {META_FILE}")

    if args.install:
        args.install.mkdir(parents=True, exist_ok=True)
        shutil.copy2(model_path, args.install / MODEL_FILE)
        shutil.copy2(args.out / META_FILE, args.install / META_FILE)
        print(f"installed into {args.install}")


if __name__ == "__main__":
    main()
