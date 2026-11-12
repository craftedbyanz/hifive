import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appLanguageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ ứng dụng'**
  String get appLanguageTitle;

  /// No description provided for @appLanguageSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo ngôn ngữ máy'**
  String get appLanguageSystem;

  /// No description provided for @appLanguageHint.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng cho chữ trong ứng dụng. Nội dung bài học vẫn giữ nguyên.'**
  String get appLanguageHint;

  /// No description provided for @comingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp ra mắt'**
  String get comingSoon;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @loadFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được nội dung'**
  String get loadFailedTitle;

  /// No description provided for @loadFailedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết nối mạng rồi thử lại.'**
  String get loadFailedSubtitle;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @emptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nội dung'**
  String get emptyTitle;

  /// No description provided for @emptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thử danh mục khác hoặc làm mới.'**
  String get emptySubtitle;

  /// No description provided for @leave.
  ///
  /// In vi, this message translates to:
  /// **'Thoát'**
  String get leave;

  /// No description provided for @stay.
  ///
  /// In vi, this message translates to:
  /// **'Ở lại'**
  String get stay;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @exitGame.
  ///
  /// In vi, this message translates to:
  /// **'Thoát game'**
  String get exitGame;

  /// No description provided for @plusBannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký Hifive Plus'**
  String get plusBannerTitle;

  /// No description provided for @plusBannerBody.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa mức sử dụng cao hơn và làm chủ kỹ năng ngôn ngữ của bạn.'**
  String get plusBannerBody;

  /// No description provided for @vietnamFlag.
  ///
  /// In vi, this message translates to:
  /// **'Cờ Việt Nam'**
  String get vietnamFlag;

  /// No description provided for @greetingNight.
  ///
  /// In vi, this message translates to:
  /// **'Chúc ngủ ngon,'**
  String get greetingNight;

  /// No description provided for @greetingMorning.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi sáng,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi chiều,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi tối,'**
  String get greetingEvening;

  /// No description provided for @homeWhatToLearn.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa biết học gì hôm nay?'**
  String get homeWhatToLearn;

  /// No description provided for @homeAiLesson.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bài học với AI'**
  String get homeAiLesson;

  /// No description provided for @homeModesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ học tập'**
  String get homeModesTitle;

  /// No description provided for @homeModesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nâng cao kỹ năng viết, ngữ pháp và giao tiếp cùng AI.'**
  String get homeModesSubtitle;

  /// No description provided for @homeSuggestTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hifive đề xuất'**
  String get homeSuggestTitle;

  /// No description provided for @homeSuggestSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các chủ đề được chọn lọc để giúp bạn học nhanh hơn.'**
  String get homeSuggestSubtitle;

  /// No description provided for @topicSurprise.
  ///
  /// In vi, this message translates to:
  /// **'Làm tôi bất ngờ'**
  String get topicSurprise;

  /// No description provided for @topicTravel.
  ///
  /// In vi, this message translates to:
  /// **'Du lịch'**
  String get topicTravel;

  /// No description provided for @topicBusiness.
  ///
  /// In vi, this message translates to:
  /// **'Kinh doanh'**
  String get topicBusiness;

  /// No description provided for @topicFood.
  ///
  /// In vi, this message translates to:
  /// **'Ẩm thực'**
  String get topicFood;

  /// No description provided for @topicShopping.
  ///
  /// In vi, this message translates to:
  /// **'Mua sắm'**
  String get topicShopping;

  /// No description provided for @topicHealth.
  ///
  /// In vi, this message translates to:
  /// **'Sức khỏe'**
  String get topicHealth;

  /// No description provided for @topicSocial.
  ///
  /// In vi, this message translates to:
  /// **'Xã hội'**
  String get topicSocial;

  /// No description provided for @topicLife.
  ///
  /// In vi, this message translates to:
  /// **'Đời sống'**
  String get topicLife;

  /// No description provided for @topicEntertainment.
  ///
  /// In vi, this message translates to:
  /// **'Giải trí'**
  String get topicEntertainment;

  /// No description provided for @home101Body.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả những gì bạn cần biết về Hifive và cách ứng dụng giúp bạn học tập hiệu quả.'**
  String get home101Body;

  /// No description provided for @openFlashcards.
  ///
  /// In vi, this message translates to:
  /// **'Mở Flashcard'**
  String get openFlashcards;

  /// No description provided for @flashPromoTitle.
  ///
  /// In vi, this message translates to:
  /// **'VOCABULARY\nFLASHCARD'**
  String get flashPromoTitle;

  /// No description provided for @flashPromoBody.
  ///
  /// In vi, this message translates to:
  /// **'Lưu từ mới, ôn tập theo\nSRS và theo dõi tiến bộ mỗi\nngày.'**
  String get flashPromoBody;

  /// No description provided for @sampleResilientMeaning.
  ///
  /// In vi, this message translates to:
  /// **'Kiên cường'**
  String get sampleResilientMeaning;

  /// No description provided for @sampleAcquireMeaning.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp thu'**
  String get sampleAcquireMeaning;

  /// No description provided for @tryNow.
  ///
  /// In vi, this message translates to:
  /// **'Thử ngay'**
  String get tryNow;

  /// No description provided for @flowTagline.
  ///
  /// In vi, this message translates to:
  /// **'Xếp chữ cái thành từ vựng'**
  String get flowTagline;

  /// No description provided for @modeGrammarBlurb.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lỗi nhanh với các câu ngắn.'**
  String get modeGrammarBlurb;

  /// No description provided for @modeWritingBlurb.
  ///
  /// In vi, this message translates to:
  /// **'Rèn luyện dịch và viết các\nđoạn văn.'**
  String get modeWritingBlurb;

  /// No description provided for @modeChatBlurb.
  ///
  /// In vi, this message translates to:
  /// **'Mô phỏng đa dạng các\ntình huống.'**
  String get modeChatBlurb;

  /// No description provided for @explore.
  ///
  /// In vi, this message translates to:
  /// **'KHÁM PHÁ'**
  String get explore;

  /// No description provided for @modeWritingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đoạn văn'**
  String get modeWritingTitle;

  /// No description provided for @modeGrammarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa câu'**
  String get modeGrammarTitle;

  /// No description provided for @modeChatTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại'**
  String get modeChatTitle;

  /// No description provided for @modeWritingCategory.
  ///
  /// In vi, this message translates to:
  /// **'LUYỆN VIẾT'**
  String get modeWritingCategory;

  /// No description provided for @modeGrammarCategory.
  ///
  /// In vi, this message translates to:
  /// **'NGỮ PHÁP'**
  String get modeGrammarCategory;

  /// No description provided for @modeChatCategory.
  ///
  /// In vi, this message translates to:
  /// **'GIAO TIẾP'**
  String get modeChatCategory;

  /// No description provided for @modeWritingHeadline.
  ///
  /// In vi, this message translates to:
  /// **'Viết nên'**
  String get modeWritingHeadline;

  /// No description provided for @modeGrammarHeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thiện'**
  String get modeGrammarHeadline;

  /// No description provided for @modeChatHeadline.
  ///
  /// In vi, this message translates to:
  /// **'Thực hành'**
  String get modeChatHeadline;

  /// No description provided for @modeWritingAccent.
  ///
  /// In vi, this message translates to:
  /// **'câu chuyện'**
  String get modeWritingAccent;

  /// No description provided for @modeGrammarAccent.
  ///
  /// In vi, this message translates to:
  /// **'ngữ pháp'**
  String get modeGrammarAccent;

  /// No description provided for @modeChatAccent.
  ///
  /// In vi, this message translates to:
  /// **'giao tiếp'**
  String get modeChatAccent;

  /// No description provided for @modeWritingAction.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get modeWritingAction;

  /// No description provided for @modeGrammarAction.
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhanh'**
  String get modeGrammarAction;

  /// No description provided for @modeChatAction.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu chat'**
  String get modeChatAction;

  /// No description provided for @menuInsight.
  ///
  /// In vi, this message translates to:
  /// **'Insight'**
  String get menuInsight;

  /// No description provided for @menuPlus.
  ///
  /// In vi, this message translates to:
  /// **'Nâng cấp Hifive Plus'**
  String get menuPlus;

  /// No description provided for @menuFlashcards.
  ///
  /// In vi, this message translates to:
  /// **'Học flashcard'**
  String get menuFlashcards;

  /// No description provided for @menuStreak.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi của tôi'**
  String get menuStreak;

  /// No description provided for @menuGame.
  ///
  /// In vi, this message translates to:
  /// **'Chơi FlowLetter'**
  String get menuGame;

  /// No description provided for @streakLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi:'**
  String get streakLabel;

  /// No description provided for @streakDays.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày'**
  String streakDays(int count);

  /// No description provided for @menu.
  ///
  /// In vi, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileStudying.
  ///
  /// In vi, this message translates to:
  /// **'Đang học'**
  String get profileStudying;

  /// No description provided for @profileGeneral.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt chung'**
  String get profileGeneral;

  /// No description provided for @profileEdit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa hồ sơ'**
  String get profileEdit;

  /// No description provided for @profileLessonSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt bài học'**
  String get profileLessonSettings;

  /// No description provided for @profileVoice.
  ///
  /// In vi, this message translates to:
  /// **'Giọng đọc'**
  String get profileVoice;

  /// No description provided for @profileAppearance.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get profileAppearance;

  /// No description provided for @profileNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get profileNotifications;

  /// No description provided for @profileSubscription.
  ///
  /// In vi, this message translates to:
  /// **'Gói đăng ký'**
  String get profileSubscription;

  /// No description provided for @profileRedeem.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã ưu đãi'**
  String get profileRedeem;

  /// No description provided for @profileInvite.
  ///
  /// In vi, this message translates to:
  /// **'Mời bạn bè'**
  String get profileInvite;

  /// No description provided for @profileRate.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá ứng dụng'**
  String get profileRate;

  /// No description provided for @profileOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get profileOther;

  /// No description provided for @profileFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Gửi phản hồi'**
  String get profileFeedback;

  /// No description provided for @profileTerms.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản dịch vụ'**
  String get profileTerms;

  /// No description provided for @profilePrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách quyền riêng tư'**
  String get profilePrivacy;

  /// No description provided for @notSignedIn.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa đăng nhập.'**
  String get notSignedIn;

  /// No description provided for @signOutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất?'**
  String get signOutTitle;

  /// No description provided for @signOutSynced.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu học đã được lưu vào tài khoản và sẽ bị xoá khỏi máy này.'**
  String get signOutSynced;

  /// No description provided for @signOutLocal.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu học trên máy này vẫn được giữ lại.'**
  String get signOutLocal;

  /// No description provided for @signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get signOut;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get cancel;

  /// No description provided for @syncUnfinishedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đồng bộ xong'**
  String get syncUnfinishedTitle;

  /// No description provided for @syncUnfinishedBody.
  ///
  /// In vi, this message translates to:
  /// **'Một số thay đổi chưa được lưu vào tài khoản và sẽ bị mất. Vẫn đăng xuất?'**
  String get syncUnfinishedBody;

  /// No description provided for @signOutAnyway.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn đăng xuất'**
  String get signOutAnyway;

  /// No description provided for @cannotOpenHere.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này chưa mở được mục này.'**
  String get cannotOpenHere;

  /// No description provided for @planFree.
  ///
  /// In vi, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @trialLine1.
  ///
  /// In vi, this message translates to:
  /// **'Nâng cấp để có giới hạn cao hơn'**
  String get trialLine1;

  /// No description provided for @trialLine2.
  ///
  /// In vi, this message translates to:
  /// **'Truy cập sớm các tính năng mới'**
  String get trialLine2;

  /// No description provided for @trialLine3.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa toàn bộ sức mạnh AI'**
  String get trialLine3;

  /// No description provided for @trialTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử Hifive Plus'**
  String get trialTitle;

  /// No description provided for @upgrade.
  ///
  /// In vi, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @footerMotto.
  ///
  /// In vi, this message translates to:
  /// **'Học một chút mỗi ngày'**
  String get footerMotto;

  /// No description provided for @footerCredit.
  ///
  /// In vi, this message translates to:
  /// **'Develop and Design by Anz in VietNam'**
  String get footerCredit;

  /// No description provided for @redeemOffer.
  ///
  /// In vi, this message translates to:
  /// **'Redeem Offer'**
  String get redeemOffer;

  /// No description provided for @redeemCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'Code'**
  String get redeemCodeHint;

  /// No description provided for @redeemLocalNote.
  ///
  /// In vi, this message translates to:
  /// **'Bản cục bộ không kết nối App Store hoặc đổi mã.'**
  String get redeemLocalNote;

  /// No description provided for @continueAction.
  ///
  /// In vi, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @optionalHint.
  ///
  /// In vi, this message translates to:
  /// **'Optional'**
  String get optionalHint;

  /// No description provided for @send.
  ///
  /// In vi, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @reviewLocalNote.
  ///
  /// In vi, this message translates to:
  /// **'Bản cục bộ không gửi đánh giá đi đâu cả.'**
  String get reviewLocalNote;

  /// No description provided for @writeReview.
  ///
  /// In vi, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @appCategoryEducation.
  ///
  /// In vi, this message translates to:
  /// **'Education'**
  String get appCategoryEducation;

  /// No description provided for @tapToRate.
  ///
  /// In vi, this message translates to:
  /// **'Tap to Rate:'**
  String get tapToRate;

  /// No description provided for @reviewTitleField.
  ///
  /// In vi, this message translates to:
  /// **'Title'**
  String get reviewTitleField;

  /// No description provided for @reviewBodyField.
  ///
  /// In vi, this message translates to:
  /// **'Review'**
  String get reviewBodyField;

  /// No description provided for @addNickname.
  ///
  /// In vi, this message translates to:
  /// **'Add Nickname'**
  String get addNickname;

  /// No description provided for @saveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get saveChanges;

  /// No description provided for @displayName.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get displayName;

  /// No description provided for @emailAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ Email'**
  String get emailAddress;

  /// No description provided for @noEmail.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản không có email'**
  String get noEmail;

  /// No description provided for @signedInWith.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối qua'**
  String get signedInWith;

  /// No description provided for @notSignedInShort.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đăng nhập'**
  String get notSignedInShort;

  /// No description provided for @connected.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết nối'**
  String get connected;

  /// No description provided for @syncLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ'**
  String get syncLabel;

  /// No description provided for @syncNow.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ ngay'**
  String get syncNow;

  /// No description provided for @dangerZone.
  ///
  /// In vi, this message translates to:
  /// **'Vùng nguy hiểm'**
  String get dangerZone;

  /// No description provided for @deleteAccountLater.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản sẽ có trong bản phát hành chính thức.'**
  String get deleteAccountLater;

  /// No description provided for @deleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn tất cả dữ liệu của bạn'**
  String get deleteAccountBody;

  /// No description provided for @syncing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ...'**
  String get syncing;

  /// No description provided for @syncFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đồng bộ được'**
  String get syncFailed;

  /// No description provided for @neverSynced.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đồng bộ'**
  String get neverSynced;

  /// No description provided for @syncedAtTime.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng bộ lúc {time}'**
  String syncedAtTime(String time);

  /// No description provided for @syncedOnDate.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng bộ {date}'**
  String syncedOnDate(String date);

  /// No description provided for @countryUS.
  ///
  /// In vi, this message translates to:
  /// **'United States'**
  String get countryUS;

  /// No description provided for @countryUK.
  ///
  /// In vi, this message translates to:
  /// **'United Kingdom'**
  String get countryUK;

  /// No description provided for @countryAU.
  ///
  /// In vi, this message translates to:
  /// **'Australia'**
  String get countryAU;

  /// No description provided for @voiceHowTo.
  ///
  /// In vi, this message translates to:
  /// **'Cách cài đặt giọng đọc'**
  String get voiceHowTo;

  /// No description provided for @voiceEngineBody.
  ///
  /// In vi, this message translates to:
  /// **'Hifive sử dụng công nghệ Neural Audio của Apple để mang lại trải nghiệm nghe tự nhiên và sống động nhất.'**
  String get voiceEngineBody;

  /// No description provided for @voiceModels.
  ///
  /// In vi, this message translates to:
  /// **'Voice Models'**
  String get voiceModels;

  /// No description provided for @voiceNormal.
  ///
  /// In vi, this message translates to:
  /// **'Normal'**
  String get voiceNormal;

  /// No description provided for @voiceStep1Title.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt (Settings)'**
  String get voiceStep1Title;

  /// No description provided for @voiceStep1Body.
  ///
  /// In vi, this message translates to:
  /// **'Truy cập ứng dụng Cài đặt trên màn hình chính của iPhone.'**
  String get voiceStep1Body;

  /// No description provided for @voiceStep2Title.
  ///
  /// In vi, this message translates to:
  /// **'Vào Trợ năng (Accessibility)'**
  String get voiceStep2Title;

  /// No description provided for @voiceStep2Body.
  ///
  /// In vi, this message translates to:
  /// **'Tìm và chọn mục Trợ năng trong danh sách\ncài đặt.'**
  String get voiceStep2Body;

  /// No description provided for @voiceStep3Title.
  ///
  /// In vi, this message translates to:
  /// **'Mở Nội dung được đọc'**
  String get voiceStep3Title;

  /// No description provided for @voiceStep3Body.
  ///
  /// In vi, this message translates to:
  /// **'Chọn \'Đọc & Nói\' (Read & Speak) -> \'Giọng nói\' (Voices).'**
  String get voiceStep3Body;

  /// No description provided for @voiceStep4Title.
  ///
  /// In vi, this message translates to:
  /// **'Tải giọng Premium hoặc Enhanced'**
  String get voiceStep4Title;

  /// No description provided for @voiceStep4Body.
  ///
  /// In vi, this message translates to:
  /// **'Chọn \'Tiếng Anh\' (English) -> Chọn 1 giọng (ví dụ: Ava, Tom) -> Tải về bản \'Cao cấp\' (Premium) hoặc \'Nâng cao\' (Enhanced).'**
  String get voiceStep4Body;

  /// No description provided for @voiceHelpIntro.
  ///
  /// In vi, this message translates to:
  /// **'Để có trải nghiệm nghe tốt nhất, hãy tải về các gói giọng đọc Neural chất lượng cao từ Apple trên chính Iphone của bạn.'**
  String get voiceHelpIntro;

  /// No description provided for @appearanceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @styleRegular.
  ///
  /// In vi, this message translates to:
  /// **'Regular'**
  String get styleRegular;

  /// No description provided for @styleMono.
  ///
  /// In vi, this message translates to:
  /// **'Mono'**
  String get styleMono;

  /// No description provided for @styleMinimal.
  ///
  /// In vi, this message translates to:
  /// **'Minimal'**
  String get styleMinimal;

  /// No description provided for @styleGlass.
  ///
  /// In vi, this message translates to:
  /// **'Glass'**
  String get styleGlass;

  /// No description provided for @cardOrder.
  ///
  /// In vi, this message translates to:
  /// **'Card Order'**
  String get cardOrder;

  /// No description provided for @reset.
  ///
  /// In vi, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @reorderItem.
  ///
  /// In vi, this message translates to:
  /// **'Reorder {name}'**
  String reorderItem(String name);

  /// No description provided for @previewWritingTag.
  ///
  /// In vi, this message translates to:
  /// **'TRANSLATION'**
  String get previewWritingTag;

  /// No description provided for @previewWritingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Paragraph'**
  String get previewWritingTitle;

  /// No description provided for @previewWritingName.
  ///
  /// In vi, this message translates to:
  /// **'Translation'**
  String get previewWritingName;

  /// No description provided for @previewWritingBlurb.
  ///
  /// In vi, this message translates to:
  /// **'Master sentence structure & flow.'**
  String get previewWritingBlurb;

  /// No description provided for @previewGrammarTag.
  ///
  /// In vi, this message translates to:
  /// **'GRAMMAR'**
  String get previewGrammarTag;

  /// No description provided for @previewGrammarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quick Fix'**
  String get previewGrammarTitle;

  /// No description provided for @previewGrammarName.
  ///
  /// In vi, this message translates to:
  /// **'Grammar'**
  String get previewGrammarName;

  /// No description provided for @previewGrammarBlurb.
  ///
  /// In vi, this message translates to:
  /// **'Fix common mistakes instantly.'**
  String get previewGrammarBlurb;

  /// No description provided for @previewChatTag.
  ///
  /// In vi, this message translates to:
  /// **'DIALOGUE'**
  String get previewChatTag;

  /// No description provided for @previewChatTitle.
  ///
  /// In vi, this message translates to:
  /// **'Speaking'**
  String get previewChatTitle;

  /// No description provided for @previewChatName.
  ///
  /// In vi, this message translates to:
  /// **'Dialogue'**
  String get previewChatName;

  /// No description provided for @previewChatBlurb.
  ///
  /// In vi, this message translates to:
  /// **'Simulate real-life chats.'**
  String get previewChatBlurb;

  /// No description provided for @pushNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo đẩy'**
  String get pushNotifications;

  /// No description provided for @notEnabledInSettings.
  ///
  /// In vi, this message translates to:
  /// **'Chưa bật trong Cài đặt'**
  String get notEnabledInSettings;

  /// No description provided for @cannotOpenSettings.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được Cài đặt.'**
  String get cannotOpenSettings;

  /// No description provided for @settingsAction.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsAction;

  /// No description provided for @smartReminders.
  ///
  /// In vi, this message translates to:
  /// **'Lịch nhắc thông minh'**
  String get smartReminders;

  /// No description provided for @smartRemindersBody.
  ///
  /// In vi, this message translates to:
  /// **'Hifive tự động học thói quen của bạn. Chúng tôi sẽ nhắc bạn vào thời gian bạn thường học nhất.'**
  String get smartRemindersBody;

  /// No description provided for @lessonSettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lesson Settings'**
  String get lessonSettingsTitle;

  /// No description provided for @inputColor.
  ///
  /// In vi, this message translates to:
  /// **'Màu ô nhập'**
  String get inputColor;

  /// No description provided for @hintSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt gợi ý'**
  String get hintSettings;

  /// No description provided for @alwaysShowHints.
  ///
  /// In vi, this message translates to:
  /// **'Luôn hiển thị gợi ý'**
  String get alwaysShowHints;

  /// No description provided for @showHintsWithoutTap.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị từ gợi ý mà\nkhông cần chạm'**
  String get showHintsWithoutTap;

  /// No description provided for @typeTranslation.
  ///
  /// In vi, this message translates to:
  /// **'Nhập bản dịch của bạn...'**
  String get typeTranslation;

  /// No description provided for @chooseLevel.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cấp độ'**
  String get chooseLevel;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @cefrBody.
  ///
  /// In vi, this message translates to:
  /// **'Khung tham chiếu ngôn ngữ chung châu Âu (CEFR) chia trình độ thành 6 cấp, từ người mới bắt đầu đến thành thạo.'**
  String get cefrBody;

  /// No description provided for @levelAiNote.
  ///
  /// In vi, this message translates to:
  /// **'AI sẽ tạo ra các bài viết dựa theo trình độ của bạn, hãy chọn mức độ phù hợp nhất.'**
  String get levelAiNote;

  /// No description provided for @yourLevel.
  ///
  /// In vi, this message translates to:
  /// **'Trình độ của bạn'**
  String get yourLevel;

  /// No description provided for @noCourses.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoá học'**
  String get noCourses;

  /// No description provided for @comeBackLater.
  ///
  /// In vi, this message translates to:
  /// **'Hãy quay lại sau.'**
  String get comeBackLater;

  /// No description provided for @studyLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ học'**
  String get studyLanguage;

  /// No description provided for @chooseStudyLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ học'**
  String get chooseStudyLanguage;

  /// No description provided for @studyLanguageBody.
  ///
  /// In vi, this message translates to:
  /// **'Hifive hiện hỗ trợ lên tới 4 ngôn ngữ và sẽ mở rộng thêm trong tương lai.'**
  String get studyLanguageBody;

  /// No description provided for @languagesSection.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get languagesSection;

  /// No description provided for @currentLevel.
  ///
  /// In vi, this message translates to:
  /// **'TRÌNH ĐỘ HIỆN TẠI'**
  String get currentLevel;

  /// No description provided for @languageSoonTag.
  ///
  /// In vi, this message translates to:
  /// **'Coming soon'**
  String get languageSoonTag;

  /// No description provided for @continueWithApple.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithEmail.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với email'**
  String get continueWithEmail;

  /// No description provided for @introPage.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu {index} trên {count}'**
  String introPage(int index, int count);

  /// No description provided for @agreePrefix.
  ///
  /// In vi, this message translates to:
  /// **'Khi tiếp tục, bạn đồng ý với '**
  String get agreePrefix;

  /// No description provided for @agreeTerms.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản'**
  String get agreeTerms;

  /// No description provided for @agreeAnd.
  ///
  /// In vi, this message translates to:
  /// **' và '**
  String get agreeAnd;

  /// No description provided for @agreeSuffix.
  ///
  /// In vi, this message translates to:
  /// **''**
  String get agreeSuffix;

  /// No description provided for @cannotOpenTerms.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được điều khoản dịch vụ.'**
  String get cannotOpenTerms;

  /// No description provided for @loadingYourData.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải dữ liệu của bạn'**
  String get loadingYourData;

  /// No description provided for @loadingYourDataDetail.
  ///
  /// In vi, this message translates to:
  /// **'Lấy tiến độ từ tài khoản về thiết bị này.'**
  String get loadingYourDataDetail;

  /// No description provided for @signingIn.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập'**
  String get signingIn;

  /// No description provided for @authWrongCredentials.
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc mật khẩu không đúng.'**
  String get authWrongCredentials;

  /// No description provided for @authEmailInUse.
  ///
  /// In vi, this message translates to:
  /// **'Email này đã có tài khoản. Hãy đăng nhập.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu cần ít nhất 6 ký tự.'**
  String get authWeakPassword;

  /// No description provided for @authInvalidEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ.'**
  String get authInvalidEmail;

  /// No description provided for @authTooManyRequests.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thử quá nhiều lần. Vui lòng đợi một lát.'**
  String get authTooManyRequests;

  /// No description provided for @authNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng. Vui lòng thử lại.'**
  String get authNetwork;

  /// No description provided for @authUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Cách đăng nhập này chưa được bật.'**
  String get authUnavailable;

  /// No description provided for @authUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Không đăng nhập được. Vui lòng thử lại.'**
  String get authUnknown;

  /// No description provided for @resetNeedsEmail.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email để nhận liên kết đặt lại mật khẩu.'**
  String get resetNeedsEmail;

  /// No description provided for @resetSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi email đặt lại mật khẩu.'**
  String get resetSent;

  /// No description provided for @createAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản Hifive'**
  String get createAccountTitle;

  /// No description provided for @emailSignInTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng email'**
  String get emailSignInTitle;

  /// No description provided for @emailSignInBody.
  ///
  /// In vi, this message translates to:
  /// **'Lưu tiến độ và học tiếp trên mọi thiết bị.'**
  String get emailSignInBody;

  /// No description provided for @emailHint.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get passwordHint;

  /// No description provided for @working.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get working;

  /// No description provided for @createAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get signIn;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? Đăng nhập'**
  String get haveAccountSignIn;

  /// No description provided for @createNewAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới'**
  String get createNewAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @sceneWritingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Viết thật nhiều,\nsửa từng câu'**
  String get sceneWritingTitle;

  /// No description provided for @sceneWritingBody.
  ///
  /// In vi, this message translates to:
  /// **'Viết bằng ngôn ngữ bạn học, nhận góp ý ngay cho từng câu.'**
  String get sceneWritingBody;

  /// No description provided for @sceneChatTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện\nkhông sợ sai'**
  String get sceneChatTitle;

  /// No description provided for @sceneChatBody.
  ///
  /// In vi, this message translates to:
  /// **'Luyện hội thoại theo tình huống, lỗi được chỉ ra nhẹ nhàng.'**
  String get sceneChatBody;

  /// No description provided for @sceneWordsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhớ từ mới\nlâu hơn'**
  String get sceneWordsTitle;

  /// No description provided for @sceneWordsBody.
  ///
  /// In vi, this message translates to:
  /// **'Bộ thẻ nhắc bạn ôn lại đúng lúc sắp quên.'**
  String get sceneWordsBody;

  /// No description provided for @demoSourceLanguage.
  ///
  /// In vi, this message translates to:
  /// **'TIẾNG VIỆT'**
  String get demoSourceLanguage;

  /// No description provided for @demoSourceSentence.
  ///
  /// In vi, this message translates to:
  /// **'Cuối tuần này mình đi biển nhé!'**
  String get demoSourceSentence;

  /// No description provided for @demoYouWrote.
  ///
  /// In vi, this message translates to:
  /// **'BẠN VIẾT'**
  String get demoYouWrote;

  /// No description provided for @demoNatural.
  ///
  /// In vi, this message translates to:
  /// **'Tự nhiên · 96'**
  String get demoNatural;

  /// No description provided for @demoPastTense.
  ///
  /// In vi, this message translates to:
  /// **'Quá khứ: go → went'**
  String get demoPastTense;

  /// No description provided for @demoRememberMeaning.
  ///
  /// In vi, this message translates to:
  /// **'ghi nhớ'**
  String get demoRememberMeaning;

  /// No description provided for @rateHard.
  ///
  /// In vi, this message translates to:
  /// **'Khó'**
  String get rateHard;

  /// No description provided for @rateOkay.
  ///
  /// In vi, this message translates to:
  /// **'Ổn'**
  String get rateOkay;

  /// No description provided for @rateEasy.
  ///
  /// In vi, this message translates to:
  /// **'Dễ'**
  String get rateEasy;

  /// No description provided for @reviewInDays.
  ///
  /// In vi, this message translates to:
  /// **'Ôn lại sau {count} ngày'**
  String reviewInDays(int count);

  /// No description provided for @preparingSavingProfile.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu hồ sơ của {name}'**
  String preparingSavingProfile(String name);

  /// No description provided for @preparingChoosingLessons.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bài học trình độ {level}'**
  String preparingChoosingLessons(String level);

  /// No description provided for @preparingSorting.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp theo mục tiêu của bạn'**
  String get preparingSorting;

  /// No description provided for @preparingDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ một chút nữa thôi.'**
  String get preparingDetail;

  /// No description provided for @finish.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get finish;

  /// No description provided for @continueStep.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get continueStep;

  /// No description provided for @stepOf.
  ///
  /// In vi, this message translates to:
  /// **'Bước {step} trên {count}'**
  String stepOf(int step, int count);

  /// No description provided for @nameStepTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào bạn!'**
  String get nameStepTitle;

  /// No description provided for @nameStepAccent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn tên là gì?'**
  String get nameStepAccent;

  /// No description provided for @nameStepBody.
  ///
  /// In vi, this message translates to:
  /// **'Hifive sẽ gọi bạn bằng tên này. Bạn có thể đổi trong Hồ sơ.'**
  String get nameStepBody;

  /// No description provided for @yourName.
  ///
  /// In vi, this message translates to:
  /// **'Tên của bạn'**
  String get yourName;

  /// No description provided for @levelLineA1.
  ///
  /// In vi, this message translates to:
  /// **'Biết vài từ và câu chào hỏi.'**
  String get levelLineA1;

  /// No description provided for @levelLineA2.
  ///
  /// In vi, this message translates to:
  /// **'Viết được câu đơn giản về bản thân.'**
  String get levelLineA2;

  /// No description provided for @levelLineB1.
  ///
  /// In vi, this message translates to:
  /// **'Viết được đoạn ngắn về chủ đề quen thuộc.'**
  String get levelLineB1;

  /// No description provided for @levelLineB2.
  ///
  /// In vi, this message translates to:
  /// **'Nêu quan điểm khá tự nhiên, có lập luận.'**
  String get levelLineB2;

  /// No description provided for @levelLineC1.
  ///
  /// In vi, this message translates to:
  /// **'Viết mạch lạc cho học tập và công việc.'**
  String get levelLineC1;

  /// No description provided for @levelLineC2.
  ///
  /// In vi, this message translates to:
  /// **'Gần như người bản ngữ.'**
  String get levelLineC2;

  /// No description provided for @levelStepTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trình độ hiện tại'**
  String get levelStepTitle;

  /// No description provided for @levelStepAccent.
  ///
  /// In vi, this message translates to:
  /// **'của bạn là gì?'**
  String get levelStepAccent;

  /// No description provided for @levelStepBody.
  ///
  /// In vi, this message translates to:
  /// **'Bài học bắt đầu từ mức này. Chưa chắc thì chọn thấp hơn một bậc.'**
  String get levelStepBody;

  /// No description provided for @goalDaily.
  ///
  /// In vi, this message translates to:
  /// **'Giao tiếp'**
  String get goalDaily;

  /// No description provided for @goalDailyBody.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện hằng ngày'**
  String get goalDailyBody;

  /// No description provided for @goalTravel.
  ///
  /// In vi, this message translates to:
  /// **'Du lịch'**
  String get goalTravel;

  /// No description provided for @goalTravelBody.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi đường, gọi món'**
  String get goalTravelBody;

  /// No description provided for @goalWork.
  ///
  /// In vi, this message translates to:
  /// **'Công việc'**
  String get goalWork;

  /// No description provided for @goalWorkBody.
  ///
  /// In vi, this message translates to:
  /// **'Email, họp, thuyết trình'**
  String get goalWorkBody;

  /// No description provided for @goalExam.
  ///
  /// In vi, this message translates to:
  /// **'Thi chứng chỉ'**
  String get goalExam;

  /// No description provided for @goalExamBody.
  ///
  /// In vi, this message translates to:
  /// **'IELTS, TOEIC, TOEFL'**
  String get goalExamBody;

  /// No description provided for @goalStudy.
  ///
  /// In vi, this message translates to:
  /// **'Du học'**
  String get goalStudy;

  /// No description provided for @goalStudyBody.
  ///
  /// In vi, this message translates to:
  /// **'Bài giảng, bài luận'**
  String get goalStudyBody;

  /// No description provided for @goalWriting.
  ///
  /// In vi, this message translates to:
  /// **'Viết tốt hơn'**
  String get goalWriting;

  /// No description provided for @goalWritingBody.
  ///
  /// In vi, this message translates to:
  /// **'Câu rõ ý, ít lỗi'**
  String get goalWritingBody;

  /// No description provided for @goalMedia.
  ///
  /// In vi, this message translates to:
  /// **'Phim và nhạc'**
  String get goalMedia;

  /// No description provided for @goalMediaBody.
  ///
  /// In vi, this message translates to:
  /// **'Hiểu không cần phụ đề'**
  String get goalMediaBody;

  /// No description provided for @goalFamily.
  ///
  /// In vi, this message translates to:
  /// **'Cùng gia đình'**
  String get goalFamily;

  /// No description provided for @goalFamilyBody.
  ///
  /// In vi, this message translates to:
  /// **'Học cùng con, người thân'**
  String get goalFamilyBody;

  /// No description provided for @goalStepTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn học'**
  String get goalStepTitle;

  /// No description provided for @goalStepAccent.
  ///
  /// In vi, this message translates to:
  /// **'để làm gì?'**
  String get goalStepAccent;

  /// No description provided for @goalPickUpTo.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tối đa {max} mục tiêu.'**
  String goalPickUpTo(int max);

  /// No description provided for @goalPicked.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {count}/{max} mục tiêu.'**
  String goalPicked(int count, int max);

  /// No description provided for @welcomeStepTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng'**
  String get welcomeStepTitle;

  /// No description provided for @welcomeStepAccent.
  ///
  /// In vi, this message translates to:
  /// **'đến với Hifive'**
  String get welcomeStepAccent;

  /// No description provided for @welcomeStepBody.
  ///
  /// In vi, this message translates to:
  /// **'Học ngoại ngữ bằng cách viết, nói và ôn từ mỗi ngày. Bốn cách luyện tập giúp bạn tiến bộ tự nhiên, từng chút một.'**
  String get welcomeStepBody;

  /// No description provided for @practiceWriting.
  ///
  /// In vi, this message translates to:
  /// **'Viết đoạn văn'**
  String get practiceWriting;

  /// No description provided for @practiceWritingBody.
  ///
  /// In vi, this message translates to:
  /// **'Dịch và viết lại từng câu theo chủ đề bạn thích.'**
  String get practiceWritingBody;

  /// No description provided for @practiceGrammar.
  ///
  /// In vi, this message translates to:
  /// **'Sửa câu'**
  String get practiceGrammar;

  /// No description provided for @practiceGrammarBody.
  ///
  /// In vi, this message translates to:
  /// **'Câu ngắn, sửa nhanh, hiểu vì sao sai.'**
  String get practiceGrammarBody;

  /// No description provided for @practiceChat.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại'**
  String get practiceChat;

  /// No description provided for @practiceChatBody.
  ///
  /// In vi, this message translates to:
  /// **'Đóng vai trong những tình huống thật.'**
  String get practiceChatBody;

  /// No description provided for @practiceCards.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ từ vựng'**
  String get practiceCards;

  /// No description provided for @practiceCardsBody.
  ///
  /// In vi, this message translates to:
  /// **'Lưu từ mới, ôn đúng lúc sắp quên.'**
  String get practiceCardsBody;

  /// No description provided for @tapForNextWay.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để xem cách học tiếp theo'**
  String get tapForNextWay;

  /// No description provided for @cardsStepTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu từ mới mọi lúc,'**
  String get cardsStepTitle;

  /// No description provided for @cardsStepAccent.
  ///
  /// In vi, this message translates to:
  /// **'ôn đúng lúc sắp quên'**
  String get cardsStepAccent;

  /// No description provided for @cardsStepBody.
  ///
  /// In vi, this message translates to:
  /// **'Lưu từ ngay khi học và ôn lại bằng bộ thẻ. Chạm vào thẻ để lật, rồi cho Hifive biết bạn đã nhớ chưa.'**
  String get cardsStepBody;

  /// No description provided for @posAdjective.
  ///
  /// In vi, this message translates to:
  /// **'TÍNH TỪ'**
  String get posAdjective;

  /// No description provided for @posNoun.
  ///
  /// In vi, this message translates to:
  /// **'DANH TỪ'**
  String get posNoun;

  /// No description provided for @posVerb.
  ///
  /// In vi, this message translates to:
  /// **'ĐỘNG TỪ'**
  String get posVerb;

  /// No description provided for @meaningCurious.
  ///
  /// In vi, this message translates to:
  /// **'tò mò'**
  String get meaningCurious;

  /// No description provided for @meaningJourney.
  ///
  /// In vi, this message translates to:
  /// **'chuyến đi'**
  String get meaningJourney;

  /// No description provided for @meaningImprove.
  ///
  /// In vi, this message translates to:
  /// **'cải thiện'**
  String get meaningImprove;

  /// No description provided for @meaningBrave.
  ///
  /// In vi, this message translates to:
  /// **'dũng cảm'**
  String get meaningBrave;

  /// No description provided for @reviewTomorrow.
  ///
  /// In vi, this message translates to:
  /// **'Ôn lại vào ngày mai'**
  String get reviewTomorrow;

  /// No description provided for @tapToFlip.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để lật'**
  String get tapToFlip;

  /// No description provided for @tapToFlipCaps.
  ///
  /// In vi, this message translates to:
  /// **'CHẠM ĐỂ LẬT'**
  String get tapToFlipCaps;

  /// No description provided for @listenTo.
  ///
  /// In vi, this message translates to:
  /// **'Nghe \"{word}\"'**
  String listenTo(String word);

  /// No description provided for @notRemembered.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhớ'**
  String get notRemembered;

  /// No description provided for @remembered.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhớ'**
  String get remembered;

  /// No description provided for @demoWriteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Viết một câu,'**
  String get demoWriteTitle;

  /// No description provided for @demoWriteAccent.
  ///
  /// In vi, this message translates to:
  /// **'nhận góp ý ngay'**
  String get demoWriteAccent;

  /// No description provided for @demoWriteBody.
  ///
  /// In vi, this message translates to:
  /// **'Hifive chấm từng câu bạn viết và chỉ cách nói tự nhiên hơn. Thử chấm câu dưới đây.'**
  String get demoWriteBody;

  /// No description provided for @demoTranslateToEnglish.
  ///
  /// In vi, this message translates to:
  /// **'DỊCH SANG TIẾNG ANH'**
  String get demoTranslateToEnglish;

  /// No description provided for @demoWriteSource.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã sống ở Đà Nẵng ba năm.'**
  String get demoWriteSource;

  /// No description provided for @scoreIt.
  ///
  /// In vi, this message translates to:
  /// **'Chấm điểm'**
  String get scoreIt;

  /// No description provided for @scored.
  ///
  /// In vi, this message translates to:
  /// **'Đã chấm'**
  String get scored;

  /// No description provided for @scoring.
  ///
  /// In vi, this message translates to:
  /// **'Đang chấm'**
  String get scoring;

  /// No description provided for @scoringEllipsis.
  ///
  /// In vi, this message translates to:
  /// **'Đang chấm...'**
  String get scoringEllipsis;

  /// No description provided for @almostRight.
  ///
  /// In vi, this message translates to:
  /// **'Gần đúng'**
  String get almostRight;

  /// No description provided for @correctSentenceCaps.
  ///
  /// In vi, this message translates to:
  /// **'CÂU ĐÚNG'**
  String get correctSentenceCaps;

  /// No description provided for @explanationCaps.
  ///
  /// In vi, this message translates to:
  /// **'GIẢI THÍCH'**
  String get explanationCaps;

  /// No description provided for @demoWriteExplanation.
  ///
  /// In vi, this message translates to:
  /// **'Việc bắt đầu trong quá khứ và vẫn còn tiếp diễn nên dùng thì hiện tại hoàn thành.'**
  String get demoWriteExplanation;

  /// No description provided for @demoGrammarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lỗi ngữ pháp'**
  String get demoGrammarTitle;

  /// No description provided for @demoGrammarAccent.
  ///
  /// In vi, this message translates to:
  /// **'trong từng câu'**
  String get demoGrammarAccent;

  /// No description provided for @demoGrammarBody.
  ///
  /// In vi, this message translates to:
  /// **'Câu ngắn, giải thích rõ, để lỗi quen không lặp lại. Chọn từ đúng cho chỗ trống.'**
  String get demoGrammarBody;

  /// No description provided for @fillTheBlankCaps.
  ///
  /// In vi, this message translates to:
  /// **'ĐIỀN VÀO CHỖ TRỐNG'**
  String get fillTheBlankCaps;

  /// No description provided for @correctExclaim.
  ///
  /// In vi, this message translates to:
  /// **'Chính xác!'**
  String get correctExclaim;

  /// No description provided for @notQuiteTryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đúng, thử lại nhé'**
  String get notQuiteTryAgain;

  /// No description provided for @demoGrammarRule.
  ///
  /// In vi, this message translates to:
  /// **'Chủ ngữ số ít (she) ở thì hiện tại đơn thì động từ thêm -s hoặc -es.'**
  String get demoGrammarRule;

  /// No description provided for @demoGrammarHint.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý: \"every day\" là thói quen, và chủ ngữ là \"she\".'**
  String get demoGrammarHint;

  /// No description provided for @demoChatPolite.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sự hơn: \"Could I have a coffee, please?\"'**
  String get demoChatPolite;

  /// No description provided for @demoChatTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện nói'**
  String get demoChatTitle;

  /// No description provided for @demoChatAccent.
  ///
  /// In vi, this message translates to:
  /// **'như ngoài đời'**
  String get demoChatAccent;

  /// No description provided for @demoChatBody.
  ///
  /// In vi, this message translates to:
  /// **'Luyện nói theo tình huống thật. Chọn một câu để trả lời.'**
  String get demoChatBody;

  /// No description provided for @hint.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý'**
  String get hint;

  /// No description provided for @noDecks.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bộ thẻ'**
  String get noDecks;

  /// No description provided for @noDecksBody.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bộ từ vựng đầu tiên của bạn.'**
  String get noDecksBody;

  /// No description provided for @addDeck.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bộ thẻ'**
  String get addDeck;

  /// No description provided for @addedSampleWords.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm {count} từ mẫu'**
  String addedSampleWords(int count);

  /// No description provided for @sampleDeckDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bộ từ vựng mẫu của bạn'**
  String get sampleDeckDescription;

  /// No description provided for @cardsFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được thẻ. Vui lòng thử lại.'**
  String get cardsFailed;

  /// No description provided for @addCards.
  ///
  /// In vi, this message translates to:
  /// **'Add Cards'**
  String get addCards;

  /// No description provided for @newDeck.
  ///
  /// In vi, this message translates to:
  /// **'New Deck'**
  String get newDeck;

  /// No description provided for @topicNameCaps.
  ///
  /// In vi, this message translates to:
  /// **'TOPIC NAME'**
  String get topicNameCaps;

  /// No description provided for @topicNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Space, Cooking, Travel...'**
  String get topicNameHint;

  /// No description provided for @wordsUnit.
  ///
  /// In vi, this message translates to:
  /// **'words'**
  String get wordsUnit;

  /// No description provided for @wordsToGenerateCaps.
  ///
  /// In vi, this message translates to:
  /// **'WORDS TO GENERATE'**
  String get wordsToGenerateCaps;

  /// No description provided for @slotsLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} slot'**
  String slotsLeft(int count);

  /// No description provided for @generateDeck.
  ///
  /// In vi, this message translates to:
  /// **'Generate Deck'**
  String get generateDeck;

  /// No description provided for @sortNewest.
  ///
  /// In vi, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In vi, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortAZ.
  ///
  /// In vi, this message translates to:
  /// **'A-Z'**
  String get sortAZ;

  /// No description provided for @filterAll.
  ///
  /// In vi, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filters.
  ///
  /// In vi, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filterNotStudied.
  ///
  /// In vi, this message translates to:
  /// **'Not studied'**
  String get filterNotStudied;

  /// No description provided for @filterLearning.
  ///
  /// In vi, this message translates to:
  /// **'Learning'**
  String get filterLearning;

  /// No description provided for @filterMastered.
  ///
  /// In vi, this message translates to:
  /// **'Mastered'**
  String get filterMastered;

  /// No description provided for @restartDeck.
  ///
  /// In vi, this message translates to:
  /// **'Học lại từ đầu'**
  String get restartDeck;

  /// No description provided for @restartDeckTitle.
  ///
  /// In vi, this message translates to:
  /// **'Học lại từ đầu?'**
  String get restartDeckTitle;

  /// No description provided for @restartDeckBody.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại lịch ôn của bộ thẻ cục bộ này?'**
  String get restartDeckBody;

  /// No description provided for @resetAction.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại'**
  String get resetAction;

  /// No description provided for @deckOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn bộ thẻ'**
  String get deckOptions;

  /// No description provided for @reviewAll.
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập tất cả'**
  String get reviewAll;

  /// No description provided for @reviewDue.
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập ({count})'**
  String reviewDue(int count);

  /// No description provided for @doneForToday.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành bài học hôm nay!'**
  String get doneForToday;

  /// No description provided for @searchCards.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm thẻ'**
  String get searchCards;

  /// No description provided for @searchWordsHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm từ vựng...'**
  String get searchWordsHint;

  /// No description provided for @cancelEn.
  ///
  /// In vi, this message translates to:
  /// **'Cancel'**
  String get cancelEn;

  /// No description provided for @statNew.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get statNew;

  /// No description provided for @statLearning.
  ///
  /// In vi, this message translates to:
  /// **'Đang học'**
  String get statLearning;

  /// No description provided for @statReview.
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập'**
  String get statReview;

  /// No description provided for @deckProgress.
  ///
  /// In vi, this message translates to:
  /// **'Deck Progress'**
  String get deckProgress;

  /// No description provided for @cardsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} cards'**
  String cardsCount(int count);

  /// No description provided for @pillNew.
  ///
  /// In vi, this message translates to:
  /// **'MỚI'**
  String get pillNew;

  /// No description provided for @pillLearning.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG HỌC'**
  String get pillLearning;

  /// No description provided for @pillReview.
  ///
  /// In vi, this message translates to:
  /// **'ÔN TẬP'**
  String get pillReview;

  /// No description provided for @pronounceWord.
  ///
  /// In vi, this message translates to:
  /// **'Phát âm {word}'**
  String pronounceWord(String word);

  /// No description provided for @pronounce.
  ///
  /// In vi, this message translates to:
  /// **'Phát âm'**
  String get pronounce;

  /// No description provided for @example.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ'**
  String get example;

  /// No description provided for @excellent.
  ///
  /// In vi, this message translates to:
  /// **'Xuất sắc!'**
  String get excellent;

  /// No description provided for @masteredMost.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã nắm vững hầu hết các thẻ!'**
  String get masteredMost;

  /// No description provided for @seen.
  ///
  /// In vi, this message translates to:
  /// **'Đã xem'**
  String get seen;

  /// No description provided for @known.
  ///
  /// In vi, this message translates to:
  /// **'Thuộc'**
  String get known;

  /// No description provided for @relearn.
  ///
  /// In vi, this message translates to:
  /// **'Học lại'**
  String get relearn;

  /// No description provided for @rateAgain.
  ///
  /// In vi, this message translates to:
  /// **'Học lại'**
  String get rateAgain;

  /// No description provided for @rateHardCard.
  ///
  /// In vi, this message translates to:
  /// **'Khó'**
  String get rateHardCard;

  /// No description provided for @rateGood.
  ///
  /// In vi, this message translates to:
  /// **'Tốt'**
  String get rateGood;

  /// No description provided for @rateEasyCard.
  ///
  /// In vi, this message translates to:
  /// **'Dễ'**
  String get rateEasyCard;

  /// No description provided for @closeReview.
  ///
  /// In vi, this message translates to:
  /// **'Đóng ôn tập'**
  String get closeReview;

  /// No description provided for @reviewOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn ôn tập'**
  String get reviewOptions;

  /// No description provided for @guideForgot.
  ///
  /// In vi, this message translates to:
  /// **'Quên bài'**
  String get guideForgot;

  /// No description provided for @guideForgotBody.
  ///
  /// In vi, this message translates to:
  /// **'Vuốt trái để Hifive sắp xếp học lại ngay'**
  String get guideForgotBody;

  /// No description provided for @guideHard.
  ///
  /// In vi, this message translates to:
  /// **'Hơi khó nhớ'**
  String get guideHard;

  /// No description provided for @guideHardBody.
  ///
  /// In vi, this message translates to:
  /// **'Vuốt xuống nếu bạn thấy từ này còn lạ lẫm'**
  String get guideHardBody;

  /// No description provided for @guideKnown.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhớ'**
  String get guideKnown;

  /// No description provided for @guideKnownBody.
  ///
  /// In vi, this message translates to:
  /// **'Vuốt lên khi bạn trả lời đúng nghĩa và phát âm'**
  String get guideKnownBody;

  /// No description provided for @guideEasy.
  ///
  /// In vi, this message translates to:
  /// **'Quá dễ'**
  String get guideEasy;

  /// No description provided for @guideEasyBody.
  ///
  /// In vi, this message translates to:
  /// **'Vuốt phải để ít gặp lại từ này hơn'**
  String get guideEasyBody;

  /// No description provided for @smartLearning.
  ///
  /// In vi, this message translates to:
  /// **'Cơ chế học thông minh'**
  String get smartLearning;

  /// No description provided for @swipeToRate.
  ///
  /// In vi, this message translates to:
  /// **'Vuốt thẻ bài để đánh giá mức độ ghi nhớ của bạn'**
  String get swipeToRate;

  /// No description provided for @gotItStart.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu, bắt đầu học'**
  String get gotItStart;

  /// No description provided for @autoPlay.
  ///
  /// In vi, this message translates to:
  /// **'Tự động phát'**
  String get autoPlay;

  /// No description provided for @cardColor.
  ///
  /// In vi, this message translates to:
  /// **'Màu thẻ'**
  String get cardColor;

  /// No description provided for @guide.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn'**
  String get guide;

  /// No description provided for @colorful.
  ///
  /// In vi, this message translates to:
  /// **'Màu sắc'**
  String get colorful;

  /// No description provided for @monochrome.
  ///
  /// In vi, this message translates to:
  /// **'Đơn sắc'**
  String get monochrome;

  /// No description provided for @gameHowToTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cách chơi Flow Letter'**
  String get gameHowToTitle;

  /// No description provided for @gameGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get gameGoal;

  /// No description provided for @gameGoalBody.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp các chữ cái thành từ vựng đúng.'**
  String get gameGoalBody;

  /// No description provided for @gameMove.
  ///
  /// In vi, this message translates to:
  /// **'Cách di chuyển'**
  String get gameMove;

  /// No description provided for @gameMoveBody.
  ///
  /// In vi, this message translates to:
  /// **'Giữ và kéo một chữ cái để đổi vị trí.'**
  String get gameMoveBody;

  /// No description provided for @gameDone.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get gameDone;

  /// No description provided for @gameDoneBody.
  ///
  /// In vi, this message translates to:
  /// **'Đúng từ sẽ tự động chuyển sang từ tiếp theo.'**
  String get gameDoneBody;

  /// No description provided for @tapToSee.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn để xem'**
  String get tapToSee;

  /// No description provided for @chooseDeck.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bộ từ vựng'**
  String get chooseDeck;

  /// No description provided for @wordsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} từ'**
  String wordsCount(int count);

  /// No description provided for @flowGuideLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn Flow Letter'**
  String get flowGuideLabel;

  /// No description provided for @rotateForBetter.
  ///
  /// In vi, this message translates to:
  /// **'Trải nghiệm tốt hơn khi xoay điện thoại'**
  String get rotateForBetter;

  /// No description provided for @levelOne.
  ///
  /// In vi, this message translates to:
  /// **'Level 1'**
  String get levelOne;

  /// No description provided for @bestScore.
  ///
  /// In vi, this message translates to:
  /// **'Best {score}'**
  String bestScore(int score);

  /// No description provided for @totalXp.
  ///
  /// In vi, this message translates to:
  /// **'XP tổng: {xp}'**
  String totalXp(int xp);

  /// No description provided for @comboZero.
  ///
  /// In vi, this message translates to:
  /// **'Combo x0'**
  String get comboZero;

  /// No description provided for @gamesPlayed.
  ///
  /// In vi, this message translates to:
  /// **'Lần chơi: {count}'**
  String gamesPlayed(int count);

  /// No description provided for @startFirstSession.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu session đầu tiên'**
  String get startFirstSession;

  /// No description provided for @continueTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục {title}'**
  String continueTitle(String title);

  /// No description provided for @play.
  ///
  /// In vi, this message translates to:
  /// **'Chơi'**
  String get play;

  /// No description provided for @difficulty.
  ///
  /// In vi, this message translates to:
  /// **'Độ khó'**
  String get difficulty;

  /// No description provided for @rotate.
  ///
  /// In vi, this message translates to:
  /// **'Xoay'**
  String get rotate;

  /// No description provided for @difficultyEasy.
  ///
  /// In vi, this message translates to:
  /// **'Dễ'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In vi, this message translates to:
  /// **'Vừa'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In vi, this message translates to:
  /// **'Khó'**
  String get difficultyHard;

  /// No description provided for @sound.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh'**
  String get sound;

  /// No description provided for @hapticFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Rung phản hồi'**
  String get hapticFeedback;

  /// No description provided for @resumeLater.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể tiếp tục từ trang Flow Letter.'**
  String get resumeLater;

  /// No description provided for @progressLost.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ chơi hiện tại sẽ bị mất.'**
  String get progressLost;

  /// No description provided for @exitGameTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thoát game?'**
  String get exitGameTitle;

  /// No description provided for @levelCaps.
  ///
  /// In vi, this message translates to:
  /// **'LEVEL {level}'**
  String levelCaps(int level);

  /// No description provided for @swipeToSeeLetters.
  ///
  /// In vi, this message translates to:
  /// **'← Vuốt ngang để xem các chữ →'**
  String get swipeToSeeLetters;

  /// No description provided for @arrangeLetters.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp các chữ cái'**
  String get arrangeLetters;

  /// No description provided for @firstLetter.
  ///
  /// In vi, this message translates to:
  /// **'Chữ đầu tiên: {letter}'**
  String firstLetter(String letter);

  /// No description provided for @skip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get skip;

  /// No description provided for @completed.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành!'**
  String get completed;

  /// No description provided for @points.
  ///
  /// In vi, this message translates to:
  /// **'Điểm'**
  String get points;

  /// No description provided for @accuracy.
  ///
  /// In vi, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @combo.
  ///
  /// In vi, this message translates to:
  /// **'Combo'**
  String get combo;

  /// No description provided for @hintStat.
  ///
  /// In vi, this message translates to:
  /// **'Hint'**
  String get hintStat;

  /// No description provided for @levelNumber.
  ///
  /// In vi, this message translates to:
  /// **'Level {level}'**
  String levelNumber(int level);

  /// No description provided for @backHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get backHome;

  /// No description provided for @daysCaps.
  ///
  /// In vi, this message translates to:
  /// **'DAYS'**
  String get daysCaps;

  /// No description provided for @monthSummary.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã hoàn thành {count} buổi tập trong {month}, và {yearCount} buổi trong năm nay.'**
  String monthSummary(int count, String month, int yearCount);

  /// No description provided for @mistakesPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã mắc'**
  String get mistakesPrefix;

  /// No description provided for @mistakesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} lỗi ngữ pháp'**
  String mistakesCount(int count);

  /// No description provided for @mistakesMiddle.
  ///
  /// In vi, this message translates to:
  /// **'trong tháng này, chủ yếu là'**
  String get mistakesMiddle;

  /// No description provided for @mistakesTopic.
  ///
  /// In vi, this message translates to:
  /// **'từ vựng'**
  String get mistakesTopic;

  /// No description provided for @seeSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Xem gợi ý cải thiện'**
  String get seeSuggestions;

  /// No description provided for @suggestionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý cải thiện'**
  String get suggestionsTitle;

  /// No description provided for @madeByAi.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bởi AI'**
  String get madeByAi;

  /// No description provided for @madeByAiBody.
  ///
  /// In vi, this message translates to:
  /// **'Phần thống kê và gợi ý cải thiện được AI tổng hợp từ các buổi học trong tháng của bạn. Nội dung có thể chưa chính xác hoàn toàn; hãy dùng như lời khuyên tham khảo.'**
  String get madeByAiBody;

  /// No description provided for @weekdaysMonFirst.
  ///
  /// In vi, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get weekdaysMonFirst;

  /// No description provided for @weekdaysSunFirst.
  ///
  /// In vi, this message translates to:
  /// **'CN,T2,T3,T4,T5,T6,T7'**
  String get weekdaysSunFirst;

  /// No description provided for @thisWeekActivity.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động tuần này'**
  String get thisWeekActivity;

  /// No description provided for @withHifive.
  ///
  /// In vi, this message translates to:
  /// **'Cùng Hifive'**
  String get withHifive;

  /// No description provided for @withPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ở cùng'**
  String get withPrefix;

  /// No description provided for @withMiddle.
  ///
  /// In vi, this message translates to:
  /// **'được'**
  String get withMiddle;

  /// No description provided for @withDays.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày. '**
  String withDays(int days);

  /// No description provided for @thanksForJourney.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn đã đồng hành!'**
  String get thanksForJourney;

  /// No description provided for @monthYearShort.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}, {year}'**
  String monthYearShort(int month, int year);

  /// No description provided for @currentStreak.
  ///
  /// In vi, this message translates to:
  /// **'Streak hiện tại'**
  String get currentStreak;

  /// No description provided for @updatedToday.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật lúc {time} hôm nay'**
  String updatedToday(String time);

  /// No description provided for @unitWords.
  ///
  /// In vi, this message translates to:
  /// **'TỪ'**
  String get unitWords;

  /// No description provided for @vocabularyLearned.
  ///
  /// In vi, this message translates to:
  /// **'Từ vựng học'**
  String get vocabularyLearned;

  /// No description provided for @unitHours.
  ///
  /// In vi, this message translates to:
  /// **'GIỜ'**
  String get unitHours;

  /// No description provided for @studyTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get studyTime;

  /// No description provided for @unitSessions.
  ///
  /// In vi, this message translates to:
  /// **'BUỔI'**
  String get unitSessions;

  /// No description provided for @sessionsDone.
  ///
  /// In vi, this message translates to:
  /// **'Buổi hoàn thành'**
  String get sessionsDone;

  /// No description provided for @unitSentences.
  ///
  /// In vi, this message translates to:
  /// **'CÂU'**
  String get unitSentences;

  /// No description provided for @sentencesPractised.
  ///
  /// In vi, this message translates to:
  /// **'Câu luyện tập'**
  String get sentencesPractised;

  /// No description provided for @unitParagraphs.
  ///
  /// In vi, this message translates to:
  /// **'ĐOẠN'**
  String get unitParagraphs;

  /// No description provided for @noMistakesMonth.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có lỗi ngữ pháp nào trong tháng này. Tuyệt vời!'**
  String get noMistakesMonth;

  /// No description provided for @makingSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo gợi ý...'**
  String get makingSuggestions;

  /// No description provided for @suggestionsFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được gợi ý'**
  String get suggestionsFailed;

  /// No description provided for @aiServiceDown.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ AI đang gặp sự cố. Vui lòng thử lại.'**
  String get aiServiceDown;

  /// No description provided for @streakTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi Streak'**
  String get streakTitle;

  /// No description provided for @onFire.
  ///
  /// In vi, this message translates to:
  /// **'ON FIRE'**
  String get onFire;

  /// No description provided for @daysInARow.
  ///
  /// In vi, this message translates to:
  /// **'ngày liên tiếp'**
  String get daysInARow;

  /// No description provided for @startStreakToday.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu chuỗi học tập ngay hôm nay!'**
  String get startStreakToday;

  /// No description provided for @keepHabit.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục duy trì thói quen tuyệt vời này!'**
  String get keepHabit;

  /// No description provided for @previousMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng sau'**
  String get nextMonth;

  /// No description provided for @studiedDays.
  ///
  /// In vi, this message translates to:
  /// **'Đã học {count} ngày'**
  String studiedDays(int count);

  /// No description provided for @currentCaps.
  ///
  /// In vi, this message translates to:
  /// **'HIỆN TẠI'**
  String get currentCaps;

  /// No description provided for @longestCaps.
  ///
  /// In vi, this message translates to:
  /// **'DÀI NHẤT'**
  String get longestCaps;

  /// No description provided for @sectionParagraph.
  ///
  /// In vi, this message translates to:
  /// **'Đoạn văn'**
  String get sectionParagraph;

  /// No description provided for @sectionSentence.
  ///
  /// In vi, this message translates to:
  /// **'Câu'**
  String get sectionSentence;

  /// No description provided for @sectionChat.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại'**
  String get sectionChat;

  /// No description provided for @clearAll.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả'**
  String get clearAll;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa lịch sử cục bộ?'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryBody.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xóa kết quả trên bản ứng dụng này. Hành động không thể hoàn tác.'**
  String get clearHistoryBody;

  /// No description provided for @newPractice.
  ///
  /// In vi, this message translates to:
  /// **'Luyện tập mới'**
  String get newPractice;

  /// No description provided for @noReviewsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bài ôn tập'**
  String get noReviewsYet;

  /// No description provided for @noResultsFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy kết quả'**
  String get noResultsFound;

  /// No description provided for @finishLessonToSave.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành một bài học để lưu lại tiến bộ của bạn.'**
  String get finishLessonToSave;

  /// No description provided for @tryAnotherKeyword.
  ///
  /// In vi, this message translates to:
  /// **'Thử một từ khóa khác.'**
  String get tryAnotherKeyword;

  /// No description provided for @reviewSection.
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập'**
  String get reviewSection;

  /// No description provided for @sessionsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} sessions'**
  String sessionsCount(int count);

  /// No description provided for @historyOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn lịch sử'**
  String get historyOptions;

  /// No description provided for @searchHistoryHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm tiêu đề, mô tả...'**
  String get searchHistoryHint;

  /// No description provided for @closeSearch.
  ///
  /// In vi, this message translates to:
  /// **'Đóng tìm kiếm'**
  String get closeSearch;

  /// No description provided for @newPracticeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bài luyện tập mới'**
  String get newPracticeLabel;

  /// No description provided for @seeMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm'**
  String get seeMore;

  /// No description provided for @helpTitle1.
  ///
  /// In vi, this message translates to:
  /// **'3 Chế Độ Luyện Tập Chính'**
  String get helpTitle1;

  /// No description provided for @helpTitle2.
  ///
  /// In vi, this message translates to:
  /// **'Trợ Lý AI & Hệ Thống Phản Hồi'**
  String get helpTitle2;

  /// No description provided for @helpTitle3.
  ///
  /// In vi, this message translates to:
  /// **'AI Magic Generator'**
  String get helpTitle3;

  /// No description provided for @helpTitle4.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống Flashcard & SRS'**
  String get helpTitle4;

  /// No description provided for @helpTitle5.
  ///
  /// In vi, this message translates to:
  /// **'Hệ Thống Theo Dõi Tiến Độ'**
  String get helpTitle5;

  /// No description provided for @helpTitle6.
  ///
  /// In vi, this message translates to:
  /// **'Chức Năng Ôn Tập Thông Minh'**
  String get helpTitle6;

  /// No description provided for @helpTitle7.
  ///
  /// In vi, this message translates to:
  /// **'Mini Game: Flow Letter'**
  String get helpTitle7;

  /// No description provided for @helpBody1.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng cung cấp 3 phương thức thực hành riêng biệt nhằm phát triển toàn diện các kỹ năng:\n\n• Đoạn văn (Paragraph): Tập trung kỹ năng viết và dịch thuật văn bản dài. Người dùng viết đoạn văn theo gợi ý, sau đó AI sẽ chấm điểm và chỉnh sửa văn phong tự nhiên.\n\n• Luyện câu (Sentence): Giải quyết các lỗi ngữ pháp và cấu trúc trong câu đơn. Phù hợp cho việc ôn tập nhanh các quy tắc ngữ pháp cơ bản.\n\n• Hội thoại (Conversation): Thực hành phản xạ giao tiếp. Bao gồm chế độ \'Kịch bản\' (tình huống giả định như đi du lịch, phỏng vấn) và \'Tự do\' (trò chuyện mở với AI).'**
  String get helpBody1;

  /// No description provided for @helpBody2.
  ///
  /// In vi, this message translates to:
  /// **'Sau mỗi bài tập, AI sẽ cung cấp phân tích chi tiết để người dùng hiểu rõ các lỗi đã mắc phải:\n\n1. Nhận diện lỗi: Màu đỏ đánh dấu các lỗi sai về ngữ pháp hoặc từ vựng cần sửa đổi.\n2. Gợi ý nâng cao: Màu xanh lá hiển thị các cách diễn đạt tự nhiên hơn hoặc chính xác hơn về mặt ngữ cảnh.\n3. Giải thích chi tiết: Chạm vào vùng được đánh dấu lỗi hoặc gợi ý để xem giải thích sâu về quy tắc ngôn ngữ hoặc lý do tại sao gợi ý đó lại tốt hơn.'**
  String get helpBody2;

  /// No description provided for @helpBody3.
  ///
  /// In vi, this message translates to:
  /// **'AI Magic Generator cho phép người dùng tự thiết kế lộ trình học tập dựa trên nhu cầu thực tế thay vì các bài học cố định:\n\n1. Cách sử dụng: Nhập bất kỳ chủ đề hoặc tình huống cụ thể (Ví dụ: \'Phỏng vấn xin việc\', \'Email phàn nàn về dịch vụ\', \'Hội thoại đi mua sắm\').\n2. Tùy chỉnh: Lựa chọn độ khó từ Cơ bản đến Nâng cao để nội dung bài tập được tối ưu theo trình độ của bạn.\n3. Kết quả: AI sẽ phân tích yêu cầu và tạo ra các bài tập cụ thể (Viết hoặc Hội thoại) liên quan trực tiếp đến chủ đề đã nhập.'**
  String get helpBody3;

  /// No description provided for @helpBody4.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống tích hợp giúp bạn lưu trữ và ôn tập từ vựng hiệu quả thông qua phương pháp lặp lại ngắt quãng (Spaced Repetition):\n\n1. Thu thập từ: Trong quá trình luyện tập, chạm vào bất kỳ từ nào bạn chưa biết để xem định nghĩa và nhấn nút \'Lưu\' để thêm vào bộ sưu tập cá nhân.\n2. Cơ chế ôn tập: Ứng dụng tự động tính toán và nhắc nhở ôn tập các từ đã lưu dựa trên mức độ ghi nhớ của bạn (Sử dụng các mức: Luyện lại, Tốt, Dễ).\n3. Thư viện: Quản lý các bộ từ vựng theo chủ đề để tập trung ôn luyện vào các nhóm từ vựng cụ thể.'**
  String get helpBody4;

  /// No description provided for @helpBody5.
  ///
  /// In vi, this message translates to:
  /// **'Các công cụ giúp người dùng đánh giá quá trình học tập theo thời gian:\n\n1. Lịch (Calendar): Ghi nhận chi tiết các ngày có tham gia học tập trong tháng dưới dạng giao diện lịch trực quan.\n2. Chuỗi (Streak): Đếm số ngày liên tiếp luyện tập nhằm khuyến khích thói quen học tập hàng ngày.\n3. Huy hiệu: Các mốc thành tựu ghi nhận sự nỗ lực khi người dùng đạt được các mục tiêu học tập nhất định.'**
  String get helpBody5;

  /// No description provided for @helpBody6.
  ///
  /// In vi, this message translates to:
  /// **'Mục Ôn tập là nơi lưu trữ toàn bộ lịch sử học tập để bạn củng cố kiến thức:\n\n1. Xem lại lịch sử: Truy cập và xem lại nội dung bài làm bất cứ lúc nào, bao gồm các sửa lỗi và nhận xét chi tiết của AI.\n2. Chức năng Làm lại (Redo): Cho phép thực hiện lại các bài tập đã hoàn thành để kiểm tra mức độ cải thiện kỹ năng so với lần làm trước.'**
  String get helpBody6;

  /// No description provided for @helpBody7.
  ///
  /// In vi, this message translates to:
  /// **'Đây là phương thức học tập bổ trợ thông qua mô hình trò chơi giải đố:\n\n1. Cách chơi: Hệ thống hiển thị các chữ cái bị xáo trộn, nhiệm vụ của bạn là sắp xếp lại thành từ vựng hoàn chỉnh dựa trên định nghĩa hoặc ví dụ.\n2. Hỗ trợ Offline: Đây là tính năng duy nhất trong ứng dụng có thể sử dụng khi thiết bị không có kết nối internet.\n3. Giới hạn: Hiện tại tính năng này chỉ được thiết kế dành riêng cho ngôn ngữ học tập là Tiếng Anh.'**
  String get helpBody7;

  /// No description provided for @privacyAiCoach.
  ///
  /// In vi, this message translates to:
  /// **'Huấn luyện viên AI'**
  String get privacyAiCoach;

  /// No description provided for @privacyAiCoachBody.
  ///
  /// In vi, this message translates to:
  /// **'Hifive đồng bộ dữ liệu học tập của bạn lên cơ sở dữ liệu riêng tư để bạn có thể truy cập từ mọi nơi. Khi bạn sử dụng Huấn luyện viên AI, hệ thống sẽ xử lý các yêu cầu một cách bảo mật để đưa ra gợi ý, hoàn toàn không chia sẻ hay lưu trữ dữ liệu này cho mục đích khác.'**
  String get privacyAiCoachBody;

  /// No description provided for @privacyCollectTitle.
  ///
  /// In vi, this message translates to:
  /// **'1. Thông tin chúng tôi thu thập'**
  String get privacyCollectTitle;

  /// No description provided for @privacyCollectBody.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi thu thập thông tin để cung cấp dịch vụ tốt hơn cho tất cả người dùng. Bao gồm:\n• Dữ liệu cá nhân: Khi bạn đăng ký, chúng tôi có thể thu thập tên, địa chỉ email và ảnh đại diện của bạn.\n• Dữ liệu sử dụng: Chúng tôi thu thập thông tin về cách Dịch vụ được truy cập và sử dụng, chẳng hạn như loại thiết bị của bạn, phiên bản hệ điều hành và thời gian dành cho các trang.'**
  String get privacyCollectBody;

  /// No description provided for @privacyUseTitle.
  ///
  /// In vi, this message translates to:
  /// **'2. Cách chúng tôi sử dụng thông tin của bạn'**
  String get privacyUseTitle;

  /// No description provided for @privacyUseBody.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi sử dụng dữ liệu đã thu thập cho nhiều mục đích khác nhau:\n• Để cung cấp và duy trì Dịch vụ của chúng tôi\n• Để thông báo cho bạn về những thay đổi đối với Dịch vụ của chúng tôi\n• Để cho phép bạn tham gia vào các tính năng tương tác khi bạn chọn làm như vậy\n• Để cung cấp hỗ trợ khách hàng\n• Để thu thập phân tích hoặc thông tin có giá trị để chúng tôi có thể cải thiện Dịch vụ của mình'**
  String get privacyUseBody;

  /// No description provided for @privacyKeepTitle.
  ///
  /// In vi, this message translates to:
  /// **'3. Lưu giữ dữ liệu'**
  String get privacyKeepTitle;

  /// No description provided for @privacyKeepBody.
  ///
  /// In vi, this message translates to:
  /// **'Hifive sẽ chỉ lưu giữ Dữ liệu cá nhân của bạn trong khoảng thời gian cần thiết cho các mục đích được nêu trong Chính sách quyền riêng tư này. Chúng tôi sẽ lưu giữ và sử dụng Dữ liệu cá nhân của bạn trong phạm vi cần thiết để tuân thủ các nghĩa vụ pháp lý của chúng tôi, giải quyết tranh chấp và thực thi các thỏa thuận và chính sách pháp lý của chúng tôi.'**
  String get privacyKeepBody;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In vi, this message translates to:
  /// **'4. Bảo mật dữ liệu của bạn'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecurityBody.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật dữ liệu của bạn rất quan trọng đối với chúng tôi, nhưng hãy nhớ rằng không có phương thức truyền qua Internet hoặc phương thức lưu trữ điện tử nào là an toàn 100%. Mặc dù chúng tôi cố gắng sử dụng các phương tiện thương mại có thể chấp nhận được để bảo vệ Dữ liệu cá nhân của bạn, chúng tôi không thể đảm bảo tính bảo mật tuyệt đối của nó.'**
  String get privacySecurityBody;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In vi, this message translates to:
  /// **'5. Quyền riêng tư của trẻ em'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildrenBody.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ của chúng tôi không giải quyết bất kỳ ai dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin nhận dạng cá nhân từ bất kỳ ai dưới 13 tuổi. Nếu bạn là cha mẹ hoặc người giám hộ và bạn biết rằng Con bạn đã cung cấp cho chúng tôi Dữ liệu cá nhân, vui lòng liên hệ với chúng tôi.'**
  String get privacyChildrenBody;

  /// No description provided for @privacyHeadline1.
  ///
  /// In vi, this message translates to:
  /// **'Hiểu những gì bạn cần,'**
  String get privacyHeadline1;

  /// No description provided for @privacyHeadline2.
  ///
  /// In vi, this message translates to:
  /// **'chứ không phải bạn là ai'**
  String get privacyHeadline2;

  /// No description provided for @privacyUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật lần cuối: 07/01/2026'**
  String get privacyUpdated;

  /// No description provided for @privacyIntro.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư của bạn là ưu tiên hàng đầu. Chúng tôi kinh doanh dựa trên sự ủng hộ (đăng ký) của bạn, không phải dữ liệu của bạn. Thông tin của bạn được lưu trữ an toàn trong cơ sở dữ liệu được mã hóa của chúng tôi. Chúng tôi tuyệt đối không chia sẻ dữ liệu cá nhân hay nội dung bạn sử dụng với AI cho bất kỳ bên thứ ba nào, và không sử dụng chúng để huấn luyện các mô hình AI công cộng.'**
  String get privacyIntro;

  /// No description provided for @contactUs.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ với chúng tôi'**
  String get contactUs;

  /// No description provided for @alwaysListening.
  ///
  /// In vi, this message translates to:
  /// **'Chúng mình luôn sẵn sàng lắng nghe bạn.'**
  String get alwaysListening;

  /// No description provided for @noSupportEmailLocal.
  ///
  /// In vi, this message translates to:
  /// **'Bản cục bộ không có email hỗ trợ.'**
  String get noSupportEmailLocal;

  /// No description provided for @supportEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email Hỗ trợ'**
  String get supportEmail;

  /// No description provided for @notInLocalBuild.
  ///
  /// In vi, this message translates to:
  /// **'Không có ở bản cục bộ'**
  String get notInLocalBuild;

  /// No description provided for @done.
  ///
  /// In vi, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @plusNoTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Bản cục bộ này không có giao dịch hoặc đăng ký.'**
  String get plusNoTransaction;

  /// No description provided for @plusYearlyNote.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử miễn phí 7 ngày. Sau đó tự động gia hạn với giá 349.000đ/năm. Hủy bất cứ lúc nào.'**
  String get plusYearlyNote;

  /// No description provided for @plusMonthlyNote.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử miễn phí 3 ngày. Sau đó tự động gia hạn với giá 49.000đ/tháng. Hủy bất cứ lúc nào.'**
  String get plusMonthlyNote;

  /// No description provided for @plusTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nâng cấp Hifive+'**
  String get plusTitle;

  /// No description provided for @plusYearlyCta.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử 7 ngày • sau đó 349.000đ/năm'**
  String get plusYearlyCta;

  /// No description provided for @plusMonthlyCta.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử 3 ngày • sau đó 49.000đ/tháng'**
  String get plusMonthlyCta;

  /// No description provided for @planYearly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng năm'**
  String get planYearly;

  /// No description provided for @planYearlyPerMonth.
  ///
  /// In vi, this message translates to:
  /// **'₫29.083 / tháng'**
  String get planYearlyPerMonth;

  /// No description provided for @perYear.
  ///
  /// In vi, this message translates to:
  /// **' / năm'**
  String get perYear;

  /// No description provided for @planYearlyTrial.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày miễn phí, sau\nđó 349.000đ'**
  String get planYearlyTrial;

  /// No description provided for @save40.
  ///
  /// In vi, this message translates to:
  /// **'Giảm 40%'**
  String get save40;

  /// No description provided for @planMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng tháng'**
  String get planMonthly;

  /// No description provided for @planMonthlyPerMonth.
  ///
  /// In vi, this message translates to:
  /// **'₫49.000 / tháng'**
  String get planMonthlyPerMonth;

  /// No description provided for @perMonth.
  ///
  /// In vi, this message translates to:
  /// **' / tháng'**
  String get perMonth;

  /// No description provided for @planMonthlyTrial.
  ///
  /// In vi, this message translates to:
  /// **'3 ngày miễn phí, sau đó 49.000đ'**
  String get planMonthlyTrial;

  /// No description provided for @priceYearly.
  ///
  /// In vi, this message translates to:
  /// **'349.000đ'**
  String get priceYearly;

  /// No description provided for @priceMonthly.
  ///
  /// In vi, this message translates to:
  /// **'49.000đ'**
  String get priceMonthly;

  /// No description provided for @plusPerksTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặc quyền gói Hifive Plus'**
  String get plusPerksTitle;

  /// No description provided for @plusPerksBody.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa toàn bộ tính năng cao cấp để học ngoại ngữ hiệu quả hơn, nhanh hơn và thú vị hơn.'**
  String get plusPerksBody;

  /// No description provided for @plusRenewalNote.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi mua, bạn có thể quản lý và tắt tính năng tự động gia hạn trong cài đặt tài khoản iTunes & App Store của mình.'**
  String get plusRenewalNote;

  /// No description provided for @cannotOpenTermsPage.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trang điều khoản.'**
  String get cannotOpenTermsPage;

  /// No description provided for @privacyShort.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get privacyShort;

  /// No description provided for @restore.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get restore;

  /// No description provided for @perkLimitsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mức cao hơn'**
  String get perkLimitsTitle;

  /// No description provided for @perkLimitsBody.
  ///
  /// In vi, this message translates to:
  /// **'Mức sử dụng AI cao hơn mỗi ngày so với gói Miễn phí. Học từ vựng, ngữ pháp và giao tiếp theo phong cách riêng của bạn.'**
  String get perkLimitsBody;

  /// No description provided for @perkDecksTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kho Flashcard mở rộng'**
  String get perkDecksTitle;

  /// No description provided for @perkDecksBody.
  ///
  /// In vi, this message translates to:
  /// **'Tạo và quản lý bộ từ vựng với số lượng cực lớn. Học thông minh với flashcard được cá nhân hóa theo tiến độ của bạn.'**
  String get perkDecksBody;

  /// No description provided for @perkChatTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chat AI nhiều hơn'**
  String get perkChatTitle;

  /// No description provided for @perkChatBody.
  ///
  /// In vi, this message translates to:
  /// **'Luyện tập hội thoại thực tế với mức sử dụng cao hơn. Nhận phản hồi chi tiết để cải thiện kỹ năng giao tiếp nhanh chóng.'**
  String get perkChatBody;

  /// No description provided for @perkInfiniteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ Vô cực'**
  String get perkInfiniteTitle;

  /// No description provided for @perkInfiniteBody.
  ///
  /// In vi, this message translates to:
  /// **'Truy cập chế độ luyện câu nâng cao với độ khó tăng dần. Thử thách bản thân và đạt điểm số cao nhất.'**
  String get perkInfiniteBody;

  /// No description provided for @perkEarlyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Truy cập sớm các tính năng'**
  String get perkEarlyTitle;

  /// No description provided for @perkEarlyBody.
  ///
  /// In vi, this message translates to:
  /// **'Trải nghiệm trước những tính năng mới nhất cùng các nội dung độc quyền.'**
  String get perkEarlyBody;

  /// No description provided for @perkLanguagesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả ngôn ngữ'**
  String get perkLanguagesTitle;

  /// No description provided for @perkLanguagesBody.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa toàn bộ ngôn ngữ hỗ trợ. Học bất kỳ ngôn ngữ nào bạn muốn với cùng một tài khoản.'**
  String get perkLanguagesBody;

  /// No description provided for @comingSoonLower.
  ///
  /// In vi, this message translates to:
  /// **'coming soon'**
  String get comingSoonLower;

  /// No description provided for @heroSlide1Top.
  ///
  /// In vi, this message translates to:
  /// **'hifive'**
  String get heroSlide1Top;

  /// No description provided for @heroSlide1Bottom.
  ///
  /// In vi, this message translates to:
  /// **'plus'**
  String get heroSlide1Bottom;

  /// No description provided for @heroSlide1Body.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa toàn bộ tính năng AI cao cấp với mức sử dụng cao hơn.'**
  String get heroSlide1Body;

  /// No description provided for @heroSlide2Top.
  ///
  /// In vi, this message translates to:
  /// **'hạn mức'**
  String get heroSlide2Top;

  /// No description provided for @heroSlide2Bottom.
  ///
  /// In vi, this message translates to:
  /// **'cao hơn'**
  String get heroSlide2Bottom;

  /// No description provided for @heroSlide2Body.
  ///
  /// In vi, this message translates to:
  /// **'Mức sử dụng AI cao hơn so với gói Miễn phí. Tạo flashcard và học mọi chủ đề.'**
  String get heroSlide2Body;

  /// No description provided for @heroSlide3Top.
  ///
  /// In vi, this message translates to:
  /// **'chinh phục'**
  String get heroSlide3Top;

  /// No description provided for @heroSlide3Bottom.
  ///
  /// In vi, this message translates to:
  /// **'ngoại ngữ'**
  String get heroSlide3Bottom;

  /// No description provided for @heroSlide3Body.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lỗi ngữ pháp và dịch thuật tức thì với AI, giúp bạn tự tin giao tiếp mọi lúc.'**
  String get heroSlide3Body;

  /// No description provided for @more.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get more;

  /// No description provided for @accuracyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Độ chính xác'**
  String get accuracyLabel;

  /// No description provided for @timeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get timeLabel;

  /// No description provided for @correctAnswers.
  ///
  /// In vi, this message translates to:
  /// **'Câu đúng'**
  String get correctAnswers;

  /// No description provided for @originalTextCaps.
  ///
  /// In vi, this message translates to:
  /// **'VĂN BẢN GỐC'**
  String get originalTextCaps;

  /// No description provided for @yourAnswerCaps.
  ///
  /// In vi, this message translates to:
  /// **'CÂU TRẢ LỜI CỦA BẠN'**
  String get yourAnswerCaps;

  /// No description provided for @redoExercise.
  ///
  /// In vi, this message translates to:
  /// **'Làm lại bài tập'**
  String get redoExercise;

  /// No description provided for @excellentEn.
  ///
  /// In vi, this message translates to:
  /// **'Excellent!'**
  String get excellentEn;

  /// No description provided for @keepGoing.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục cố gắng!'**
  String get keepGoing;

  /// No description provided for @masteredLesson.
  ///
  /// In vi, this message translates to:
  /// **'You have mastered this lesson'**
  String get masteredLesson;

  /// No description provided for @everySessionStep.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi buổi học là một bước tiến.'**
  String get everySessionStep;

  /// No description provided for @timeEn.
  ///
  /// In vi, this message translates to:
  /// **'Time'**
  String get timeEn;

  /// No description provided for @correctEn.
  ///
  /// In vi, this message translates to:
  /// **'Correct'**
  String get correctEn;

  /// No description provided for @newStreakStarted.
  ///
  /// In vi, this message translates to:
  /// **'Khởi động chuỗi mới!'**
  String get newStreakStarted;

  /// No description provided for @greatStart.
  ///
  /// In vi, this message translates to:
  /// **'Một khởi đầu tuyệt vời. Hãy duy trì thói quen học tập mỗi ngày nhé!'**
  String get greatStart;

  /// No description provided for @levelA1Title.
  ///
  /// In vi, this message translates to:
  /// **'A1 - Beginner'**
  String get levelA1Title;

  /// No description provided for @levelA2Title.
  ///
  /// In vi, this message translates to:
  /// **'A2 - Elementary'**
  String get levelA2Title;

  /// No description provided for @levelB1Title.
  ///
  /// In vi, this message translates to:
  /// **'B1 - Intermediate'**
  String get levelB1Title;

  /// No description provided for @levelB2Title.
  ///
  /// In vi, this message translates to:
  /// **'B2 - Upper Intermediate'**
  String get levelB2Title;

  /// No description provided for @levelC1Title.
  ///
  /// In vi, this message translates to:
  /// **'C1 - Advanced'**
  String get levelC1Title;

  /// No description provided for @levelC2Title.
  ///
  /// In vi, this message translates to:
  /// **'C2 - Proficient'**
  String get levelC2Title;

  /// No description provided for @levelA1Body.
  ///
  /// In vi, this message translates to:
  /// **'Có thể viết lại và hoàn thành các câu rất ngắn với từ vựng quen thuộc. Phù hợp để luyện mẫu câu cơ bản và diễn đạt ý đơn giản.'**
  String get levelA1Body;

  /// No description provided for @levelA2Body.
  ///
  /// In vi, this message translates to:
  /// **'Có thể viết và chỉnh sửa các câu đơn giản về chủ đề quen thuộc. Bắt đầu nối ý ngắn thành đoạn và giảm lỗi ngữ pháp cơ bản.'**
  String get levelA2Body;

  /// No description provided for @levelB1Body.
  ///
  /// In vi, this message translates to:
  /// **'Có thể viết đoạn văn rõ ý về chủ đề quen thuộc, diễn đạt trải nghiệm, kế hoạch và quan điểm ngắn. Phù hợp để luyện mở rộng câu và liên kết ý.'**
  String get levelB1Body;

  /// No description provided for @levelB2Body.
  ///
  /// In vi, this message translates to:
  /// **'Có thể viết câu và đoạn văn khá tự nhiên, có cấu trúc rõ ràng, diễn đạt quan điểm và lập luận chi tiết hơn. Phù hợp để luyện paraphrase và kiểm soát ngữ pháp tốt hơn.'**
  String get levelB2Body;

  /// No description provided for @levelC1Body.
  ///
  /// In vi, this message translates to:
  /// **'Có thể viết mạch lạc, linh hoạt theo nhiều mục đích học thuật, công việc và cá nhân. Có thể chọn từ ngữ và cấu trúc câu phù hợp với ngữ cảnh.'**
  String get levelC1Body;

  /// No description provided for @levelC2Body.
  ///
  /// In vi, this message translates to:
  /// **'Có thể viết chính xác, tinh tế và tự nhiên gần như người thành thạo. Có thể diễn đạt ý phức tạp rõ ràng và kiểm soát sắc thái ngôn ngữ tốt.'**
  String get levelC2Body;

  /// No description provided for @levelInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cấp độ'**
  String get levelInfoTitle;

  /// No description provided for @changeLevelInSettings.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể thay đổi cấp độ trong Cài đặt'**
  String get changeLevelInSettings;

  /// No description provided for @currentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại'**
  String get currentLabel;

  /// No description provided for @noCategories.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục'**
  String get noCategories;

  /// No description provided for @createModeCaps.
  ///
  /// In vi, this message translates to:
  /// **'CHẾ ĐỘ TẠO'**
  String get createModeCaps;

  /// No description provided for @categoriesCaps.
  ///
  /// In vi, this message translates to:
  /// **'DANH MỤC'**
  String get categoriesCaps;

  /// No description provided for @yourTopicsCaps.
  ///
  /// In vi, this message translates to:
  /// **'CHỦ ĐỀ CỦA BẠN'**
  String get yourTopicsCaps;

  /// No description provided for @relatedTopicsCaps.
  ///
  /// In vi, this message translates to:
  /// **'CHỦ ĐỀ LIÊN QUAN'**
  String get relatedTopicsCaps;

  /// No description provided for @topicsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} chủ đề'**
  String topicsCount(int count);

  /// No description provided for @noTopics.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chủ đề'**
  String get noTopics;

  /// No description provided for @noTopicsBody.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thử danh mục khác hoặc tạo chủ đề bằng AI.'**
  String get noTopicsBody;

  /// No description provided for @questionsShort.
  ///
  /// In vi, this message translates to:
  /// **'Qs'**
  String get questionsShort;

  /// No description provided for @setsShort.
  ///
  /// In vi, this message translates to:
  /// **'Sets'**
  String get setsShort;

  /// No description provided for @lessonsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bài học'**
  String get lessonsTitle;

  /// No description provided for @collectionCaps.
  ///
  /// In vi, this message translates to:
  /// **'BỘ SƯU TẬP'**
  String get collectionCaps;

  /// No description provided for @noLessons.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bài học'**
  String get noLessons;

  /// No description provided for @noLessonsBody.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đề này chưa có bộ bài nào.'**
  String get noLessonsBody;

  /// No description provided for @levelCapsLabel.
  ///
  /// In vi, this message translates to:
  /// **'CẤP ĐỘ'**
  String get levelCapsLabel;

  /// No description provided for @createScenarioQ.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tình huống?'**
  String get createScenarioQ;

  /// No description provided for @topicNotListed.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đề không có trong danh sách?'**
  String get topicNotListed;

  /// No description provided for @roleplayAnything.
  ///
  /// In vi, this message translates to:
  /// **'Nhập vai mọi tình huống với AI'**
  String get roleplayAnything;

  /// No description provided for @customGrammar.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bài tập ngữ pháp tùy chỉnh'**
  String get customGrammar;

  /// No description provided for @createCustom.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tùy chỉnh'**
  String get createCustom;

  /// No description provided for @pronounceTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Phát âm'**
  String get pronounceTooltip;

  /// No description provided for @saveWord.
  ///
  /// In vi, this message translates to:
  /// **'Lưu từ'**
  String get saveWord;

  /// No description provided for @savedWord.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu {word}'**
  String savedWord(String word);

  /// No description provided for @refresh.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get refresh;

  /// No description provided for @endlessMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ Vô tận'**
  String get endlessMode;

  /// No description provided for @endlessBody.
  ///
  /// In vi, this message translates to:
  /// **'Học tập không ngừng'**
  String get endlessBody;

  /// No description provided for @leaveExerciseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thoát bài tập?'**
  String get leaveExerciseTitle;

  /// No description provided for @leaveExerciseBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa hoàn thành bài tập. Tiến độ sẽ không được lưu nếu bạn thoát bây giờ.'**
  String get leaveExerciseBody;

  /// No description provided for @aiHint.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý AI'**
  String get aiHint;

  /// No description provided for @analysingDraft.
  ///
  /// In vi, this message translates to:
  /// **'Đang phân tích bản nháp...'**
  String get analysingDraft;

  /// No description provided for @backgroundColor.
  ///
  /// In vi, this message translates to:
  /// **'Màu nền'**
  String get backgroundColor;

  /// No description provided for @lessonDictionary.
  ///
  /// In vi, this message translates to:
  /// **'Từ điển bài'**
  String get lessonDictionary;

  /// No description provided for @doneVi.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get doneVi;

  /// No description provided for @hideHints.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn gợi ý'**
  String get hideHints;

  /// No description provided for @showHints.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị gợi ý'**
  String get showHints;

  /// No description provided for @feedbackNoted.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận đánh giá trong phiên học này'**
  String get feedbackNoted;

  /// No description provided for @leaveExercise.
  ///
  /// In vi, this message translates to:
  /// **'Thoát bài tập'**
  String get leaveExercise;

  /// No description provided for @lessonOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn bài học'**
  String get lessonOptions;

  /// No description provided for @typeAnswer.
  ///
  /// In vi, this message translates to:
  /// **'Nhập câu trả lời...'**
  String get typeAnswer;

  /// No description provided for @previousSentence.
  ///
  /// In vi, this message translates to:
  /// **'Câu trước'**
  String get previousSentence;

  /// No description provided for @hiddenHint.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý ẩn'**
  String get hiddenHint;

  /// No description provided for @like.
  ///
  /// In vi, this message translates to:
  /// **'Thích'**
  String get like;

  /// No description provided for @dislike.
  ///
  /// In vi, this message translates to:
  /// **'Không thích'**
  String get dislike;

  /// No description provided for @next.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển tiếp'**
  String get next;

  /// No description provided for @sentencesList.
  ///
  /// In vi, this message translates to:
  /// **'Câu {list}'**
  String sentencesList(String list);

  /// No description provided for @saveItem.
  ///
  /// In vi, this message translates to:
  /// **'Lưu {word}'**
  String saveItem(String word);

  /// No description provided for @excellentShort.
  ///
  /// In vi, this message translates to:
  /// **'Xuất sắc'**
  String get excellentShort;

  /// No description provided for @fixCaps.
  ///
  /// In vi, this message translates to:
  /// **'SỬA LỖI'**
  String get fixCaps;

  /// No description provided for @tapWordToLookUp.
  ///
  /// In vi, this message translates to:
  /// **'Chạm từ để tra cứu'**
  String get tapWordToLookUp;

  /// No description provided for @keyImprovementsCaps.
  ///
  /// In vi, this message translates to:
  /// **'KEY IMPROVEMENTS'**
  String get keyImprovementsCaps;

  /// No description provided for @tipsCaps.
  ///
  /// In vi, this message translates to:
  /// **'MẸO'**
  String get tipsCaps;

  /// No description provided for @tipKeepMeaning.
  ///
  /// In vi, this message translates to:
  /// **'Giữ đúng ý và thời gian của câu gốc.'**
  String get tipKeepMeaning;

  /// No description provided for @tipSubjectVerb.
  ///
  /// In vi, this message translates to:
  /// **'Đối chiếu chủ ngữ và động từ.'**
  String get tipSubjectVerb;

  /// No description provided for @tipTapReference.
  ///
  /// In vi, this message translates to:
  /// **'Chạm từ trong câu tham khảo để tra nghĩa.'**
  String get tipTapReference;

  /// No description provided for @seeAiAnalysisBody.
  ///
  /// In vi, this message translates to:
  /// **'Xem phân tích chi tiết từ AI cho câu trả lời của bạn.'**
  String get seeAiAnalysisBody;

  /// No description provided for @seeAiAnalysis.
  ///
  /// In vi, this message translates to:
  /// **'Xem phân tích AI'**
  String get seeAiAnalysis;

  /// No description provided for @editEn.
  ///
  /// In vi, this message translates to:
  /// **'Edit'**
  String get editEn;

  /// No description provided for @editVi.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get editVi;

  /// No description provided for @nextSentence.
  ///
  /// In vi, this message translates to:
  /// **'Câu tiếp theo'**
  String get nextSentence;

  /// No description provided for @nextEn.
  ///
  /// In vi, this message translates to:
  /// **'Next'**
  String get nextEn;

  /// No description provided for @nextVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo'**
  String get nextVi;

  /// No description provided for @helpful.
  ///
  /// In vi, this message translates to:
  /// **'Hữu ích'**
  String get helpful;

  /// No description provided for @notHelpful.
  ///
  /// In vi, this message translates to:
  /// **'Chưa hữu ích'**
  String get notHelpful;

  /// No description provided for @gradingFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không chấm được câu trả lời'**
  String get gradingFailed;

  /// No description provided for @gradingFailedBody.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối hoặc dịch vụ AI đang gặp sự cố.'**
  String get gradingFailedBody;

  /// No description provided for @grading.
  ///
  /// In vi, this message translates to:
  /// **'Đang chấm điểm...'**
  String get grading;

  /// No description provided for @fixCapsStar.
  ///
  /// In vi, this message translates to:
  /// **'✦  SỬA LỖI'**
  String get fixCapsStar;

  /// No description provided for @gradeCorrect.
  ///
  /// In vi, this message translates to:
  /// **'Chính xác'**
  String get gradeCorrect;

  /// No description provided for @gradeNear.
  ///
  /// In vi, this message translates to:
  /// **'Gần đúng'**
  String get gradeNear;

  /// No description provided for @gradeIncorrect.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đúng'**
  String get gradeIncorrect;

  /// No description provided for @leaveChatTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thoát hội thoại?'**
  String get leaveChatTitle;

  /// No description provided for @leaveChatBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa hoàn thành hội thoại. Tiến độ của phiên này sẽ không được lưu nếu bạn thoát bây giờ.'**
  String get leaveChatBody;

  /// No description provided for @leaveChat.
  ///
  /// In vi, this message translates to:
  /// **'Thoát hội thoại'**
  String get leaveChat;

  /// No description provided for @freeChat.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện Tự do'**
  String get freeChat;

  /// No description provided for @scriptMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ Kịch bản'**
  String get scriptMode;

  /// No description provided for @toneLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giọng: {tone}'**
  String toneLabel(String tone);

  /// No description provided for @sayThis.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nói: {prompt}'**
  String sayThis(String prompt);

  /// No description provided for @answerFreelyEnglish.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời tự do bằng tiếng Anh'**
  String get answerFreelyEnglish;

  /// No description provided for @sendAction.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get sendAction;

  /// No description provided for @listenToLine.
  ///
  /// In vi, this message translates to:
  /// **'Nghe câu này'**
  String get listenToLine;

  /// No description provided for @hideTranslation.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn bản dịch'**
  String get hideTranslation;

  /// No description provided for @showTranslation.
  ///
  /// In vi, this message translates to:
  /// **'Xem bản dịch'**
  String get showTranslation;

  /// No description provided for @hintWith.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý: {answer}'**
  String hintWith(String answer);

  /// No description provided for @sendFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi được câu trả lời.'**
  String get sendFailed;

  /// No description provided for @customCaps.
  ///
  /// In vi, this message translates to:
  /// **'TÙY CHỈNH'**
  String get customCaps;

  /// No description provided for @practiceFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được bài luyện tập. Vui lòng thử lại.'**
  String get practiceFailed;

  /// No description provided for @noSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gợi ý'**
  String get noSuggestions;

  /// No description provided for @describeOwnTopic.
  ///
  /// In vi, this message translates to:
  /// **'Hãy tự mô tả chủ đề bạn muốn luyện tập.'**
  String get describeOwnTopic;

  /// No description provided for @createOwnTopic.
  ///
  /// In vi, this message translates to:
  /// **'Tạo chủ đề độc đáo của riêng bạn.'**
  String get createOwnTopic;

  /// No description provided for @createWithAiCaps.
  ///
  /// In vi, this message translates to:
  /// **'TẠO BẰNG AI'**
  String get createWithAiCaps;

  /// No description provided for @chooseTopicCaps.
  ///
  /// In vi, this message translates to:
  /// **'CHỌN CHỦ ĐỀ'**
  String get chooseTopicCaps;

  /// No description provided for @describeTopicCaps.
  ///
  /// In vi, this message translates to:
  /// **'MÔ TẢ CHỦ ĐỀ'**
  String get describeTopicCaps;

  /// No description provided for @startPractice.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu luyện tập'**
  String get startPractice;

  /// No description provided for @createScenario.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tình huống'**
  String get createScenario;

  /// No description provided for @createSentences.
  ///
  /// In vi, this message translates to:
  /// **'Tạo Câu Luyện Tập'**
  String get createSentences;

  /// No description provided for @customTopicHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: \'Phrasal Verbs với Get\', \'Câu hỏi phỏng vấn\'...'**
  String get customTopicHint;

  /// No description provided for @startPracticeCaps.
  ///
  /// In vi, this message translates to:
  /// **'Bắt Đầu Luyện Tập'**
  String get startPracticeCaps;

  /// No description provided for @settingsGuideTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn Cài đặt'**
  String get settingsGuideTitle;

  /// No description provided for @settingsGuideBody.
  ///
  /// In vi, this message translates to:
  /// **'Hiểu rõ các cài đặt giúp bạn tối ưu hóa việc luyện tập hội thoại.'**
  String get settingsGuideBody;

  /// No description provided for @learningModeCaps.
  ///
  /// In vi, this message translates to:
  /// **'CHẾ ĐỘ HỌC'**
  String get learningModeCaps;

  /// No description provided for @freeChatBody.
  ///
  /// In vi, this message translates to:
  /// **'Hội thoại mở. AI thích ứng với câu trả lời của bạn. Phù hợp cho luyện tập nâng cao.'**
  String get freeChatBody;

  /// No description provided for @scriptModeBody.
  ///
  /// In vi, this message translates to:
  /// **'Tuân theo kịch bản cụ thể. Phù hợp cho người mới bắt đầu cần hướng dẫn rõ ràng.'**
  String get scriptModeBody;

  /// No description provided for @tonePersonalityCaps.
  ///
  /// In vi, this message translates to:
  /// **'GIỌNG & TÍNH CÁCH'**
  String get tonePersonalityCaps;

  /// No description provided for @toneFormal.
  ///
  /// In vi, this message translates to:
  /// **'Trang trọng'**
  String get toneFormal;

  /// No description provided for @toneFormalBody.
  ///
  /// In vi, this message translates to:
  /// **'Chuyên nghiệp và lịch sự. Phù hợp cho công việc và các tình huống trang trọng.'**
  String get toneFormalBody;

  /// No description provided for @toneCasual.
  ///
  /// In vi, this message translates to:
  /// **'Thoải mái'**
  String get toneCasual;

  /// No description provided for @toneCasualBody.
  ///
  /// In vi, this message translates to:
  /// **'Tự nhiên như trò chuyện với bạn bè, dùng nhiều cách nói đời thường.'**
  String get toneCasualBody;

  /// No description provided for @toneFriendly.
  ///
  /// In vi, this message translates to:
  /// **'Thân thiện'**
  String get toneFriendly;

  /// No description provided for @toneFriendlyBody.
  ///
  /// In vi, this message translates to:
  /// **'Nhẹ nhàng, khích lệ và kiên nhẫn khi bạn cần thêm thời gian.'**
  String get toneFriendlyBody;

  /// No description provided for @customizeLesson.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh bài học'**
  String get customizeLesson;

  /// No description provided for @customizeLessonTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh Bài học'**
  String get customizeLessonTitle;

  /// No description provided for @customizeLessonBody.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển đổi giữa Trò chuyện Tự do và Kịch bản. Điều chỉnh độ khó, giọng và số câu hỏi.'**
  String get customizeLessonBody;

  /// No description provided for @closeTip.
  ///
  /// In vi, this message translates to:
  /// **'Đóng gợi ý'**
  String get closeTip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
