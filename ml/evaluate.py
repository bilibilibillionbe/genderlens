"""Evaluate a trained model (Keras or the exported TFLite file) on the test split.

Reports overall accuracy, accuracy broken down by race / age / gender, the
expected calibration error, and how often the app would show "uncertain" at
the confidence threshold it uses. With --gate the script exits non-zero when
quality or fairness targets are missed, so it can be used as a release check.

Usage:
    python evaluate.py --model runs/v1/best.keras --splits data/splits --out runs/v1
    python evaluate.py --tflite runs/v1/gender_classifier.tflite --splits data/splits --out runs/v1 --gate
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf

from common import AGE_COLUMN, GENDER_COLUMN, LABELS, RACE_COLUMN, write_json
from train import make_dataset


def predict_keras(path: Path, df: pd.DataFrame, batch: int) -> np.ndarray:
    model = tf.keras.models.load_model(path)
    return model.predict(make_dataset(df, batch, False, 0), verbose=0)


def predict_tflite(path: Path, df: pd.DataFrame) -> np.ndarray:
    interp = tf.lite.Interpreter(model_path=str(path))
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    probs = []
    for x, _ in make_dataset(df, 1, False, 0):
        x = x.numpy()
        if inp["dtype"] != np.float32:  # fully integer model
            scale, zero = inp["quantization"]
            x = np.clip(np.round(x / scale + zero), np.iinfo(inp["dtype"]).min,
                        np.iinfo(inp["dtype"]).max).astype(inp["dtype"])
        interp.set_tensor(inp["index"], x)
        interp.invoke()
        y = interp.get_tensor(out["index"])
        if out["dtype"] != np.float32:
            scale, zero = out["quantization"]
            y = (y.astype(np.float32) - zero) * scale
        probs.append(y[0])
    return np.stack(probs)


def expected_calibration_error(conf: np.ndarray, correct: np.ndarray, bins: int = 15) -> float:
    edges = np.linspace(0.5, 1.0, bins + 1)  # binary: confidence is always >= 0.5
    ece = 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (conf > lo) & (conf <= hi) if lo > 0.5 else (conf >= lo) & (conf <= hi)
        if m.any():
            ece += m.mean() * abs(correct[m].mean() - conf[m].mean())
    return float(ece)


def group_table(df: pd.DataFrame, column: str) -> dict:
    out = {}
    for key, g in df.groupby(column):
        out[str(key)] = {"n": int(len(g)), "accuracy": round(float(g["correct"].mean()), 4)}
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--model", type=Path, help=".keras model")
    src.add_argument("--tflite", type=Path, help=".tflite model")
    ap.add_argument("--splits", type=Path, required=True)
    ap.add_argument("--split", default="test")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--batch", type=int, default=64)
    ap.add_argument("--threshold", type=float, default=0.70,
                    help="confidence below this is shown as 'uncertain' in the app")
    ap.add_argument("--gate", action="store_true", help="exit 1 if targets below are missed")
    ap.add_argument("--min-accuracy", type=float, default=0.92)
    ap.add_argument("--max-group-gap", type=float, default=0.06,
                    help="max allowed accuracy gap between best and worst race group")
    ap.add_argument("--max-ece", type=float, default=0.05)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    df = pd.read_csv(args.splits / f"{args.split}.csv")
    if args.limit:
        df = df.sample(min(args.limit, len(df)), random_state=0)

    probs = predict_keras(args.model, df, args.batch) if args.model else predict_tflite(args.tflite, df)
    pred = probs.argmax(1)
    conf = probs.max(1)
    df = df.assign(pred=pred, conf=conf, correct=(pred == df["label"].values))
    confident = conf >= args.threshold

    race_acc = group_table(df, RACE_COLUMN)
    accs = [v["accuracy"] for v in race_acc.values() if v["n"] >= 30] or [v["accuracy"] for v in race_acc.values()]
    report = {
        "model": str(args.model or args.tflite),
        "split": args.split,
        "n": int(len(df)),
        "accuracy": round(float(df["correct"].mean()), 4),
        "ece": round(expected_calibration_error(conf, df["correct"].values), 4),
        "threshold": args.threshold,
        "uncertain_rate": round(float(1 - confident.mean()), 4),
        "accuracy_when_confident": round(float(df.loc[confident, "correct"].mean()), 4) if confident.any() else None,
        "race_group_gap": round(float(max(accs) - min(accs)), 4),
        "confusion": {
            f"true_{t}": {f"pred_{p}": int(((df['label'] == i) & (df['pred'] == j)).sum())
                          for j, p in enumerate(LABELS)}
            for i, t in enumerate(LABELS)
        },
        "by_gender": group_table(df, GENDER_COLUMN),
        "by_race": race_acc,
        "by_age": group_table(df, AGE_COLUMN),
    }

    name = (args.model or args.tflite).stem
    write_json(args.out / f"eval_{name}_{args.split}.json", report)
    md = [f"# Evaluation: `{name}` on `{args.split}` (n={report['n']})", "",
          f"- accuracy: **{report['accuracy']:.2%}**",
          f"- ECE: {report['ece']:.3f}",
          f"- uncertain (< {args.threshold:.0%}): {report['uncertain_rate']:.2%}; accuracy on the rest: "
          f"{report['accuracy_when_confident']}",
          f"- race group accuracy gap: {report['race_group_gap']:.2%}", ""]
    for title, key in (("Race", "by_race"), ("Age", "by_age"), ("Gender", "by_gender")):
        md += [f"## {title}", "", "| group | n | accuracy |", "|---|---:|---:|"]
        md += [f"| {k} | {v['n']} | {v['accuracy']:.2%} |" for k, v in report[key].items()]
        md.append("")
    (args.out / f"eval_{name}_{args.split}.md").write_text("\n".join(md), encoding="utf-8")
    print("\n".join(md))

    if args.gate:
        failures = []
        if report["accuracy"] < args.min_accuracy:
            failures.append(f"accuracy {report['accuracy']:.4f} < {args.min_accuracy}")
        if report["race_group_gap"] > args.max_group_gap:
            failures.append(f"race gap {report['race_group_gap']:.4f} > {args.max_group_gap}")
        if report["ece"] > args.max_ece:
            failures.append(f"ECE {report['ece']:.4f} > {args.max_ece}")
        if failures:
            print("RELEASE GATE FAILED:\n  " + "\n  ".join(failures), file=sys.stderr)
            sys.exit(1)
        print("release gate passed")


if __name__ == "__main__":
    main()
