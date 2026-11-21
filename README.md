# GenderLens / 性别识镜

用摄像头实时估计人脸的外貌性别。iOS 和 Android 共用一套 Flutter 代码，**完全在设备上运行，不联网、不保存、不上传任何画面。**

## 项目结构

```
app/            Flutter 应用（iOS + Android）
  lib/core/       与平台无关的核心逻辑：帧格式、旋转、裁剪、平滑（全部有单元测试）
  lib/features/   界面：同意页、扫描页、设置页、法律文本
  lib/l10n/       English / 简体中文 / 繁體中文
  assets/legal/   隐私政策和用户协议（应用内显示，也可以直接托管成网页）
  assets/models/  训练好的模型放这里（不纳入 git）
ml/             模型训练流水线：数据准备 → 训练 → 公平性评估 → 导出 TFLite
store/          App Store 和 Google Play 的商店文案（fastlane 格式，三种语言）
docs/RELEASE.md 上架指南：各商店审核表单答案、国内商店资质、签名、截图、真机测试清单
scripts/        发布前检查脚本
.github/        CI：代码检查、测试、ML 冒烟测试、Android 和 iOS 构建
```

## 工作原理

```
相机帧 (NV21 / BGRA)
  → ML Kit 人脸检测（本地，附带跟踪 ID 和头部角度）
  → 质量过滤（太小、侧脸、歪头的不识别，提示“请正对镜头”）
  → 按 1.5 倍人脸框裁剪成正方形，旋转校正，抗锯齿缩放到 224×224
  → MobileNetV3 TFLite 模型（在后台 isolate 中运行）
  → 按人脸跟踪做多帧指数平滑；置信度低于 70% 显示“不确定”
  → 叠加显示（前置摄像头镜像也已处理）
```

## 快速开始

需要 Flutter 3.50 或更高版本。iOS 构建需要 Mac 和 Xcode。

1. 训练模型（详见 `ml/README.md`，需要 GPU，Colab 也可以）：

```bash
cd ml && pip install -r requirements.txt
```

```bash
python prepare_fairface.py --fairface-dir data/fairface --out data/splits
```

```bash
python train.py --splits data/splits --out runs/v1
```

```bash
python export_tflite.py --model runs/v1/best.keras --splits data/splits --out runs/v1 --install ../app/assets/models
```

```bash
python evaluate.py --tflite runs/v1/gender_classifier.tflite --splits data/splits --out runs/v1 --gate
```

2. 运行应用（需要真机，模拟器没有摄像头）：

```bash
cd app && flutter run
```

3. 测试：

```bash
cd app && flutter analyze && flutter test
```

4. 上架：先阅读 [`docs/RELEASE.md`](docs/RELEASE.md)，然后运行：

```bash
python3 scripts/check_release.py
```

## 设计决策

| 决策 | 原因 |
|---|---|
| 完全离线、Android 移除 INTERNET 权限 | 人脸是敏感个人信息；离线让“不收集数据”在技术上成立，商店隐私表单也最简单 |
| 同意页出现在任何权限和 SDK 调用之前 | 满足国内商店的隐私合规检测、《个人信息保护法》的单独同意要求、Apple 5.1.1 |
| 使用 FairFace 数据集（CC BY 4.0） | 可商用，且在族裔、年龄、性别之间保持均衡。CelebA、UTKFace 等常见数据集禁止商用 |
| 发布门槛包含族裔间准确率差距 ≤ 6 个百分点 | 避免模型只对部分人群有效 |
| 低置信度显示“不确定”，多帧平滑 | 单帧结果噪声大；宁可不答，也不要乱猜 |
| 结果颜色用琥珀色和青色，不用粉色和蓝色 | 避免刻板印象 |
| 只持久化“是否同意”这一项 | 没有可泄露的数据 |
| release 构建拒绝加载 `release_ready: false` 的模型 | 防止把冒烟测试产出的未训练模型发布出去 |

## 已知限制

- 没有在真机上运行过（当前开发环境无设备），上架前请按 `docs/RELEASE.md` 第 6 节完成真机测试。
- 仓库中不包含训练好的模型，需要按 `ml/README.md` 自行训练（可商用的数据集需要你自己下载并接受其许可）。
