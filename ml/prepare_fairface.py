"""Turn the raw FairFace download into train/val/test CSVs.

FairFace (https://github.com/joojs/fairface) is released under CC BY 4.0,
which allows commercial use with attribution. It ships a train split and a
val split; we hold out part of train for validation and use the official val
split as the untouched test set.

Expected layout (the "padding=0.25" release):

    <fairface_dir>/
        train/1.jpg ...
        val/1.jpg ...
        fairface_label_train.csv
        fairface_label_val.csv

Usage:
    python prepare_fairface.py --fairface-dir data/fairface --out data/splits
"""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd
from sklearn.model_selection import train_test_split

from common import AGE_COLUMN, FILE_COLUMN, GENDER_COLUMN, RACE_COLUMN, gender_to_index


def load(csv_path: Path, root: Path) -> pd.DataFrame:
    df = pd.read_csv(csv_path)
    missing = {FILE_COLUMN, GENDER_COLUMN, RACE_COLUMN, AGE_COLUMN} - set(df.columns)
    if missing:
        raise SystemExit(f"{csv_path} is missing columns: {sorted(missing)}")
    df["path"] = df[FILE_COLUMN].map(lambda f: str((root / f).resolve()))
    df["label"] = df[GENDER_COLUMN].map(gender_to_index)
    exists = df["path"].map(lambda p: Path(p).is_file())
    if not exists.all():
        print(f"warning: {int((~exists).sum())} images listed in {csv_path.name} not found, skipping")
        df = df[exists]
    return df[["path", "label", GENDER_COLUMN, RACE_COLUMN, AGE_COLUMN]]


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--fairface-dir", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--val-fraction", type=float, default=0.1)
    ap.add_argument("--seed", type=int, default=1337)
    args = ap.parse_args()

    root = args.fairface_dir
    train_all = load(root / "fairface_label_train.csv", root)
    test = load(root / "fairface_label_val.csv", root)

    # Stratify on gender x race so validation mirrors the training mix.
    strata = train_all[GENDER_COLUMN] + "|" + train_all[RACE_COLUMN]
    train, val = train_test_split(
        train_all, test_size=args.val_fraction, random_state=args.seed, stratify=strata
    )

    args.out.mkdir(parents=True, exist_ok=True)
    for name, df in (("train", train), ("val", val), ("test", test)):
        df.to_csv(args.out / f"{name}.csv", index=False)
        counts = df[GENDER_COLUMN].value_counts().to_dict()
        print(f"{name:5s}: {len(df):6d} images  {counts}")


if __name__ == "__main__":
    main()
