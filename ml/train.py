"""Fine-tune a MobileNetV3 face-gender classifier.

Two stages:
  1. train only the new head with the ImageNet backbone frozen;
  2. unfreeze the backbone (BatchNorm stays frozen) and fine-tune with a
     cosine-decayed learning rate.

Usage:
    python train.py --splits data/splits --out runs/v1
    python train.py --splits data/splits --out runs/v1 --arch small --epochs 15
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf

from common import IMG_SIZE, LABELS

AUTOTUNE = tf.data.AUTOTUNE


def decode(path: tf.Tensor) -> tf.Tensor:
    raw = tf.io.read_file(path)
    img = tf.io.decode_image(raw, channels=3, expand_animations=False)
    img = tf.image.resize(img, (IMG_SIZE, IMG_SIZE), antialias=True)
    return tf.cast(img, tf.float32)  # 0..255, the model normalises internally


def build_augmenter(seed: int) -> tf.keras.Sequential:
    # Geometric jitter mimics the variation of the on-device detector box
    # (ML Kit boxes are not identical to the dlib boxes FairFace was cut with).
    return tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal", seed=seed),
            tf.keras.layers.RandomRotation(0.04, fill_mode="reflect", seed=seed),
            tf.keras.layers.RandomZoom((-0.15, 0.15), fill_mode="reflect", seed=seed),
            tf.keras.layers.RandomTranslation(0.08, 0.08, fill_mode="reflect", seed=seed),
        ],
        name="augment",
    )


def photometric(img: tf.Tensor) -> tf.Tensor:
    img = img / 255.0
    img = tf.image.random_brightness(img, 0.2)
    img = tf.image.random_contrast(img, 0.7, 1.3)
    img = tf.image.random_saturation(img, 0.6, 1.4)
    img = tf.image.random_hue(img, 0.03)
    # 10% grayscale so the model does not lean on colour cues (lighting, white balance).
    gray = tf.image.grayscale_to_rgb(tf.image.rgb_to_grayscale(img))
    img = tf.where(tf.random.uniform([]) < 0.1, gray, img)
    return tf.clip_by_value(img, 0.0, 1.0) * 255.0


def make_dataset(df: pd.DataFrame, batch: int, training: bool, seed: int) -> tf.data.Dataset:
    ds = tf.data.Dataset.from_tensor_slices((df["path"].values, df["label"].values.astype("int32")))
    if training:
        ds = ds.shuffle(len(df), seed=seed, reshuffle_each_iteration=True)
    ds = ds.map(lambda p, y: (decode(p), y), num_parallel_calls=AUTOTUNE)
    if training:
        aug = build_augmenter(seed)
        ds = ds.map(lambda x, y: (photometric(x), y), num_parallel_calls=AUTOTUNE)
        ds = ds.batch(batch, drop_remainder=True)
        ds = ds.map(lambda x, y: (aug(x, training=True), y), num_parallel_calls=AUTOTUNE)
    else:
        ds = ds.batch(batch)
    ds = ds.map(lambda x, y: (x, tf.one_hot(y, len(LABELS))), num_parallel_calls=AUTOTUNE)
    return ds.prefetch(AUTOTUNE)


def build_model(arch: str, weights: str | None, dropout: float) -> tuple[tf.keras.Model, tf.keras.Model]:
    ctor = {
        "large": tf.keras.applications.MobileNetV3Large,
        "small": tf.keras.applications.MobileNetV3Small,
    }[arch]
    backbone = ctor(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights=weights,
        pooling="avg",
        include_preprocessing=True,
    )
    inputs = tf.keras.Input((IMG_SIZE, IMG_SIZE, 3), name="image")
    x = backbone(inputs, training=False)  # keep BN in inference mode in both stages
    x = tf.keras.layers.Dropout(dropout)(x)
    outputs = tf.keras.layers.Dense(len(LABELS), activation="softmax", name="probs")(x)
    return tf.keras.Model(inputs, outputs, name=f"genderlens_mnv3{arch}"), backbone


def compile_model(model: tf.keras.Model, lr, smoothing: float) -> None:
    model.compile(
        optimizer=tf.keras.optimizers.AdamW(learning_rate=lr, weight_decay=1e-4),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=smoothing),
        metrics=[tf.keras.metrics.CategoricalAccuracy(name="acc"), tf.keras.metrics.AUC(name="auc")],
    )


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--splits", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--arch", choices=["large", "small"], default="large")
    ap.add_argument("--weights", default="imagenet", help="'imagenet' or 'none'")
    ap.add_argument("--batch", type=int, default=64)
    ap.add_argument("--head-epochs", type=int, default=3)
    ap.add_argument("--epochs", type=int, default=12, help="fine-tuning epochs")
    ap.add_argument("--lr", type=float, default=3e-4)
    ap.add_argument("--dropout", type=float, default=0.2)
    ap.add_argument("--label-smoothing", type=float, default=0.05)
    ap.add_argument("--limit", type=int, default=0, help="debug: use only N training images")
    ap.add_argument("--seed", type=int, default=1337)
    args = ap.parse_args()

    tf.keras.utils.set_random_seed(args.seed)
    args.out.mkdir(parents=True, exist_ok=True)

    train_df = pd.read_csv(args.splits / "train.csv")
    val_df = pd.read_csv(args.splits / "val.csv")
    if args.limit:
        train_df = train_df.sample(min(args.limit, len(train_df)), random_state=args.seed)
        val_df = val_df.sample(min(max(args.limit // 5, 1), len(val_df)), random_state=args.seed)
    batch = min(args.batch, len(train_df))

    train_ds = make_dataset(train_df, batch, True, args.seed)
    val_ds = make_dataset(val_df, batch, False, args.seed)

    counts = np.bincount(train_df["label"], minlength=len(LABELS)).astype(float)
    class_weight = {i: float(counts.sum() / (len(LABELS) * c)) for i, c in enumerate(counts) if c > 0}
    print("class counts", dict(zip(LABELS, counts.tolist())), "weights", class_weight)

    weights = None if args.weights.lower() == "none" else args.weights
    model, backbone = build_model(args.arch, weights, args.dropout)

    best_path = args.out / "best.keras"
    callbacks = [
        tf.keras.callbacks.ModelCheckpoint(best_path, monitor="val_acc", mode="max", save_best_only=True),
        tf.keras.callbacks.CSVLogger(str(args.out / "history.csv"), append=True),
    ]

    # Stage 1: head only.
    backbone.trainable = False
    compile_model(model, 1e-3, args.label_smoothing)
    model.fit(train_ds, validation_data=val_ds, epochs=args.head_epochs,
              class_weight=class_weight, callbacks=callbacks, verbose=2)

    # Stage 2: full fine-tune. BN layers stay frozen; small batches make their
    # statistics noisy and that hurts more than it helps here.
    backbone.trainable = True
    for layer in backbone.layers:
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False
    steps = max(1, args.epochs * len(train_ds))
    schedule = tf.keras.optimizers.schedules.CosineDecay(args.lr, decay_steps=steps, alpha=0.02)
    compile_model(model, schedule, args.label_smoothing)
    callbacks.append(tf.keras.callbacks.EarlyStopping(monitor="val_acc", mode="max", patience=4,
                                                      restore_best_weights=True))
    model.fit(train_ds, validation_data=val_ds, initial_epoch=args.head_epochs,
              epochs=args.head_epochs + args.epochs, class_weight=class_weight,
              callbacks=callbacks, verbose=2)

    if not best_path.exists():
        model.save(best_path)
    (args.out / "train_args.json").write_text(json.dumps(vars(args), default=str, indent=2))
    print(f"saved best model to {best_path}")


if __name__ == "__main__":
    main()
