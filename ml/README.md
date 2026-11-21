# Training the model

This folder produces the two files the app ships with:

- `app/assets/models/gender_classifier.tflite`: MobileNetV3 classifier, 224×224 RGB in, `[p_female, p_male]` out
- `app/assets/models/model_meta.json`: input format, label order, crop scale, threshold and version, read by the app at startup

## 1. Get the data

Use **FairFace** (Kärkkäinen & Joo, WACV 2021), licensed **CC BY 4.0**. It allows commercial use with attribution (the app credits it on its licences screen). It is balanced across 7 ethnic groups, which matters a lot for fairness. Many popular face datasets (CelebA, UTKFace, Adience, IMDB-WIKI) are **non-commercial only**, so do not use them for a store build.

1. Download the **padding = 0.25** images and the two label CSVs from https://github.com/joojs/fairface
2. Unzip so you have:

```
ml/data/fairface/train/*.jpg
ml/data/fairface/val/*.jpg
ml/data/fairface/fairface_label_train.csv
ml/data/fairface/fairface_label_val.csv
```

## 2. Install

```bash
cd ml
python3 -m venv .venv
```

```bash
source .venv/bin/activate
```

```bash
pip install -r requirements.txt
```

## 3. Run the pipeline

```bash
python prepare_fairface.py --fairface-dir data/fairface --out data/splits
```

```bash
python train.py --splits data/splits --out runs/v1
```

```bash
python export_tflite.py --model runs/v1/best.keras --splits data/splits --out runs/v1
```

```bash
python evaluate.py --tflite runs/v1/gender_classifier.tflite --splits data/splits --out runs/v1 --gate
```

If the gate passes, install the model into the app:

```bash
cp runs/v1/gender_classifier.tflite runs/v1/model_meta.json ../app/assets/models/
```

(or pass `--install ../app/assets/models` to `export_tflite.py`).

**Time.** About 98k training images, 15 epochs. One modern GPU takes about 1 to 2 hours. A free Google Colab T4 works. A CPU alone would take days.

## 4. Release gate

`evaluate.py --gate` fails, and you should not ship, when any of these is missed on the held-out FairFace val split:

| check | default | why |
|---|---|---|
| overall accuracy | ≥ 92% | below this the app feels random |
| best − worst ethnic group accuracy | ≤ 6 pts | avoid a model that works well only for some groups |
| expected calibration error | ≤ 0.05 | the % shown in the app must mean something |

It also writes `eval_*.md` with accuracy by ethnic group, age band and gender. Keep it with the release, because app reviewers and journalists ask for it. Published MobileNet-class results on FairFace are around 93–95% overall.

Expect lower accuracy on children (0–9), where the difference is barely visible, and on side views. The app already shows "Not sure" below the confidence threshold and refuses to classify turned or tiny faces.

## 5. Smoke test (no data needed)

```bash
python smoke_test.py --work /tmp/genderlens-smoke
```

This runs the whole pipeline on synthetic images to check the code. The resulting model is untrained and marked `"release_ready": false`. The app refuses to start with it in release mode.

## Design notes

- **Crop contract.** FairFace crops are the dlib face box plus 25% padding per side, so 1.5× the box. The app grows the ML Kit box by `face_crop_scale` (1.5) to match. Training adds ±15% zoom and ±8% shift jitter so the small mismatch between detectors doesn't matter.
- **Pre-processing lives in the model.** Keras' MobileNetV3 has `include_preprocessing=True`, so the app feeds raw 0–255 RGB and can't get normalisation wrong.
- **float16** export halves the size (about 8 MB → 4 MB for Large) with no accuracy loss. `--quant int8` gives about 2.5 MB if size matters more. Re-run the gate after changing it.
- **Labels.** FairFace has binary perceived-gender labels. The app presents results as an appearance estimate, never as someone's gender, and shows "Not sure" when confidence is low.
