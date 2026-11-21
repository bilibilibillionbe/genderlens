# 上架指南（App Store / Google Play / 国内安卓商店）

本文件列出上架前**必须由你完成**的事项，以及各商店审核表单的标准答案。所有答案都基于本项目的真实行为：完全离线、不收集任何数据。如果你修改了这些行为（例如加了广告或统计），对应答案也必须修改。

---

## 0. 上架前必做清单

| # | 事项 | 说明 |
|---|---|---|
| 1 | 训练并放入正式模型 | 见 `ml/README.md`，须通过 `evaluate.py --gate` |
| 2 | 修改包名 / Bundle ID | 把 `com.yourcompany.genderlens` 全局替换成你自己的（Android：`app/android/app/build.gradle.kts`；iOS：`project.pbxproj`），并同步修改 Kotlin 目录 `app/android/app/src/main/kotlin/com/yourcompany/` |
| 3 | 填写法律文本占位符 | `app/assets/legal/*.md` 中的 `[DEVELOPER_LEGAL_NAME]`、`[CONTACT_EMAIL]`、`[CONTACT_ADDRESS]`、`[EFFECTIVE_DATE]` |
| 4 | 公开托管隐私政策 | 两大商店都要求提供可访问的 URL。可以直接用 GitHub Pages 发布 `app/assets/legal/` 里的文件，再把 URL 填入 `store/app_store/metadata/*/privacy_url.txt` 和 `support_url.txt` |
| 5 | Android 签名密钥 | 见第 4 节 |
| 6 | 截图 | 见第 5 节 |
| 7 | 运行检查 | `python3 scripts/check_release.py` 全部通过 |
| 8 | 真机测试 | 见第 6 节，至少 1 台 iPhone、1 台有 GMS 的安卓、1 台华为/荣耀（无 GMS） |

---

## 1. Apple App Store

### 1.1 账号与构建
- Apple Developer Program（个人或公司，每年 99 美元）。公司账号需要邓白氏编码（D-U-N-S）。
- 需要一台 Mac，安装最新 Xcode：

```bash
cd app && flutter build ipa --release
```

- 产物在 `app/build/ios/ipa/`，用 Xcode Organizer 或 Transporter 上传。也可以使用 `fastlane deliver`，元数据已经按 fastlane 格式放在 `store/app_store/metadata/`。

### 1.2 App 隐私（App Privacy，营养标签）
- “你或第三方合作伙伴是否从此 App 收集数据？” → **否，我们不从此 App 收集数据**（Data Not Collected）
- 依据：画面只在内存中处理、不离开设备，按 Apple 的定义不算“收集”。工程中已包含 `ios/Runner/PrivacyInfo.xcprivacy`（无追踪、无收集；UserDefaults 理由为 CA92.1）。

### 1.3 年龄分级
所有问题都选“无”，“不受限制的网络访问”也选“否”，得到 **4+**。也可以在“年龄分级覆盖”里手动提高到 **12+**，以降低审核方对未成年人使用的顾虑（推荐）。

### 1.4 类别
主类别：娱乐（Entertainment），次类别：摄影与录像。

### 1.5 审核备注（App Review Information → Notes）
可直接粘贴：

```
GenderLens estimates whether a face in the live camera view looks male or female.

- All processing happens on-device (Google ML Kit face detection + a TensorFlow Lite classifier bundled in the app). The app makes no network requests, has no account, no analytics and no ads.
- Camera frames are analysed in memory and discarded immediately; nothing is stored or transmitted. No face templates or identifiers are created; the app cannot recognise or identify people.
- Before the camera is ever used, a consent screen explains this, states that results are estimates of appearance (not gender identity), and asks users to only scan people who agree. Users can withdraw consent in Settings.
- The model was trained on FairFace (CC BY 4.0) and evaluated for consistent accuracy across demographic groups. Low-confidence results are shown as "Not sure".

To test: accept the consent screen, allow camera access, and point the camera at a face (a photo of a face on another screen also works).
```

### 1.6 审核风险与对策
| 风险 | 对策（已实现） |
|---|---|
| 4.3 垃圾/重复 App（同类应用很多） | 完成度高：多人脸、置信度、平滑、隐私设计、三语本地化。名称和截图不要模仿其他应用。被拒时在申诉中强调隐私和公平性设计 |
| 4.2 最低功能要求 | 功能完整、原生摄像头体验，不是网页壳 |
| 5.1.1 / 5.1.2 隐私 | 相机用途说明已本地化；同意页出现在任何权限请求之前；可撤回同意；无数据收集 |
| 1.1 令人反感的内容（性别议题） | 用语中性：“外貌估计”“不确定”，明确不代表性别认同；颜色不使用粉/蓝刻板印象 |

---

## 2. Google Play

### 2.1 构建
```bash
cd app && flutter build appbundle --release
```
上传 `app/build/app/outputs/bundle/release/app-release.aab`。务必启用 **Play App Signing**（Play 应用签名）。

### 2.2 数据安全（Data safety）表单
- 你的应用是否收集或分享任何必需的用户数据类型？ → **否**
- 依据：Google 规定“仅在设备上处理、不发送出设备的数据不算收集”。Android 版本的 Manifest 已经**移除 INTERNET 权限**，技术上无法外传。
- 数据是否加密传输 → 不适用（无传输）
- 是否提供数据删除方式 → 不适用（未收集任何数据）

### 2.3 内容分级（IARC 问卷）
类别选“实用工具 / 效率 / 通讯 / 其他”，暴力、性、脏话、受管制物品、赌博全部选否；用户互动/分享选否；位置分享选否。

### 2.4 目标受众
选择 **13 岁及以上**（或 18+）。**不要**勾选 13 岁以下，否则会触发“家庭”政策的额外要求。

### 2.5 其他声明
- 广告：不含广告
- 政府应用：否
- 金融功能：无
- 健康：无

---

## 3. 国内安卓应用商店（华为、荣耀、小米、OPPO、vivo、腾讯应用宝等）

### 3.1 资质（必须）
1. **APP 备案（工信部 ICP 备案）**：自 2023 年起，国内上架的 App 必须先备案。一般通过云服务商（阿里云、腾讯云、华为云）的备案系统办理，需要填写包名、签名 MD5 公钥等。**先确定最终包名和签名密钥，再去备案。**
2. **软件著作权证书**：大部分商店要求（华为、小米、OPPO、vivo），个人也可以申请，周期约 1 到 2 个月（加急可更快）。部分商店接受“电子版权认证”作为替代。
3. 开发者账号：个人或企业实名认证。部分商店对个人开发者上架有类别限制，企业账号最稳妥。

### 3.2 隐私合规（已在代码中实现，审核会检测）
- ✅ 首次启动先显示隐私说明和同意页，**同意前不申请任何权限、不调用任何 SDK**
- ✅ 隐私政策包含第三方 SDK 清单（ML Kit、TensorFlow Lite）、权限用途、未成年人条款、联系方式和答复时限
- ✅ 人脸属于**敏感个人信息**（《个人信息保护法》第 28、29 条），需要单独同意：同意页单独说明了人脸处理
- ✅ 提供撤回同意的入口（设置 → 撤回同意）
- ✅ 不收集 IMEI、MAC、Android ID 等设备标识，不自启动、不关联启动
- ✅ 关闭了系统备份（`allowBackup=false`）

### 3.3 构建
国内商店通常要 APK 而不是 AAB。只打包 ARM 架构（真机全部是 ARM；release 构建已在 Gradle 中排除 x86 库，APK 约 63 MB，加上模型约 70 MB）：

```bash
cd app && flutter build apk --release --target-platform android-arm,android-arm64
```

产物在 `app/build/app/outputs/flutter-apk/app-release.apk`，包含 arm64-v8a 和 armeabi-v7a，满足各商店的 64 位要求。Google Play 用 AAB，会按设备自动拆分，用户实际下载约 25 到 30 MB。

上传前用下面的命令确认权限只有 CAMERA（以及系统自动生成的 DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION）：

```bash
$ANDROID_HOME/build-tools/*/aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
```

### 3.4 无 GMS 设备
ML Kit 人脸检测使用的是**打包进 APK 的模型**（`com.google.mlkit:face-detection`），不依赖 Google Play 服务，在华为/荣耀等无 GMS 设备上也能运行。Manifest 中已设置不下载任何 ML Kit 模型。**仍需在真机上确认。**

### 3.5 隐私政策 URL
国内商店要求提供可访问的隐私政策链接。建议托管在国内可访问的地址（例如已备案域名或 Gitee Pages），GitHub Pages 在国内访问不稳定。

---

## 4. Android 签名

只需生成一次，**妥善备份，丢失后无法更新应用**：

```bash
keytool -genkey -v -keystore ~/genderlens-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

然后创建 `app/android/key.properties`（已在 .gitignore 中，不会提交）：

```
storeFile=/Users/you/genderlens-upload.jks
storePassword=******
keyAlias=upload
keyPassword=******
```

查看签名 MD5 / SHA-256（APP 备案和部分商店需要）：

```bash
keytool -list -v -keystore ~/genderlens-upload.jks -alias upload
```

> 如果使用 Play App Signing，Google Play 上分发的 APK 由 Google 的密钥签名；国内商店分发的 APK 由你的上传密钥签名。APP 备案时填写你实际用于国内分发的那个密钥。

---

## 5. 截图规格

| 商店 | 必需尺寸 | 数量 |
|---|---|---|
| App Store | 6.9 英寸 iPhone：1320×2868（或 1290×2796） | 3 到 10 张 |
| Google Play | 手机截图 1080×1920 以上，16:9 或 9:16；特色图片 1024×500（`app/assets/icon/feature_graphic.png`） | 2 到 8 张 |
| 国内商店 | 一般 1080×1920，3 到 5 张；图标 512×512 或 216×216 | 以各商店后台为准 |

建议截图内容：① 同意页（突出“仅在本机处理”）；② 单人识别（需要获得被拍摄者的书面授权，或使用可商用图库的照片对着屏幕拍摄）；③ 多人识别；④ “不确定”状态；⑤ 设置页的“不收集任何数据”。

**截图中出现的人脸必须获得肖像授权。**

---

## 6. 真机测试清单

- [ ] 首次启动：同意页出现之前没有任何权限弹窗
- [ ] 拒绝相机权限后显示说明页；iOS 上“打开设置”按钮可用；重新授权后恢复正常
- [ ] 前置和后置摄像头：人脸框与人脸对齐（前置画面镜像也正确）
- [ ] 多人同时出现：每张脸都有标签，切换时不串号
- [ ] 侧脸、远距离：显示“请正对镜头”
- [ ] 切到后台再回来：相机恢复；切到后台时系统的相机指示灯熄灭
- [ ] 飞行模式下功能完全正常（验证离线）
- [ ] 系统语言分别设为 English、简体中文、繁體中文（台湾、香港）
- [ ] 设置 → 撤回同意 → 回到同意页
- [ ] 低端机（例如 3GB 内存）上帧率可接受、不发热、不崩溃
- [ ] 华为/荣耀无 GMS 设备可以检测人脸

---

## 7. 法律提示（非法律意见）

- **欧盟 AI 法案**：根据生物特征推断性别属于“生物特征分类”，第 50 条要求告知被处理的人。同意页和使用规范已覆盖告知要求。在欧盟上架前建议咨询当地律师。
- **美国伊利诺伊州 BIPA、得州 CUBI** 等法律规范“生物特征标识”的采集。本应用不生成、不存储人脸模板，风险较低，但仍建议在隐私政策中保留现有表述。
- **中国**：人脸信息属于敏感个人信息，已采用单独同意加本地处理加不存储的方案。
