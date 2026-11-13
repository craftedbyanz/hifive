// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appLanguageTitle => 'App language';

  @override
  String get appLanguageSystem => 'Same as device';

  @override
  String get appLanguageHint =>
      'Applies to the app\'s text. Lesson content stays the same.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get loading => 'Loading...';

  @override
  String get loadFailedTitle => 'Couldn\'t load this';

  @override
  String get loadFailedSubtitle => 'Check your connection and try again.';

  @override
  String get retry => 'Try again';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get emptySubtitle => 'Try another category or refresh.';

  @override
  String get leave => 'Leave';

  @override
  String get stay => 'Stay';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get exitGame => 'Exit game';

  @override
  String get vietnamFlag => 'Flag of Vietnam';

  @override
  String get greetingNight => 'Good night,';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get homeWhatToLearn => 'Not sure what to learn today?';

  @override
  String get homeAiLesson => 'Create a lesson with AI';

  @override
  String get homeModesTitle => 'Study modes';

  @override
  String get homeModesSubtitle =>
      'Improve your writing, grammar and conversation with AI.';

  @override
  String get homeSuggestTitle => 'Picked by Hifive';

  @override
  String get homeSuggestSubtitle =>
      'Hand-picked topics to help you learn faster.';

  @override
  String get topicSurprise => 'Surprise me';

  @override
  String get topicTravel => 'Travel';

  @override
  String get topicBusiness => 'Business';

  @override
  String get topicFood => 'Food';

  @override
  String get topicShopping => 'Shopping';

  @override
  String get topicHealth => 'Health';

  @override
  String get topicSocial => 'Social';

  @override
  String get topicLife => 'Daily life';

  @override
  String get topicEntertainment => 'Entertainment';

  @override
  String get home101Body =>
      'Everything you need to know about Hifive and how it helps you learn well.';

  @override
  String get openFlashcards => 'Open flashcards';

  @override
  String get flashPromoTitle => 'VOCABULARY\nFLASHCARDS';

  @override
  String get flashPromoBody =>
      'Save new words, review with\nspaced repetition and track\nyour progress every day.';

  @override
  String get sampleResilientMeaning => 'Tough';

  @override
  String get sampleAcquireMeaning => 'To gain';

  @override
  String get tryNow => 'Try now';

  @override
  String get flowTagline => 'Arrange letters into words';

  @override
  String get modeGrammarBlurb => 'Fix mistakes fast in short sentences.';

  @override
  String get modeWritingBlurb =>
      'Practise translating and\nwriting paragraphs.';

  @override
  String get modeChatBlurb => 'Role-play a wide range\nof situations.';

  @override
  String get explore => 'EXPLORE';

  @override
  String get modeWritingTitle => 'Paragraphs';

  @override
  String get modeGrammarTitle => 'Sentence fixes';

  @override
  String get modeChatTitle => 'Conversation';

  @override
  String get modeWritingCategory => 'WRITING';

  @override
  String get modeGrammarCategory => 'GRAMMAR';

  @override
  String get modeChatCategory => 'SPEAKING';

  @override
  String get modeWritingHeadline => 'Write your';

  @override
  String get modeGrammarHeadline => 'Perfect your';

  @override
  String get modeChatHeadline => 'Practise';

  @override
  String get modeWritingAccent => 'story';

  @override
  String get modeGrammarAccent => 'grammar';

  @override
  String get modeChatAccent => 'conversation';

  @override
  String get modeWritingAction => 'Start';

  @override
  String get modeGrammarAction => 'Quick fix';

  @override
  String get modeChatAction => 'Start chatting';

  @override
  String get menuInsight => 'Insights';

  @override
  String get menuPlus => 'Upgrade to Hifive Plus';

  @override
  String get menuFlashcards => 'Study flashcards';

  @override
  String get menuStreak => 'My streak';

  @override
  String get menuGame => 'Play FlowLetter';

  @override
  String get streakLabel => 'Streak:';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get menu => 'Menu';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileStudying => 'Studying';

  @override
  String get profileGeneral => 'General';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileLessonSettings => 'Lesson settings';

  @override
  String get profileVoice => 'Voice';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileSubscription => 'Subscription';

  @override
  String get profileRedeem => 'Redeem a code';

  @override
  String get profileInvite => 'Invite friends';

  @override
  String get profileRate => 'Rate the app';

  @override
  String get profileOther => 'More';

  @override
  String get profileFeedback => 'Send feedback';

  @override
  String get profileTerms => 'Terms of service';

  @override
  String get profilePrivacy => 'Privacy policy';

  @override
  String get notSignedIn => 'You\'re not signed in.';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutSynced =>
      'Your progress is saved to your account and will be removed from this device.';

  @override
  String get signOutLocal => 'Your progress stays on this device.';

  @override
  String get signOut => 'Sign out';

  @override
  String get cancel => 'Cancel';

  @override
  String get syncUnfinishedTitle => 'Not fully synced';

  @override
  String get syncUnfinishedBody =>
      'Some changes aren\'t saved to your account yet and will be lost. Sign out anyway?';

  @override
  String get signOutAnyway => 'Sign out anyway';

  @override
  String get cannotOpenHere => 'This device can\'t open that yet.';

  @override
  String get planFree => 'Free';

  @override
  String get trialLine1 => 'Upgrade for higher limits';

  @override
  String get trialLine2 => 'Get new features early';

  @override
  String get trialLine3 => 'Unlock the full power of AI';

  @override
  String get trialTitle => 'Try Hifive Plus';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get footerMotto => 'Learn a little every day';

  @override
  String get footerCredit => 'Developed and designed by Anz in Vietnam';

  @override
  String get redeemOffer => 'Redeem Offer';

  @override
  String get redeemCodeHint => 'Code';

  @override
  String get redeemLocalNote =>
      'This build doesn\'t connect to the App Store or redeem codes.';

  @override
  String get continueAction => 'Continue';

  @override
  String get optionalHint => 'Optional';

  @override
  String get send => 'Send';

  @override
  String get reviewLocalNote =>
      'This build doesn\'t send your review anywhere.';

  @override
  String get writeReview => 'Write a Review';

  @override
  String get appCategoryEducation => 'Education';

  @override
  String get tapToRate => 'Tap to Rate:';

  @override
  String get reviewTitleField => 'Title';

  @override
  String get reviewBodyField => 'Review';

  @override
  String get addNickname => 'Add Nickname';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get displayName => 'Display name';

  @override
  String get emailAddress => 'Email address';

  @override
  String get noEmail => 'This account has no email';

  @override
  String get signedInWith => 'Signed in with';

  @override
  String get notSignedInShort => 'Not signed in';

  @override
  String get connected => 'Connected';

  @override
  String get syncLabel => 'Sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAccountLater =>
      'Account deletion is coming in the official release.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody => 'Permanently delete all your data';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncFailed => 'Couldn\'t sync';

  @override
  String get neverSynced => 'Not synced yet';

  @override
  String syncedAtTime(String time) {
    return 'Synced at $time';
  }

  @override
  String syncedOnDate(String date) {
    return 'Synced $date';
  }

  @override
  String get countryUS => 'United States';

  @override
  String get countryUK => 'United Kingdom';

  @override
  String get countryAU => 'Australia';

  @override
  String get voiceHowTo => 'How to set up voices';

  @override
  String get voiceEngineBody =>
      'Hifive uses Apple\'s neural audio to make listening sound as natural and lively as possible.';

  @override
  String get voiceModels => 'Voice models';

  @override
  String get voiceNormal => 'Normal';

  @override
  String get voiceStep1Title => 'Open Settings';

  @override
  String get voiceStep1Body =>
      'Open the Settings app from your iPhone\'s Home Screen.';

  @override
  String get voiceStep2Title => 'Go to Accessibility';

  @override
  String get voiceStep2Body =>
      'Find and tap Accessibility in the\nlist of settings.';

  @override
  String get voiceStep3Title => 'Open Spoken Content';

  @override
  String get voiceStep3Body => 'Choose Read & Speak, then Voices.';

  @override
  String get voiceStep4Title => 'Download a Premium or Enhanced voice';

  @override
  String get voiceStep4Body =>
      'Choose English, pick a voice (such as Ava or Tom), then download its Premium or Enhanced version.';

  @override
  String get voiceHelpIntro =>
      'For the best listening experience, download Apple\'s high-quality neural voices on your iPhone.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get styleRegular => 'Regular';

  @override
  String get styleMono => 'Mono';

  @override
  String get styleMinimal => 'Minimal';

  @override
  String get styleGlass => 'Glass';

  @override
  String get cardOrder => 'Card order';

  @override
  String get reset => 'Reset';

  @override
  String reorderItem(String name) {
    return 'Reorder $name';
  }

  @override
  String get previewWritingTag => 'TRANSLATION';

  @override
  String get previewWritingTitle => 'Paragraph';

  @override
  String get previewWritingName => 'Translation';

  @override
  String get previewWritingBlurb => 'Master sentence structure and flow.';

  @override
  String get previewGrammarTag => 'GRAMMAR';

  @override
  String get previewGrammarTitle => 'Quick Fix';

  @override
  String get previewGrammarName => 'Grammar';

  @override
  String get previewGrammarBlurb => 'Fix common mistakes instantly.';

  @override
  String get previewChatTag => 'DIALOGUE';

  @override
  String get previewChatTitle => 'Speaking';

  @override
  String get previewChatName => 'Dialogue';

  @override
  String get previewChatBlurb => 'Simulate real-life chats.';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get notEnabledInSettings => 'Not turned on in Settings';

  @override
  String get cannotOpenSettings => 'Couldn\'t open Settings.';

  @override
  String get settingsAction => 'Settings';

  @override
  String get smartReminders => 'Smart reminders';

  @override
  String get smartRemindersBody =>
      'hifive works out which words are fading. At your reminder time you only hear from us if words are due, with how many and about how long it takes.';

  @override
  String get lessonSettingsTitle => 'Lesson settings';

  @override
  String get inputColor => 'Input colour';

  @override
  String get hintSettings => 'Hints';

  @override
  String get alwaysShowHints => 'Always show hints';

  @override
  String get showHintsWithoutTap => 'Show hint words without\ntapping';

  @override
  String get typeTranslation => 'Type your translation...';

  @override
  String get chooseLevel => 'Choose your level';

  @override
  String get confirm => 'Confirm';

  @override
  String get cefrBody =>
      'The Common European Framework of Reference (CEFR) has 6 levels, from beginner to proficient.';

  @override
  String get levelAiNote =>
      'AI writes lessons for your level, so pick the one that fits best.';

  @override
  String get yourLevel => 'Your level';

  @override
  String get noCourses => 'No courses yet';

  @override
  String get comeBackLater => 'Please check back later.';

  @override
  String get studyLanguage => 'Study language';

  @override
  String get chooseStudyLanguage => 'Choose a language to learn';

  @override
  String get studyLanguageBody =>
      'Hifive supports up to 4 languages and will add more.';

  @override
  String get languagesSection => 'Languages';

  @override
  String get currentLevel => 'CURRENT LEVEL';

  @override
  String get languageSoonTag => 'Coming soon';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String introPage(int index, int count) {
    return 'Intro $index of $count';
  }

  @override
  String get agreePrefix => 'By continuing, you agree to the ';

  @override
  String get agreeTerms => 'Terms';

  @override
  String get agreeAnd => ' and ';

  @override
  String get agreeSuffix => '.';

  @override
  String get cannotOpenTerms => 'Couldn\'t open the terms of service.';

  @override
  String get loadingYourData => 'Loading your data';

  @override
  String get loadingYourDataDetail =>
      'Bringing your progress from your account to this device.';

  @override
  String get signingIn => 'Signing in';

  @override
  String get authWrongCredentials => 'Wrong email or password.';

  @override
  String get authEmailInUse =>
      'This email already has an account. Please sign in.';

  @override
  String get authWeakPassword => 'Your password needs at least 6 characters.';

  @override
  String get authInvalidEmail => 'That email isn\'t valid.';

  @override
  String get authTooManyRequests => 'Too many tries. Please wait a moment.';

  @override
  String get authNetwork => 'No internet connection. Please try again.';

  @override
  String get authUnavailable => 'This sign-in method isn\'t turned on yet.';

  @override
  String get authUnknown => 'Couldn\'t sign in. Please try again.';

  @override
  String get resetNeedsEmail =>
      'Enter your email to get a password reset link.';

  @override
  String get resetSent => 'Password reset email sent.';

  @override
  String get createAccountTitle => 'Create your Hifive account';

  @override
  String get emailSignInTitle => 'Sign in with email';

  @override
  String get emailSignInBody =>
      'Save your progress and keep learning on any device.';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get working => 'Working...';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get haveAccountSignIn => 'Have an account? Sign in';

  @override
  String get createNewAccount => 'Create a new account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get sceneWritingTitle => 'Write a lot,\nfix every line';

  @override
  String get sceneWritingBody =>
      'Write in the language you\'re learning and get feedback on every sentence.';

  @override
  String get sceneChatTitle => 'Chat without\nfear of mistakes';

  @override
  String get sceneChatBody =>
      'Practise real situations, with gentle notes on your mistakes.';

  @override
  String get sceneWordsTitle => 'Remember new\nwords longer';

  @override
  String get sceneWordsBody =>
      'Your cards remind you to review right before you\'d forget.';

  @override
  String get demoSourceLanguage => 'VIETNAMESE';

  @override
  String get demoSourceSentence => 'Cuối tuần này mình đi biển nhé!';

  @override
  String get demoYouWrote => 'YOU WROTE';

  @override
  String get demoNatural => 'Natural · 96';

  @override
  String get demoPastTense => 'Past tense: go → went';

  @override
  String get demoRememberMeaning => 'to keep in mind';

  @override
  String get rateHard => 'Hard';

  @override
  String get rateOkay => 'Okay';

  @override
  String get rateEasy => 'Easy';

  @override
  String reviewInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review in $count days',
      one: 'Review in 1 day',
    );
    return '$_temp0';
  }

  @override
  String preparingSavingProfile(String name) {
    return 'Saving $name\'s profile';
  }

  @override
  String preparingChoosingLessons(String level) {
    return 'Choosing $level lessons';
  }

  @override
  String get preparingSorting => 'Arranging them around your goals';

  @override
  String get preparingDetail => 'Just a moment more.';

  @override
  String get finish => 'Finish';

  @override
  String get continueStep => 'Continue';

  @override
  String stepOf(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get nameStepTitle => 'Hi there!';

  @override
  String get nameStepAccent => 'What\'s your name?';

  @override
  String get nameStepBody =>
      'Hifive will call you by this name. You can change it in your profile.';

  @override
  String get yourName => 'Your name';

  @override
  String get levelLineA1 => 'You know a few words and greetings.';

  @override
  String get levelLineA2 => 'You can write simple sentences about yourself.';

  @override
  String get levelLineB1 =>
      'You can write short paragraphs on familiar topics.';

  @override
  String get levelLineB2 =>
      'You give your views fairly naturally, with reasons.';

  @override
  String get levelLineC1 => 'You write clearly for study and work.';

  @override
  String get levelLineC2 => 'Close to a native speaker.';

  @override
  String get levelStepTitle => 'What\'s your';

  @override
  String get levelStepAccent => 'current level?';

  @override
  String get levelStepBody =>
      'Lessons start at this level. Not sure? Pick one step lower.';

  @override
  String get goalDaily => 'Everyday talk';

  @override
  String get goalDailyBody => 'Chat day to day';

  @override
  String get goalTravel => 'Travel';

  @override
  String get goalTravelBody => 'Directions, ordering food';

  @override
  String get goalWork => 'Work';

  @override
  String get goalWorkBody => 'Email, meetings, presentations';

  @override
  String get goalExam => 'Exams';

  @override
  String get goalExamBody => 'IELTS, TOEIC, TOEFL';

  @override
  String get goalStudy => 'Study abroad';

  @override
  String get goalStudyBody => 'Lectures, essays';

  @override
  String get goalWriting => 'Write better';

  @override
  String get goalWritingBody => 'Clear sentences, fewer mistakes';

  @override
  String get goalMedia => 'Films and music';

  @override
  String get goalMediaBody => 'Understand without subtitles';

  @override
  String get goalFamily => 'With family';

  @override
  String get goalFamilyBody => 'Learn with your kids and family';

  @override
  String get goalStepTitle => 'Why are you';

  @override
  String get goalStepAccent => 'learning?';

  @override
  String goalPickUpTo(int max) {
    return 'Pick up to $max goals.';
  }

  @override
  String goalPicked(int count, int max) {
    return '$count of $max goals picked.';
  }

  @override
  String get welcomeStepTitle => 'Welcome';

  @override
  String get welcomeStepAccent => 'to Hifive';

  @override
  String get welcomeStepBody =>
      'Learn a language by writing, speaking and reviewing words every day. Four ways to practise help you improve naturally, bit by bit.';

  @override
  String get practiceWriting => 'Write paragraphs';

  @override
  String get practiceWritingBody =>
      'Translate and rewrite each sentence on topics you like.';

  @override
  String get practiceGrammar => 'Fix sentences';

  @override
  String get practiceGrammarBody =>
      'Short sentences, quick fixes, and why they were wrong.';

  @override
  String get practiceChat => 'Conversation';

  @override
  String get practiceChatBody => 'Role-play real situations.';

  @override
  String get practiceCards => 'Word cards';

  @override
  String get practiceCardsBody =>
      'Save new words and review right before you\'d forget.';

  @override
  String get tapForNextWay => 'Tap to see the next way to learn';

  @override
  String get cardsStepTitle => 'Save new words anytime,';

  @override
  String get cardsStepAccent => 'review right before you forget';

  @override
  String get cardsStepBody =>
      'Save words as you learn and review them with cards. Tap a card to flip it, then tell Hifive whether you remembered.';

  @override
  String get posAdjective => 'ADJECTIVE';

  @override
  String get posNoun => 'NOUN';

  @override
  String get posVerb => 'VERB';

  @override
  String get meaningCurious => 'eager to know';

  @override
  String get meaningJourney => 'a trip';

  @override
  String get meaningImprove => 'to get better';

  @override
  String get meaningBrave => 'showing courage';

  @override
  String get reviewTomorrow => 'Review tomorrow';

  @override
  String get tapToFlip => 'Tap to flip';

  @override
  String get tapToFlipCaps => 'TAP TO FLIP';

  @override
  String listenTo(String word) {
    return 'Listen to \"$word\"';
  }

  @override
  String get notRemembered => 'Not yet';

  @override
  String get remembered => 'Got it';

  @override
  String get demoWriteTitle => 'Write a sentence,';

  @override
  String get demoWriteAccent => 'get feedback at once';

  @override
  String get demoWriteBody =>
      'Hifive scores every sentence you write and shows a more natural way to say it. Try scoring the sentence below.';

  @override
  String get demoTranslateToEnglish => 'TRANSLATE INTO ENGLISH';

  @override
  String get demoWriteSource => 'Tôi đã sống ở Đà Nẵng ba năm.';

  @override
  String get scoreIt => 'Check';

  @override
  String get scored => 'Checked';

  @override
  String get scoring => 'Checking';

  @override
  String get scoringEllipsis => 'Checking...';

  @override
  String get almostRight => 'Almost right';

  @override
  String get correctSentenceCaps => 'CORRECT SENTENCE';

  @override
  String get explanationCaps => 'EXPLANATION';

  @override
  String get demoWriteExplanation =>
      'It started in the past and is still going on, so use the present perfect.';

  @override
  String get demoGrammarTitle => 'Fix grammar';

  @override
  String get demoGrammarAccent => 'sentence by sentence';

  @override
  String get demoGrammarBody =>
      'Short sentences with clear explanations, so old mistakes don\'t come back. Pick the right word for the blank.';

  @override
  String get fillTheBlankCaps => 'FILL IN THE BLANK';

  @override
  String get correctExclaim => 'Correct!';

  @override
  String get notQuiteTryAgain => 'Not quite, try again';

  @override
  String get demoGrammarRule =>
      'With a singular subject (she) in the present simple, the verb takes -s or -es.';

  @override
  String get demoGrammarHint =>
      'Hint: \"every day\" is a habit, and the subject is \"she\".';

  @override
  String get demoChatPolite =>
      'More polite: \"Could I have a coffee, please?\"';

  @override
  String get demoChatTitle => 'Practise speaking';

  @override
  String get demoChatAccent => 'like real life';

  @override
  String get demoChatBody =>
      'Practise with real situations. Pick a sentence to reply.';

  @override
  String get hint => 'Hint';

  @override
  String get noDecks => 'No decks yet';

  @override
  String get noDecksBody => 'Add your first vocabulary deck.';

  @override
  String get addDeck => 'Add deck';

  @override
  String addedSampleWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count sample words',
      one: 'Added 1 sample word',
    );
    return '$_temp0';
  }

  @override
  String get sampleDeckDescription => 'Your sample vocabulary deck';

  @override
  String get cardsFailed => 'Couldn\'t create cards. Please try again.';

  @override
  String get addCards => 'Add Cards';

  @override
  String get newDeck => 'New Deck';

  @override
  String get topicNameCaps => 'TOPIC NAME';

  @override
  String get topicNameHint => 'Space, Cooking, Travel...';

  @override
  String get wordsUnit => 'words';

  @override
  String get wordsToGenerateCaps => 'WORDS TO GENERATE';

  @override
  String slotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slots left',
      one: '1 slot left',
    );
    return '$_temp0';
  }

  @override
  String get generateDeck => 'Generate Deck';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortAZ => 'A-Z';

  @override
  String get filterAll => 'All';

  @override
  String get filters => 'Filters';

  @override
  String get filterNotStudied => 'Not studied';

  @override
  String get filterLearning => 'Learning';

  @override
  String get filterMastered => 'Mastered';

  @override
  String get restartDeck => 'Start over';

  @override
  String get restartDeckTitle => 'Start over?';

  @override
  String get restartDeckBody => 'Reset the review schedule of this deck?';

  @override
  String get resetAction => 'Reset';

  @override
  String get deckOptions => 'Deck options';

  @override
  String get reviewAll => 'Review all';

  @override
  String reviewDue(int count) {
    return 'Review ($count)';
  }

  @override
  String get doneForToday => 'You\'re done for today!';

  @override
  String get searchCards => 'Search cards';

  @override
  String get searchWordsHint => 'Search words...';

  @override
  String get cancelEn => 'Cancel';

  @override
  String get statNew => 'New';

  @override
  String get statLearning => 'Learning';

  @override
  String get statReview => 'Review';

  @override
  String get deckProgress => 'Deck progress';

  @override
  String cardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String get pillNew => 'NEW';

  @override
  String get pillLearning => 'LEARNING';

  @override
  String get pillReview => 'REVIEW';

  @override
  String pronounceWord(String word) {
    return 'Pronounce $word';
  }

  @override
  String get pronounce => 'Pronounce';

  @override
  String get example => 'Example';

  @override
  String get excellent => 'Excellent!';

  @override
  String get masteredMost => 'You\'ve mastered most of the cards!';

  @override
  String get seen => 'Seen';

  @override
  String get known => 'Known';

  @override
  String get relearn => 'Relearn';

  @override
  String get rateAgain => 'Again';

  @override
  String get rateHardCard => 'Hard';

  @override
  String get rateGood => 'Good';

  @override
  String get rateEasyCard => 'Easy';

  @override
  String get closeReview => 'Close review';

  @override
  String get reviewOptions => 'Review options';

  @override
  String get guideForgot => 'Forgot it';

  @override
  String get guideForgotBody =>
      'Swipe left and Hifive brings it back right away';

  @override
  String get guideHard => 'A bit hard';

  @override
  String get guideHardBody => 'Swipe down if the word still feels unfamiliar';

  @override
  String get guideKnown => 'Got it';

  @override
  String get guideKnownBody =>
      'Swipe up when you got the meaning and the sound right';

  @override
  String get guideEasy => 'Too easy';

  @override
  String get guideEasyBody => 'Swipe right to see this word less often';

  @override
  String get smartLearning => 'How smart review works';

  @override
  String get swipeToRate => 'Swipe a card to say how well you remember it';

  @override
  String get gotItStart => 'Got it, let\'s start';

  @override
  String get autoPlay => 'Autoplay';

  @override
  String get cardColor => 'Card colour';

  @override
  String get guide => 'Guide';

  @override
  String get colorful => 'Colourful';

  @override
  String get monochrome => 'Monochrome';

  @override
  String get gameHowToTitle => 'How to play Flow Letter';

  @override
  String get gameGoal => 'Goal';

  @override
  String get gameGoalBody => 'Arrange the letters into the right word.';

  @override
  String get gameMove => 'How to move';

  @override
  String get gameMoveBody => 'Hold and drag a letter to swap places.';

  @override
  String get gameDone => 'Finish';

  @override
  String get gameDoneBody =>
      'A correct word moves on to the next one by itself.';

  @override
  String get tapToSee => 'Tap to see';

  @override
  String get chooseDeck => 'Choose a deck';

  @override
  String wordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get flowGuideLabel => 'Flow Letter guide';

  @override
  String get rotateForBetter => 'Better with your phone turned sideways';

  @override
  String get levelOne => 'Level 1';

  @override
  String bestScore(int score) {
    return 'Best $score';
  }

  @override
  String totalXp(int xp) {
    return 'Total XP: $xp';
  }

  @override
  String get comboZero => 'Combo x0';

  @override
  String gamesPlayed(int count) {
    return 'Games played: $count';
  }

  @override
  String get startFirstSession => 'Start your first session';

  @override
  String continueTitle(String title) {
    return 'Continue $title';
  }

  @override
  String get play => 'Play';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get rotate => 'Rotate';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get sound => 'Sound';

  @override
  String get hapticFeedback => 'Haptic feedback';

  @override
  String get resumeLater => 'You can pick up again from the Flow Letter page.';

  @override
  String get progressLost => 'Your current progress will be lost.';

  @override
  String get exitGameTitle => 'Exit the game?';

  @override
  String levelCaps(int level) {
    return 'LEVEL $level';
  }

  @override
  String get swipeToSeeLetters => '← Swipe sideways to see the letters →';

  @override
  String get arrangeLetters => 'Arrange the letters';

  @override
  String firstLetter(String letter) {
    return 'First letter: $letter';
  }

  @override
  String get skip => 'Skip';

  @override
  String get completed => 'Complete!';

  @override
  String get points => 'Points';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get combo => 'Combo';

  @override
  String get hintStat => 'Hints';

  @override
  String levelNumber(int level) {
    return 'Level $level';
  }

  @override
  String get backHome => 'Back to Home';

  @override
  String get daysCaps => 'DAYS';

  @override
  String monthSummary(int count, String month, int yearCount) {
    return 'You finished $count sessions in $month, and $yearCount this year.';
  }

  @override
  String get mistakesPrefix => 'You made';

  @override
  String mistakesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grammar mistakes',
      one: '1 grammar mistake',
    );
    return '$_temp0';
  }

  @override
  String get mistakesMiddle => 'this month, mostly about';

  @override
  String get mistakesTopic => 'vocabulary';

  @override
  String get seeSuggestions => 'See tips to improve';

  @override
  String get suggestionsTitle => 'Tips to improve';

  @override
  String get madeByAi => 'Made by AI';

  @override
  String get madeByAiBody =>
      'These stats and tips are put together by AI from your sessions this month. They may not be fully accurate, so treat them as advice.';

  @override
  String get weekdaysMonFirst => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get weekdaysSunFirst => 'S,M,T,W,T,F,S';

  @override
  String get thisWeekActivity => 'This week\'s activity';

  @override
  String get withHifive => 'With Hifive';

  @override
  String get withPrefix => 'You\'ve been with';

  @override
  String get withMiddle => 'for';

  @override
  String withDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days. ',
      one: '1 day. ',
    );
    return '$_temp0';
  }

  @override
  String get thanksForJourney => 'Thanks for coming along!';

  @override
  String monthYearShort(int month, int year) {
    return '$month/$year';
  }

  @override
  String get currentStreak => 'Current streak';

  @override
  String updatedToday(String time) {
    return 'Updated at $time today';
  }

  @override
  String get unitWords => 'WORDS';

  @override
  String get vocabularyLearned => 'Words learned';

  @override
  String get unitHours => 'HRS';

  @override
  String get studyTime => 'Study time';

  @override
  String get unitSessions => 'SESSIONS';

  @override
  String get sessionsDone => 'Sessions done';

  @override
  String get unitSentences => 'SENTENCES';

  @override
  String get sentencesPractised => 'Sentences practised';

  @override
  String get unitParagraphs => 'PARAS';

  @override
  String get noMistakesMonth => 'No grammar mistakes this month. Great work!';

  @override
  String get makingSuggestions => 'Making tips...';

  @override
  String get suggestionsFailed => 'Couldn\'t make tips';

  @override
  String get aiServiceDown =>
      'The AI service is having trouble. Please try again.';

  @override
  String get streakTitle => 'Streak';

  @override
  String get onFire => 'ON FIRE';

  @override
  String get daysInARow => 'days in a row';

  @override
  String get startStreakToday => 'Start your streak today!';

  @override
  String get keepHabit => 'Keep up this great habit!';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String studiedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Studied $count days',
      one: 'Studied 1 day',
    );
    return '$_temp0';
  }

  @override
  String get currentCaps => 'CURRENT';

  @override
  String get longestCaps => 'LONGEST';

  @override
  String get sectionParagraph => 'Paragraphs';

  @override
  String get sectionSentence => 'Sentences';

  @override
  String get sectionChat => 'Conversations';

  @override
  String get clearAll => 'Clear all';

  @override
  String get clearHistoryTitle => 'Clear history?';

  @override
  String get clearHistoryBody =>
      'This only clears results in this app and can\'t be undone.';

  @override
  String get newPractice => 'New practice';

  @override
  String get noReviewsYet => 'No results yet';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get finishLessonToSave => 'Finish a lesson to save your progress.';

  @override
  String get tryAnotherKeyword => 'Try another keyword.';

  @override
  String get reviewSection => 'Review';

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get historyOptions => 'History options';

  @override
  String get searchHistoryHint => 'Search titles and descriptions...';

  @override
  String get closeSearch => 'Close search';

  @override
  String get newPracticeLabel => 'Start a new practice';

  @override
  String get seeMore => 'See more';

  @override
  String get helpTitle1 => 'The 3 Main Practice Modes';

  @override
  String get helpTitle2 => 'AI Assistant & Feedback';

  @override
  String get helpTitle3 => 'AI Magic Generator';

  @override
  String get helpTitle4 => 'Flashcards & Spaced Repetition';

  @override
  String get helpTitle5 => 'Progress Tracking';

  @override
  String get helpTitle6 => 'Smart Review';

  @override
  String get helpTitle7 => 'Mini Game: Flow Letter';

  @override
  String get helpBody1 =>
      'The app offers 3 separate ways to practise, to build every skill:\n\n• Paragraph: Focuses on writing and translating longer texts. You write a paragraph from a prompt, then AI scores it and makes the style sound natural.\n\n• Sentence: Tackles grammar and structure mistakes in single sentences. Good for a quick review of basic grammar rules.\n\n• Conversation: Builds your speaking reflexes. Includes \'Scripted\' mode (set situations such as travel or interviews) and \'Free\' mode (open chat with AI).';

  @override
  String get helpBody2 =>
      'After every exercise, AI gives a detailed breakdown so you understand your mistakes:\n\n1. Spotting mistakes: Red marks grammar or vocabulary errors to fix.\n2. Better phrasing: Green shows more natural or more accurate ways to say it in context.\n3. Detailed explanations: Tap a marked mistake or suggestion to see the language rule behind it, or why the suggestion works better.';

  @override
  String get helpBody3 =>
      'AI Magic Generator lets you design your own learning path from real needs instead of fixed lessons:\n\n1. How to use it: Enter any topic or situation (for example \'Job interview\', \'Email complaining about a service\', \'Shopping conversation\').\n2. Customise: Choose a difficulty from Basic to Advanced so the exercises match your level.\n3. Result: AI reads your request and creates exercises (Writing or Conversation) directly about that topic.';

  @override
  String get helpBody4 =>
      'A built-in system helps you save and review words well with spaced repetition:\n\n1. Collecting words: While practising, tap any word you don\'t know to see its meaning, then tap \'Save\' to add it to your collection.\n2. How review works: The app works out when to remind you about saved words based on how well you remember them (Again, Good, Easy).\n3. Library: Organise word decks by topic so you can focus on specific groups of words.';

  @override
  String get helpBody5 =>
      'Tools that help you see how your learning goes over time:\n\n1. Calendar: Shows each day you studied this month in a clear calendar view.\n2. Streak: Counts the days in a row you practised, to build a daily habit.\n3. Badges: Milestones that recognise your effort when you reach certain learning goals.';

  @override
  String get helpBody6 =>
      'Review keeps your whole learning history so you can strengthen what you\'ve learned:\n\n1. Look back: Open any past exercise at any time, with AI\'s corrections and detailed notes.\n2. Redo: Do a finished exercise again to see how much you\'ve improved since last time.';

  @override
  String get helpBody7 =>
      'An extra way to learn through a puzzle game:\n\n1. How to play: The letters are shuffled, and your job is to put them back into the word using its meaning or an example.\n2. Works offline: It\'s the only feature in the app you can use without an internet connection.\n3. Limits: For now it\'s designed only for English as the language you\'re learning.';

  @override
  String get privacyAiCoach => 'AI Coach';

  @override
  String get privacyAiCoachBody =>
      'Hifive syncs your learning data to a private database so you can reach it from anywhere. When you use the AI Coach, requests are handled securely to give suggestions, and this data is never shared or kept for any other purpose.';

  @override
  String get privacyCollectTitle => '1. Information we collect';

  @override
  String get privacyCollectBody =>
      'We collect information to provide a better service to everyone. This includes:\n• Personal data: When you sign up, we may collect your name, email address and profile photo.\n• Usage data: We collect how the Service is accessed and used, such as your device type, operating system version and time spent on pages.';

  @override
  String get privacyUseTitle => '2. How we use your information';

  @override
  String get privacyUseBody =>
      'We use the data we collect for several purposes:\n• To provide and maintain our Service\n• To tell you about changes to our Service\n• To let you take part in interactive features when you choose to\n• To provide customer support\n• To gather analysis or useful information so we can improve our Service';

  @override
  String get privacyKeepTitle => '3. Keeping data';

  @override
  String get privacyKeepBody =>
      'Hifive keeps your Personal Data only as long as needed for the purposes in this Privacy Policy. We keep and use your Personal Data as far as needed to meet our legal obligations, resolve disputes and enforce our legal agreements and policies.';

  @override
  String get privacySecurityTitle => '4. Keeping your data safe';

  @override
  String get privacySecurityBody =>
      'Keeping your data safe matters to us, but no method of sending data over the Internet or storing it electronically is 100% secure. While we use commercially acceptable means to protect your Personal Data, we can\'t guarantee its absolute security.';

  @override
  String get privacyChildrenTitle => '5. Children\'s privacy';

  @override
  String get privacyChildrenBody =>
      'Our Service is not meant for anyone under 13. We don\'t knowingly collect personally identifiable information from anyone under 13. If you are a parent or guardian and know that your child has given us Personal Data, please contact us.';

  @override
  String get privacyHeadline1 => 'We understand what you need,';

  @override
  String get privacyHeadline2 => 'not who you are';

  @override
  String get privacyUpdated => 'Last updated: 7 January 2026';

  @override
  String get privacyIntro =>
      'Your privacy comes first. Our business runs on your support (subscriptions), not your data. Your information is stored safely in our encrypted database. We never share your personal data or what you use with AI with any third party, and we don\'t use it to train public AI models.';

  @override
  String get contactUs => 'Contact us';

  @override
  String get alwaysListening => 'We\'re always happy to hear from you.';

  @override
  String get noSupportEmailLocal => 'This build has no support email.';

  @override
  String get supportEmail => 'Support email';

  @override
  String get notInLocalBuild => 'Not in this build';

  @override
  String get done => 'Done';

  @override
  String get plusNoTransaction =>
      'This build has no purchases or subscriptions.';

  @override
  String get plusYearlyNote =>
      'Free for 7 days, then renews automatically at 349,000₫ a year. Cancel anytime.';

  @override
  String get plusMonthlyNote =>
      'Free for 3 days, then renews automatically at 49,000₫ a month. Cancel anytime.';

  @override
  String get plusTitle => 'Upgrade to Hifive+';

  @override
  String get plusYearlyCta => 'Try 7 days • then 349,000₫/year';

  @override
  String get plusMonthlyCta => 'Try 3 days • then 49,000₫/month';

  @override
  String get planYearly => 'Yearly';

  @override
  String get planYearlyPerMonth => '₫29,083 / month';

  @override
  String get perYear => ' / year';

  @override
  String get planYearlyTrial => '7 days free, then\n349,000₫';

  @override
  String get save40 => 'Save 40%';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planMonthlyPerMonth => '₫49,000 / month';

  @override
  String get perMonth => ' / month';

  @override
  String get planMonthlyTrial => '3 days free, then 49,000₫';

  @override
  String get priceYearly => '349,000₫';

  @override
  String get priceMonthly => '49,000₫';

  @override
  String get plusPerksTitle => 'Hifive Plus perks';

  @override
  String get plusPerksBody =>
      'Unlock every premium feature to learn languages better, faster and with more fun.';

  @override
  String get plusRenewalNote =>
      'After buying, you can manage and turn off auto-renewal in your iTunes & App Store account settings.';

  @override
  String get cannotOpenTermsPage => 'Couldn\'t open the terms page.';

  @override
  String get privacyShort => 'Privacy';

  @override
  String get restore => 'Restore';

  @override
  String get perkLimitsTitle => 'Higher limits';

  @override
  String get perkLimitsBody =>
      'More AI use every day than the Free plan. Learn words, grammar and conversation your own way.';

  @override
  String get perkDecksTitle => 'Bigger flashcard library';

  @override
  String get perkDecksBody =>
      'Create and manage huge word decks. Study smart with flashcards tailored to your progress.';

  @override
  String get perkChatTitle => 'More AI chat';

  @override
  String get perkChatBody =>
      'Practise real conversations with higher limits, and get detailed feedback to improve quickly.';

  @override
  String get perkInfiniteTitle => 'Infinite mode';

  @override
  String get perkInfiniteBody =>
      'Get the advanced sentence mode with rising difficulty. Challenge yourself and chase the top score.';

  @override
  String get perkEarlyTitle => 'Early access to features';

  @override
  String get perkEarlyBody =>
      'Try the newest features first, plus exclusive content.';

  @override
  String get perkLanguagesTitle => 'Every language';

  @override
  String get perkLanguagesBody =>
      'Unlock every supported language. Learn any language you like with one account.';

  @override
  String get comingSoonLower => 'coming soon';

  @override
  String get heroSlide1Top => 'hifive';

  @override
  String get heroSlide1Bottom => 'plus';

  @override
  String get heroSlide1Body =>
      'Unlock every premium AI feature with higher limits.';

  @override
  String get heroSlide2Top => 'higher';

  @override
  String get heroSlide2Bottom => 'limits';

  @override
  String get heroSlide2Body =>
      'More AI use than the Free plan. Make flashcards and learn any topic.';

  @override
  String get heroSlide3Top => 'master';

  @override
  String get heroSlide3Bottom => 'a language';

  @override
  String get heroSlide3Body =>
      'Fix grammar and translate instantly with AI, so you can speak with confidence anytime.';

  @override
  String get more => 'More';

  @override
  String get accuracyLabel => 'Accuracy';

  @override
  String get timeLabel => 'Time';

  @override
  String get correctAnswers => 'Correct';

  @override
  String get originalTextCaps => 'ORIGINAL TEXT';

  @override
  String get yourAnswerCaps => 'YOUR ANSWER';

  @override
  String get redoExercise => 'Redo exercise';

  @override
  String get excellentEn => 'Excellent!';

  @override
  String get keepGoing => 'Keep going!';

  @override
  String get masteredLesson => 'You\'ve mastered this lesson';

  @override
  String get everySessionStep => 'Every session is a step forward.';

  @override
  String get timeEn => 'Time';

  @override
  String get correctEn => 'Correct';

  @override
  String get newStreakStarted => 'New streak started!';

  @override
  String get greatStart => 'A great start. Keep up the daily habit!';

  @override
  String get levelA1Title => 'A1 - Beginner';

  @override
  String get levelA2Title => 'A2 - Elementary';

  @override
  String get levelB1Title => 'B1 - Intermediate';

  @override
  String get levelB2Title => 'B2 - Upper Intermediate';

  @override
  String get levelC1Title => 'C1 - Advanced';

  @override
  String get levelC2Title => 'C2 - Proficient';

  @override
  String get levelA1Body =>
      'Can rewrite and complete very short sentences with familiar words. Good for practising basic patterns and simple ideas.';

  @override
  String get levelA2Body =>
      'Can write and fix simple sentences on familiar topics. Starting to join short ideas into paragraphs with fewer basic grammar mistakes.';

  @override
  String get levelB1Body =>
      'Can write clear paragraphs on familiar topics about experiences, plans and short opinions. Good for practising longer sentences and linking ideas.';

  @override
  String get levelB2Body =>
      'Can write fairly natural, well-structured sentences and paragraphs with more detailed views and arguments. Good for practising paraphrasing and better grammar control.';

  @override
  String get levelC1Body =>
      'Can write clearly and flexibly for study, work and personal purposes, choosing words and structures that fit the context.';

  @override
  String get levelC2Body =>
      'Can write accurately, subtly and naturally, close to a proficient speaker, expressing complex ideas clearly with fine control of nuance.';

  @override
  String get levelInfoTitle => 'About levels';

  @override
  String get changeLevelInSettings => 'You can change your level in Settings';

  @override
  String get currentLabel => 'Current';

  @override
  String get noCategories => 'No categories yet';

  @override
  String get createModeCaps => 'CREATE MODE';

  @override
  String get categoriesCaps => 'CATEGORIES';

  @override
  String get yourTopicsCaps => 'YOUR TOPICS';

  @override
  String get relatedTopicsCaps => 'RELATED TOPICS';

  @override
  String topicsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topics',
      one: '1 topic',
    );
    return '$_temp0';
  }

  @override
  String get noTopics => 'No topics yet';

  @override
  String get noTopicsBody => 'Try another category or create a topic with AI.';

  @override
  String get questionsShort => 'Qs';

  @override
  String get setsShort => 'Sets';

  @override
  String get lessonsTitle => 'Lessons';

  @override
  String get collectionCaps => 'COLLECTION';

  @override
  String get noLessons => 'No lessons yet';

  @override
  String get noLessonsBody => 'This topic has no sets yet.';

  @override
  String get levelCapsLabel => 'LEVEL';

  @override
  String get createScenarioQ => 'Create a situation?';

  @override
  String get topicNotListed => 'Topic not on the list?';

  @override
  String get roleplayAnything => 'Role-play any situation with AI';

  @override
  String get customGrammar => 'Create custom grammar practice';

  @override
  String get createCustom => 'Create custom';

  @override
  String get pronounceTooltip => 'Pronounce';

  @override
  String get saveWord => 'Save word';

  @override
  String savedWord(String word) {
    return 'Saved $word';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get endlessMode => 'Endless mode';

  @override
  String get endlessBody => 'Keep learning without end';

  @override
  String get leaveExerciseTitle => 'Leave the exercise?';

  @override
  String get leaveExerciseBody =>
      'You haven\'t finished. Your progress won\'t be saved if you leave now.';

  @override
  String get aiHint => 'AI hint';

  @override
  String get analysingDraft => 'Looking at your draft...';

  @override
  String get backgroundColor => 'Background';

  @override
  String get lessonDictionary => 'Lesson dictionary';

  @override
  String get doneVi => 'Done';

  @override
  String get hideHints => 'Hide hints';

  @override
  String get showHints => 'Show hints';

  @override
  String get feedbackNoted => 'Thanks, noted for this session';

  @override
  String get leaveExercise => 'Leave exercise';

  @override
  String get lessonOptions => 'Lesson options';

  @override
  String get typeAnswer => 'Type your answer...';

  @override
  String get previousSentence => 'Previous sentence';

  @override
  String get hiddenHint => 'Hidden hint';

  @override
  String get like => 'Like';

  @override
  String get dislike => 'Dislike';

  @override
  String get next => 'Next';

  @override
  String sentencesList(String list) {
    return 'Sentence $list';
  }

  @override
  String saveItem(String word) {
    return 'Save $word';
  }

  @override
  String get excellentShort => 'Excellent';

  @override
  String get fixCaps => 'CORRECTIONS';

  @override
  String get tapWordToLookUp => 'Tap a word to look it up';

  @override
  String get keyImprovementsCaps => 'KEY IMPROVEMENTS';

  @override
  String get tipsCaps => 'TIPS';

  @override
  String get tipKeepMeaning => 'Keep the original meaning and tense.';

  @override
  String get tipSubjectVerb => 'Check the subject and the verb.';

  @override
  String get tipTapReference =>
      'Tap words in the reference sentence to see their meaning.';

  @override
  String get seeAiAnalysisBody => 'See AI\'s detailed analysis of your answer.';

  @override
  String get seeAiAnalysis => 'See AI analysis';

  @override
  String get editEn => 'Edit';

  @override
  String get editVi => 'Edit';

  @override
  String get nextSentence => 'Next sentence';

  @override
  String get nextEn => 'Next';

  @override
  String get nextVi => 'Next';

  @override
  String get helpful => 'Helpful';

  @override
  String get notHelpful => 'Not helpful';

  @override
  String get gradingFailed => 'Couldn\'t check your answer';

  @override
  String get gradingFailedBody =>
      'The connection or the AI service is having trouble.';

  @override
  String get grading => 'Checking...';

  @override
  String get fixCapsStar => '✦  CORRECTIONS';

  @override
  String get gradeCorrect => 'Correct';

  @override
  String get gradeNear => 'Almost';

  @override
  String get gradeIncorrect => 'Not quite';

  @override
  String get leaveChatTitle => 'Leave the conversation?';

  @override
  String get leaveChatBody =>
      'You haven\'t finished the conversation. This session won\'t be saved if you leave now.';

  @override
  String get leaveChat => 'Leave conversation';

  @override
  String get freeChat => 'Free chat';

  @override
  String get scriptMode => 'Scripted mode';

  @override
  String toneLabel(String tone) {
    return 'Tone: $tone';
  }

  @override
  String sayThis(String prompt) {
    return 'Say: $prompt';
  }

  @override
  String get answerFreelyEnglish => 'Answer freely in English';

  @override
  String get sendAction => 'Send';

  @override
  String get listenToLine => 'Listen to this line';

  @override
  String get hideTranslation => 'Hide translation';

  @override
  String get showTranslation => 'Show translation';

  @override
  String hintWith(String answer) {
    return 'Hint: $answer';
  }

  @override
  String get sendFailed => 'Couldn\'t send your reply.';

  @override
  String get customCaps => 'CUSTOM';

  @override
  String get practiceFailed =>
      'Couldn\'t create the practice. Please try again.';

  @override
  String get noSuggestions => 'No suggestions yet';

  @override
  String get describeOwnTopic => 'Describe the topic you\'d like to practise.';

  @override
  String get createOwnTopic => 'Create a topic all your own.';

  @override
  String get createWithAiCaps => 'CREATE WITH AI';

  @override
  String get chooseTopicCaps => 'CHOOSE A TOPIC';

  @override
  String get describeTopicCaps => 'TOPIC DESCRIPTION';

  @override
  String get startPractice => 'Start practising';

  @override
  String get createScenario => 'Create a situation';

  @override
  String get createSentences => 'Create practice sentences';

  @override
  String get customTopicHint =>
      'e.g. \'Phrasal verbs with get\', \'Interview questions\'...';

  @override
  String get startPracticeCaps => 'Start Practising';

  @override
  String get settingsGuideTitle => 'Settings guide';

  @override
  String get settingsGuideBody =>
      'Knowing the settings helps you get the most from conversation practice.';

  @override
  String get learningModeCaps => 'LEARNING MODE';

  @override
  String get freeChatBody =>
      'Open conversation. AI adapts to your answers. Good for advanced practice.';

  @override
  String get scriptModeBody =>
      'Follows a set script. Good for beginners who want clear guidance.';

  @override
  String get tonePersonalityCaps => 'TONE & PERSONALITY';

  @override
  String get toneFormal => 'Formal';

  @override
  String get toneFormalBody =>
      'Professional and polite. Good for work and formal situations.';

  @override
  String get toneCasual => 'Casual';

  @override
  String get toneCasualBody =>
      'Natural, like chatting with friends, with lots of everyday phrases.';

  @override
  String get toneFriendly => 'Friendly';

  @override
  String get toneFriendlyBody =>
      'Gentle, encouraging and patient when you need more time.';

  @override
  String get customizeLesson => 'Customise lesson';

  @override
  String get customizeLessonTitle => 'Customise Lesson';

  @override
  String get customizeLessonBody =>
      'Switch between Free chat and Scripted. Adjust difficulty, tone and the number of questions.';

  @override
  String get closeTip => 'Close tip';

  @override
  String get menuFocus => 'Garden';

  @override
  String get focusStart => 'Start focusing';

  @override
  String get focusChangeTree => 'Change tree';

  @override
  String focusMinutes(int count) {
    return '$count min';
  }

  @override
  String get focusRunningHint =>
      'Put your phone down. Your tree grows while you focus.';

  @override
  String focusCancel(int seconds) {
    return 'Cancel ($seconds)';
  }

  @override
  String get focusGiveUp => 'Give up';

  @override
  String get focusGiveUpTitle => 'Give up this session?';

  @override
  String get focusGiveUpBody =>
      'This session\'s tree will wither and stay in your garden.';

  @override
  String get focusKeepGoing => 'Keep going';

  @override
  String focusDoneTitle(int count) {
    return '$count minutes done';
  }

  @override
  String focusDoneReview(int count) {
    return 'Take 5. Review $count words you\'re about to forget to make it bloom?';
  }

  @override
  String get focusDoneRest => 'Take a 5-minute break, then come back.';

  @override
  String focusReviewWords(int count) {
    return 'Review $count words';
  }

  @override
  String get focusRest => 'Just rest';

  @override
  String get focusBloomed => 'Your tree bloomed';

  @override
  String get focusBreakDeck => 'Break review';

  @override
  String get focusWitheredTitle => 'That\'s okay, try again';

  @override
  String focusWitheredBody(int count) {
    return 'This tree withered after $count min. A new sprout is waiting.';
  }

  @override
  String get focusReplant => 'Plant again';

  @override
  String get focusFinish => 'Done';

  @override
  String get focusPickTree => 'Choose a tree';

  @override
  String get focusLocked => 'Locked';

  @override
  String get focusTagEnglish => 'English';

  @override
  String get focusTagWriting => 'Writing';

  @override
  String get focusTagWork => 'Work';

  @override
  String get focusTagOther => 'Other';

  @override
  String get speciesOak => 'Oak';

  @override
  String get speciesPine => 'Pine';

  @override
  String get speciesSunflower => 'Sunflower';

  @override
  String get speciesTulip => 'Tulip';

  @override
  String get speciesCherry => 'Cherry';

  @override
  String get speciesApple => 'Apple';

  @override
  String get speciesOrange => 'Orange';

  @override
  String get speciesMaple => 'Red maple';

  @override
  String get speciesBirch => 'Birch';

  @override
  String get speciesGinkgo => 'Ginkgo';

  @override
  String get speciesWillow => 'Willow';

  @override
  String get speciesLavender => 'Lavender';

  @override
  String get speciesMushroom => 'Mushroom';

  @override
  String get speciesCactus => 'Cactus';

  @override
  String get speciesBonsai => 'Bonsai';

  @override
  String get speciesBaobab => 'Baobab';

  @override
  String get speciesWisteria => 'Wisteria';

  @override
  String get speciesBamboo => 'Bamboo';

  @override
  String get speciesCoconut => 'Coconut';

  @override
  String get speciesBanana => 'Banana';

  @override
  String get speciesPhuong => 'Flame tree';

  @override
  String get speciesBang => 'Tropical almond';

  @override
  String get speciesMai => 'Yellow apricot';

  @override
  String get speciesDao => 'Peach blossom';

  @override
  String get speciesLotus => 'Lotus';

  @override
  String get speciesBanyan => 'Banyan';

  @override
  String get speciesSnowpine => 'Snow pine';

  @override
  String get speciesGalaxy => 'Galaxy';

  @override
  String get gardenTitle => 'Your garden';

  @override
  String get gardenDay => 'Day';

  @override
  String get gardenWeek => 'Week';

  @override
  String get gardenMonth => 'Month';

  @override
  String get gardenYear => 'Year';

  @override
  String gardenCounts(int trees, int withered) {
    return '$trees trees · $withered withered';
  }

  @override
  String get gardenEmpty =>
      'No trees yet. Focus or review words to plant your first.';

  @override
  String get gardenFocusTime => 'Focused';

  @override
  String get gardenReviews => 'Waterings';

  @override
  String get gardenStudyDays => 'Study days';

  @override
  String gardenHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String gardenGrowing(int count, int total) {
    return 'Study tree growing · $count/$total waterings';
  }

  @override
  String get gardenGrowingHint =>
      'Each new or due card you review waters it. Tap to change the species.';

  @override
  String get gardenCollection => 'Collection';

  @override
  String gardenUnlocked(int count, int total) {
    return '$count of $total species unlocked';
  }

  @override
  String get gardenStartFocus => 'Start focusing';

  @override
  String get unlockAlways => 'Ready';

  @override
  String unlockStudyTrees(int n) {
    return 'Grow $n study trees';
  }

  @override
  String unlockWordsKnown(int n) {
    return 'Know $n words';
  }

  @override
  String unlockStreak(int n) {
    return '$n-day streak';
  }

  @override
  String unlockFocusHours(int n) {
    return 'Focus for $n hours';
  }

  @override
  String unlockFocusSessions(int n) {
    return '$n focus sessions';
  }

  @override
  String unlockLongSession(int n) {
    return 'One $n-minute session';
  }

  @override
  String unlockReviews(int n) {
    return '$n reviews';
  }

  @override
  String unlockStudyDays(int n) {
    return 'Study on $n days';
  }

  @override
  String unlockBlooms(int n) {
    return 'Bloom $n times';
  }

  @override
  String unlockEvenings(int n) {
    return 'Study on $n evenings';
  }

  @override
  String unlockComeback(int n) {
    return '$n sessions in a row after a withered tree';
  }

  @override
  String unlockWeeks(int n) {
    return 'Study $n weeks in a row';
  }

  @override
  String unlockMonth(int n) {
    return 'Study in month $n';
  }

  @override
  String get focusWarnTitle => 'Your tree is about to wither';

  @override
  String get focusWarnBody =>
      'Come back to hifive in a few seconds to keep it growing.';

  @override
  String reviewWatered(int count) {
    return 'Study tree +$count waterings';
  }

  @override
  String get homeGardenTitle => 'Your garden';

  @override
  String get homeGardenBody => 'Focus or review words to grow trees';

  @override
  String get homeGardenOpen => 'Open';

  @override
  String get tagPickTitle => 'Tags';

  @override
  String get tagNew => 'New tag';

  @override
  String get tagEditTitle => 'Edit tag';

  @override
  String get tagNameHint => 'Tag name, e.g. Reading';

  @override
  String get tagSave => 'Save';

  @override
  String get tagDelete => 'Delete tag';

  @override
  String get tagDeleteTitle => 'Delete this tag?';

  @override
  String get tagDeleteBody =>
      'Sessions with this tag will show as \"Other\". Their focus time stays.';

  @override
  String get gardenByTag => 'By tag';

  @override
  String get gardenByTagEmpty => 'Finish a focus session to see time by tag.';

  @override
  String get gardenShare => 'Share';

  @override
  String gardenShareText(int count) {
    return 'My hifive garden: $count trees grown by studying and focusing.';
  }

  @override
  String get gardenShareFailed => 'Couldn\'t open the share sheet.';

  @override
  String get timerTitle => 'Timer';

  @override
  String get timerSubtitle => 'Set a length and count down';

  @override
  String get stopwatchTitle => 'Stopwatch';

  @override
  String get stopwatchSubtitle => 'Count up from zero, up to 180 minutes';

  @override
  String get sessionTitleHint => 'Add a session title...';

  @override
  String get sessionTitleSheet => 'Session title';

  @override
  String get focusStop => 'Stop';

  @override
  String get focusStopShortTitle => 'Stop before 10 minutes?';

  @override
  String get focusStopShortBody =>
      'A stopwatch session under 10 minutes plants no tree.';

  @override
  String get helpTitle0 => 'The story of hifive';

  @override
  String get helpBody0 =>
      'hifive helps you learn a language every day the way you tend a garden: a little each day, until one day you look back at a whole forest.\n\nWhat the logo means\n\n• The five rounded bars are five fingers raised for a high five, a cheer after every session.\n• They are also the sound wave of a voice, because learning a language is about speaking and understanding each other.\n• The five colors are the ways you learn here: conversation (cyan), writing (blue), hifive\'s own indigo, grammar (violet) and AI (purple).\n\nThe hifive promise\n\nEvery word you meet anywhere in hifive, in flashcards, games or the dictionary, is followed until you can use it.';

  @override
  String get todayTitle => 'Today\'s review';

  @override
  String todaySummary(int due, int fresh) {
    return '$due to review · $fresh new';
  }

  @override
  String get todayStart => 'Start';

  @override
  String get todayAllDone => 'All done for today';

  @override
  String get todayAllDoneBody =>
      'Come back tomorrow, just before you\'d forget.';

  @override
  String get exIntro => 'New word. Guess the meaning first.';

  @override
  String get exShowMeaning => 'Show meaning';

  @override
  String get exChoose => 'Pick the right meaning';

  @override
  String get exType => 'Type the word for this meaning';

  @override
  String get exListen => 'Listen and type it';

  @override
  String get exCloze => 'Fill in the missing word';

  @override
  String get exAnswerHint => 'Type your answer';

  @override
  String get exHint => 'Hint';

  @override
  String get exCheck => 'Check';

  @override
  String get exDontKnow => 'I don\'t know';

  @override
  String get exCorrect => 'Correct';

  @override
  String get exAlmost => 'Almost, mind the spelling';

  @override
  String get exWrong => 'Not quite, this word comes back';

  @override
  String get exNext => 'Next';

  @override
  String get exTooEasy => 'Too easy';

  @override
  String get exPlay => 'Play again';

  @override
  String exProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get newPerDayTitle => 'New words a day';

  @override
  String get newPerDayBody =>
      'Reviews are never capped. When many are waiting, new words slow down.';

  @override
  String get memorySettings => 'Word memory';

  @override
  String get exTypingSetting => 'Typing exercises';

  @override
  String get exTypingSettingBody =>
      'See the meaning and type the word; fill in sentences';

  @override
  String get exListeningSetting => 'Listening exercises';

  @override
  String get exListeningSettingBody =>
      'Hear and type. Turn off in public places.';

  @override
  String get reminderTitle => 'Daily review reminder';

  @override
  String reminderAt(String time) {
    return 'At $time · only when words are due';
  }

  @override
  String get reminderPickTime => 'Reminder time';

  @override
  String get reminderDone => 'Done';

  @override
  String reminderNoteTitle(int count) {
    return '$count words are fading';
  }

  @override
  String reminderNoteBody(int minutes) {
    return 'About $minutes min of review keeps them, and waters your study tree.';
  }

  @override
  String get memoryTitle => 'Word memory';

  @override
  String memoryCardBody(int known, int total) {
    return '$known known · $total met';
  }

  @override
  String get levelFresh => 'New';

  @override
  String get levelLearning => 'Learning';

  @override
  String get levelRemembering => 'Remembering';

  @override
  String get levelKnown => 'Known';

  @override
  String get levelMastered => 'Mastered';

  @override
  String get memoryLevels => 'Words by level';

  @override
  String get memoryLevelsNote =>
      'Known: remembered for 3 weeks or more. Mastered: known, and typed or used right in the last 60 days.';

  @override
  String get memoryRetention => 'Retention';

  @override
  String memoryRetentionBody(int count) {
    return 'Of $count reviews of known words in 30 days. The aim is about 90%.';
  }

  @override
  String get memoryRetentionWait =>
      'Review a few more days to measure retention.';

  @override
  String get memoryForecast => 'Next 7 days';

  @override
  String get memoryToday => 'Today';

  @override
  String get memorySkills => 'Skills';

  @override
  String get memorySkillsEmpty =>
      'Do Today\'s review to see which skills need work.';

  @override
  String get skillMeaning => 'Meaning';

  @override
  String get skillRecall => 'Recall';

  @override
  String get skillForm => 'Sound and spelling';

  @override
  String get skillUse => 'Use in a sentence';

  @override
  String get memoryHard => 'Hard words';

  @override
  String get memoryHardEmpty =>
      'No hard words yet. Words forgotten four times or more show here.';

  @override
  String get wordRecallNow => 'Chance you remember now';

  @override
  String get wordNextReview => 'Next review';

  @override
  String get wordStability => 'Memory lasts about';

  @override
  String wordDays(int count) {
    return '$count days';
  }

  @override
  String get wordLapses => 'Times forgotten';

  @override
  String get wordHistory => 'Meetings';

  @override
  String get wordNoHistory => 'Not reviewed yet.';

  @override
  String get wordNow => 'Now';

  @override
  String get todayEyebrow => 'TODAY';

  @override
  String get todayHeadline => 'Review words';

  @override
  String todayDueChip(int count) {
    return '$count due';
  }

  @override
  String todayNewChip(int count) {
    return '$count new';
  }

  @override
  String todayMinutes(int count) {
    return 'about $count min';
  }

  @override
  String get todayDoneBody => 'See you tomorrow';

  @override
  String get practiceTitle => 'Type and listen';

  @override
  String get practiceBody =>
      'Type, listen and fill words into sentences to remember them for good.';

  @override
  String get menuListen => 'Listen';

  @override
  String get listenTitle => 'Listening';

  @override
  String get listenIntro =>
      'Listening picked by hifive for your level. Save new words to review them in Today\'s review.';

  @override
  String get listenEmpty =>
      'Loading listening sources. Check your connection and open this again.';

  @override
  String listenPlaylist(String channel) {
    return 'YouTube playlist · $channel';
  }

  @override
  String get listenSaveWord => 'Save a word you heard';

  @override
  String get listenWord => 'Word or phrase';

  @override
  String get listenMeaning => 'Meaning';

  @override
  String get listenSave => 'Save';

  @override
  String listenSaved(String word) {
    return 'Saved \"$word\" to Saved words';
  }

  @override
  String get listenTip =>
      'Tip: listen once for the gist, then again and save the words you want to use.';
}
