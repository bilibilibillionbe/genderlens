// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '性别识镜';

  @override
  String get consentTitle => '使用前请阅读';

  @override
  String get consentIntro => '性别识镜使用 AI 估计摄像头画面中的人脸看起来更像男性还是女性。请先了解以下内容：';

  @override
  String get consentOnDevice => '所有计算都在你的设备上完成。摄像头画面只在内存中分析，不会被保存、上传或分享。本应用不联网。';

  @override
  String get consentEstimate => '结果仅是对外貌的估计，可能出错，不代表任何人的性别认同。';

  @override
  String get consentPeople => '请只扫描已同意被扫描的人。不得用于识别身份、评判或歧视他人。';

  @override
  String get consentPurpose => '本应用仅供娱乐，不适合用于任何重要决定。';

  @override
  String get consentCheckbox => '我已阅读并同意《隐私政策》和《用户协议》';

  @override
  String get consentContinue => '同意并继续';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfUse => '用户协议';

  @override
  String get labelFemale => '女性';

  @override
  String get labelMale => '男性';

  @override
  String get labelUncertain => '不确定';

  @override
  String get labelAnalysing => '分析中…';

  @override
  String get labelPoorView => '请正对镜头';

  @override
  String confidence(int percent) {
    return '$percent%';
  }

  @override
  String get scanHint => '将摄像头对准人脸';

  @override
  String get disclaimerBanner => 'AI 外貌估计 · 仅在本机处理';

  @override
  String get switchCamera => '切换摄像头';

  @override
  String get settings => '设置';

  @override
  String get cameraPermissionTitle => '需要摄像头权限';

  @override
  String get cameraPermissionBody => '性别识镜需要使用摄像头来检测人脸，画面不会离开你的设备。你可以在系统设置中开启权限。';

  @override
  String get openSettings => '打开设置';

  @override
  String get retry => '重试';

  @override
  String get noCamera => '未在此设备上找到摄像头。';

  @override
  String get cameraError => '无法启动摄像头。';

  @override
  String get modelErrorTitle => '模型不可用';

  @override
  String get modelMissing => '此版本缺少识别模型。';

  @override
  String get modelInvalid => '识别模型已损坏或不兼容。';

  @override
  String get modelNotReleaseReady => '此版本包含不可用于正式使用的测试模型。';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionAbout => '关于';

  @override
  String get sectionPrivacy => '隐私';

  @override
  String get appVersion => '应用版本';

  @override
  String get modelVersion => '模型版本';

  @override
  String get howItWorks => '工作原理';

  @override
  String howItWorksBody(int percent) {
    return '人脸检测器先在摄像头画面中找到人脸，然后把每张人脸裁剪出来，交给在手机上运行的小型神经网络。网络输出一个概率，并在多帧之间取平均。当任一方向的置信度低于 $percent% 时，应用显示“不确定”。\n\n该网络使用 FairFace 训练，这是一个在不同族裔、年龄和性别之间保持均衡的公开数据集（CC BY 4.0）。对儿童、光线较差、浓妆、口罩以及侧脸的识别准确率较低。';
  }

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get withdrawConsent => '撤回同意';

  @override
  String get withdrawConsentBody => '应用将停止使用摄像头，并重新显示授权说明页。';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get dataNotCollected => '不收集任何数据';

  @override
  String get dataNotCollectedBody => '不存储、不传输任何图像、识别结果、设备标识或统计数据。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '性別識鏡';

  @override
  String get consentTitle => '使用前請閱讀';

  @override
  String get consentIntro => '性別識鏡使用 AI 估計相機畫面中的人臉看起來較像男性還是女性。請先了解以下內容：';

  @override
  String get consentOnDevice => '所有運算都在你的裝置上完成。相機畫面只在記憶體中分析，不會被儲存、上傳或分享。本應用程式不連網。';

  @override
  String get consentEstimate => '結果僅是對外貌的估計，可能出錯，不代表任何人的性別認同。';

  @override
  String get consentPeople => '請只掃描已同意被掃描的人。不得用於識別身分、評判或歧視他人。';

  @override
  String get consentPurpose => '本應用程式僅供娛樂，不適合用於任何重要決定。';

  @override
  String get consentCheckbox => '我已閱讀並同意《隱私權政策》和《使用條款》';

  @override
  String get consentContinue => '同意並繼續';

  @override
  String get privacyPolicy => '隱私權政策';

  @override
  String get termsOfUse => '使用條款';

  @override
  String get labelFemale => '女性';

  @override
  String get labelMale => '男性';

  @override
  String get labelUncertain => '不確定';

  @override
  String get labelAnalysing => '分析中…';

  @override
  String get labelPoorView => '請正對鏡頭';

  @override
  String confidence(int percent) {
    return '$percent%';
  }

  @override
  String get scanHint => '將相機對準人臉';

  @override
  String get disclaimerBanner => 'AI 外貌估計 · 僅在本機處理';

  @override
  String get switchCamera => '切換鏡頭';

  @override
  String get settings => '設定';

  @override
  String get cameraPermissionTitle => '需要相機權限';

  @override
  String get cameraPermissionBody => '性別識鏡需要使用相機來偵測人臉，畫面不會離開你的裝置。你可以在系統設定中開啟權限。';

  @override
  String get openSettings => '開啟設定';

  @override
  String get retry => '重試';

  @override
  String get noCamera => '未在此裝置上找到相機。';

  @override
  String get cameraError => '無法啟動相機。';

  @override
  String get modelErrorTitle => '模型無法使用';

  @override
  String get modelMissing => '此版本缺少辨識模型。';

  @override
  String get modelInvalid => '辨識模型已損壞或不相容。';

  @override
  String get modelNotReleaseReady => '此版本包含不可用於正式使用的測試模型。';

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionAbout => '關於';

  @override
  String get sectionPrivacy => '隱私';

  @override
  String get appVersion => '應用程式版本';

  @override
  String get modelVersion => '模型版本';

  @override
  String get howItWorks => '運作原理';

  @override
  String howItWorksBody(int percent) {
    return '人臉偵測器先在相機畫面中找到人臉，然後把每張人臉裁切出來，交給在手機上執行的小型神經網路。網路輸出一個機率，並在多個影格之間取平均。當任一方向的信心度低於 $percent% 時，應用程式顯示「不確定」。\n\n該網路使用 FairFace 訓練，這是一個在不同族裔、年齡和性別之間保持均衡的公開資料集（CC BY 4.0）。對兒童、光線不足、濃妝、口罩以及側臉的辨識準確率較低。';
  }

  @override
  String get openSourceLicenses => '開放原始碼授權';

  @override
  String get withdrawConsent => '撤回同意';

  @override
  String get withdrawConsentBody => '應用程式將停止使用相機，並重新顯示授權說明頁。';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get dataNotCollected => '不收集任何資料';

  @override
  String get dataNotCollectedBody => '不儲存、不傳輸任何影像、辨識結果、裝置識別碼或統計資料。';
}
