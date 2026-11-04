import 'package:flutter/material.dart';

/// Screen-specific colors, kept exact for fidelity. Prefer the `D` tokens for
/// anything shared across screens.
abstract final class Palette {
  // Profile sub-screens, sampled from the reference after conversion to sRGB.
  static const settingsPage = Color(0xfff8fbfc);
  // Flashcards, sampled from the reference after conversion to sRGB.
  static const deckFab = Color(0xff1f2937);
  static const deckRowFill = Color(0xfffafafa);
  static const dueDot = Color(0xffef4444);
  static const reviewPill = Color(0xffdcfce7);
  static const reviewPillInk = Color(0xff15803d);
  static const learningPill = Color(0xffffedd5);
  static const learningPillInk = Color(0xffc2410c);
  static const newPill = Color(0xffdbeafe);
  static const newPillInk = Color(0xff1d4ed8);
  static const progressLearning = Color(0xfff59e0b);
  static const progressReview = Color(0xff10b981);
  static const reviewFill = Color(0xff86efac);
  static const rateAgain = Color(0xffef4444);
  static const rateHard = Color(0xfff59e0b);
  static const rateGood = Color(0xff3b82f6);
  static const rateEasy = Color(0xff84cc16);
  static const slotFill = Color(0xfffdf3c6);
  static const slotInk = Color(0xffd97706);
  static const generateOff = Color(0xffcdd0d7);
  static const completePage = Color(0xfffafafa);
  static const medalGold = Color(0xfffbd038);
  static const medalOrange = Color(0xfff59e0b);
  static const medalRibbon = Color(0xffd97f06);
  static const statSeen = Color(0xff6366f1);
  static const statKnown = Color(0xff22c55e);
  static const guideBarrier = Color(0x8c3c3c3c);
  static const cardTintBlue = Color(0xffdbeafe);
  static const cardTintPurple = Color(0xffede9fe);
  static const cardTintGreen = Color(0xffdcfce7);
  static const cardTintAmber = Color(0xfffef3c7);
  static const plusBody = Color(0xff8a8f99);
  static const policyBody = Color(0xff606775);
  static const logoTop = Color(0xff22d3ee);
  static const logoMiddle = Color(0xff1d8ff0);
  static const logoBottom = Color(0xff7cb8fb);
  static const flagChinaRed = Color(0xffee3124);
  static const settingsPanel = Color(0xfff2f5f6);
  static const settingsPanelClear = Color(0x00f2f5f6);
  static const settingsEdge = Color(0xffe5e7eb);
  static const settingsMuted = Color(0xff6b7280);
  static const settingsHint = Color(0xff9ca3af);
  static const accentCyan = Color(0xff06b6d4);
  static const ctaCyan = Color(0xff22d3ee);
  static const ctaGreen = Color(0xff10b981);
  static const ctaDisabled = Color(0xffd1d5db);
  static const saveDisabled = Color(0xffdddddf);
  static const soonInk = Color(0xffea580c);
  static const soonFill = Color(0xffffedd5);
  static const nativeStar = Color(0xfff59e0b);
  static const levelA1 = Color(0xff22c55e);
  static const levelA2 = Color(0xff84cc16);
  static const levelB1 = Color(0xffeab308);
  static const levelB2 = Color(0xfff97316);
  static const levelC1 = Color(0xffef4444);
  static const levelC2 = Color(0xffdc2626);
  static const levelNote = Color(0xff0891b2);
  static const voiceNormal = Color(0xff059669);
  static const previewDefault = Color(0xff3b82f6);
  static const inputOrange = Color(0xffff8e28);
  static const inputYellow = Color(0xfffecc00);
  static const inputGreen = Color(0xff34c85a);
  static const inputBlue = Color(0xff0088fe);
  static const inputPink = Color(0xfffe2d55);
  static const inputPurple = Color(0xffca30df);
  static const inputIndigo = Color(0xff6366f0);
  static const toggleOff = Color(0xffc1c0c4);
  static const hintDisc = Color(0xffe8eaed);
  static const previewBlue = Color(0xff5a94f6);
  static const previewPurple = Color(0xff9a74f4);
  static const previewCyan = Color(0xff4cc9de);
  static const styleRegularStart = Color(0xff2563eb);
  static const styleRegularEnd = Color(0xff06b6d4);
  static const styleGlassStart = Color(0xffa78bfa);
  static const styleGlassEnd = Color(0xffddd6fe);
  static const pushDisc = Color(0xffdcfce7);
  static const pushBell = Color(0xff16a34a);
  static const pushPill = Color(0xffe7f8f1);
  static const smartSpark = Color(0xfffacc15);
  static const wallMint = Color(0xffb9e6d9);
  static const wallTeal = Color(0xff7fd1bb);
  static const wallBlue = Color(0xff4f86dc);
  static const wallDeep = Color(0xff2f4fb8);
  static const wallMist = Color(0xffc6d8dc);
  static const dangerFill = Color(0xffffefee);
  static const dangerEdge = Color(0xffffd7d8);
  static const dangerInk = Color(0xffef4444);
  static const plusBlue = Color(0xff0088fe);
  static const plusFill = Color(0xffeaf5ff);
  static const plusChat = Color(0xff34c759);
  static const plusSpark = Color(0xfffacc15);
  static const plusSoonFill = Color(0xfffef0d7);
  static const plusSoonInk = Color(0xffc2710c);
  static const storeBlue = Color(0xff1c8ef9);
  static const storeField = Color(0xfff2f2f4);
  static const storeInk = Color(0xff8e8e93);
  static const storeAction = Color(0xff007aff);
  static const reviewField = Color(0xfff2f2f7);
  static const sheetEdge = Color(0xffe5e5ea);
  static const sheetGlass = Color(0xb3f5f5f7);
  static const sheetBarrier = Color(0x33000000);
  static const policyLink = Color(0xff0088fe);
  static const policyHighlight = Color(0xff3b82f6);
  static const yellow = Color(0xffeab308);
  static const iconGrey = Color(0xff4b5563);
  static const magenta = Color(0xffed409c);
  static const promoInk = Color(0xff16334a);
  static const footerBase = Color(0xffd1d2dd);
  static const flowerTop = Color(0xff12c6e6);
  static const flowerBottom = Color(0xffb5d6fb);
  static const flowerStarEnd = Color(0xff9fd4f7);
  static const glassWriting = Color(0xffb5d9ff);
  static const glassGrammar = Color(0xffe0c9fe);
  static const glassConversation = Color(0xff9aedfd);
  static const edgeWriting = Color(0xff4b6caf);
  static const edgeGrammar = Color(0xff725bae);
  static const edgeConversation = Color(0xff388b9c);
  static const edgeNeutral = Color(0xfff4f5f6);
  static const insightBook = Color(0xff8b5cf6);
  static const insightClock = Color(0xfff59e0b);
  static const insightPeople = Color(0xffec4899);
  static const insightDot = Color(0xffe5e7eb);
  static const insightDotDone = Color(0xffa7f3c8);
  static const insightCard = Color(0xfff6f9fa);
  static const insightBarTop = Color(0xff3b82f6);
  static const insightBarEnd = Color(0xff93c5fd);
  static const insightTips = Color(0xfffdf8e3);
  static const insightTipsInk = Color(0xff374151);
  static const insightFaint = Color(0xff9ca3af);
  static const insightAiInk = Color(0xfff0605a);
  static const insightBackEdge = Color(0xffc6c6c8);
  static const profileDisc = Color(0xffeeeef0);
  static const profilePill = Color(0xfff2f5f6);
  static const profileEdge = Color(0xfff2f5f6);
  static const profileLine = Color(0xfff8fbfc);
  static const profileIconDisc = Color(0xfff8fbfc);
  static const profileChevron = Color(0xffc4c6ca);
  static const trialStart = Color(0xff3881f5);
  static const trialMiddle = Color(0xff2664ea);
  static const trialEnd = Color(0xff0ea0e8);
  static const logoutFill = Color(0xfffdf0f0);
  static const logoutEdge = Color(0xfff9d6d6);
  static const menuVeil = Color(0xffe2e7ed);
  static const menuLabelInk = Color(0xff32363a);
  static const menuGlyph = Color(0xfff3f6ff);
  static const footerIcon = Color(0xff8b8b8b);
  static const statusBand = Color(0xfff3f3f4);
  static const footerNeutral = Color(0xfff2f2f3);
  static const glassNeutral = Color(0xfff1f2f5);
  static const flagGlass = Color(0xfff6f7f7);
  static const flagBorder = Color(0xffa9aaab);
  static const aiUnderline = Color(0xffd0d4dc);
  static const menuInsight = Color(0xff39bcd9);
  static const menuPlus = Color(0xffecaa43);
  static const menuFlashcard = Color(0xff9d77f5);
  static const menuStreak = Color(0xfff48744);
  static const menuGame = Color(0xff31be94);
  static const orbBack = Color(0xffa4b6eb);
  static const orbMiddle = Color(0xff75c9cb);
  static const orbFront = Color(0xff8ed3d8);
  static const flagRed = Color(0xffec4545);
  static const flagBlue = Color(0xff274b9e);
  static const chipSpecial = Color(0xffdbeafe);
  static const chipSpecialText = Color(0xff1f3a8a);
  static const chipSpecialIcon = Color(0xff2563eb);
  static const chipInk = Color(0xff374151);
  static const homeDivider = Color(0xffeef1f3);
  static const artPurpleSoft = Color(0xffefe9fd);
  static const artPurpleIcon = Color(0xffb99df8);
  static const artPinkLine = Color(0xfffce7f1);
  static const artPinkFill = Color(0xfffdf0f6);
  static const artPinkBorder = Color(0xfff8d4e4);
  static const artPinkBar = Color(0xfff5b9d5);
  static const artGreenFill = Color(0xffe6f7f0);
  static const artGreenBorder = Color(0xffb8e8d6);
  static const artGreenBar = Color(0xffa7e5cf);
  static const artGreenBar2 = Color(0xffc9eedf);
  static const artBlueSheet = Color(0xffd3e2fd);
  static const artBlueDisc = Color(0xffe8eef8);
  static const artOrange = Color(0xfff97316);
  static const artOrangeFaint = Color(0xfffbcfa8);
  static const artOrangeLight = Color(0xfffdac78);
  static const artOrangeMedium = Color(0xfffb9952);
  static const artOrangeGlow = Color(0xfffed7aa);
  static const artOrangeFill = Color(0xffffedd5);
  static const artOrangeBorder = Color(0xfffdba74);
  static const artOrangeHand = Color(0xfffb923c);
  static const artTealArc = Color(0xffb2e7df);
  static const artTealDisc = Color(0xffe0f5f2);
  static const flashcardPromoStart = Color(0xff1a2452);
  static const flashcardPromoEnd = Color(0xff2560df);
  static const promoAccent = Color(0xffb9e8fc);
  static const promoCard = Color(0xfff0f5ff);
  static const promoCardLine = Color(0xffd3e3fc);
  static const gamePromoStart = Color(0xff5a29aa);
  static const gamePromoEnd = Color(0xff120923);
  static const gamePromoAccent = Color(0xffa35df2);
  static const miniArtPurple = Color(0xff8b5cf6);
  static const helpTeal = Color(0xff14b8ad);
  static const deckRow = Color(0xfff8f9fa);
  static const reviewBlue = Color(0xffe9f3ff);
  static const reviewPurple = Color(0xfff0e8ff);
  static const reviewGreen = Color(0xffe6faec);
  static const reviewAmber = Color(0xfffff2da);
  static const ratingEasy = Color(0xff8bd011);
  static const categoryInactive = Color(0xffd3d6dc);
  static const topicInactive = Color(0xffd2d6db);
  static const profileMuted = Color(0xffbebdc1);
  static const progressDone = Color(0xffa7efc6);
  static const highlight = Color(0xfffffac3);
  static const wrong = Color(0xffef4444);
  static const correctionBackground = Color(0xfff3f6f7);
  static const removedWord = Color(0xffef8888);
  static const gameTop = Color(0xff69c847);
  static const gameMiddle = Color(0xff346b26);
  static const gameBottom = Color(0xff071404);

  /// Flow Letter's background per word, sampled on the iPhone (top, middle,
  /// bottom): green, purple, then teal-green, repeating.
  static const gameWords = [
    [Color(0xff4fae3a), Color(0xff26521d), Color(0xff081804)],
    [Color(0xff663e9f), Color(0xff3d2562), Color(0xff0c0519)],
    [Color(0xff3e9c5e), Color(0xff25663c), Color(0xff06180b)],
  ];
  static const gameBest = Color(0xfffbbf24);
  static const gameTrophy = Color(0xffefbe01);
  static const gameTileTop = Color(0xff86cf63);
  static const gameTileBottom = Color(0xff5c9f40);
  static const difficultyTop = Color(0xff5525ae);
  static const difficultyBottom = Color(0xff0a021a);
  static const settingsTop = Color(0xff275ab4);
  static const settingsBottom = Color(0xff02091a);
  static const notificationStart = Color(0xffcee8ff);
  static const notificationEnd = Color(0xffece2ff);
  static const ratingAgain = Colors.red;
  static const insightHeart = Colors.pink;

  // Topic screen, sampled on the physical iPhone (3 November 2026).
  static const categorySelected = Color(0xfff97216);
  static const categoryText = Color(0xff1f2937);
  static const topicTileTop = Color(0xffffffff);
  static const topicTileBand = Color(0xfff6f9fa);
  static const topicTileBottom = Color(0xfffafdfe);
  static const topicTileEdge = Color(0xffb9bcbd);
  static const topicIconFill = Color(0xfff2f5f6);
  static const topicCountPill = Color(0xfff1f4f5);
  static const grammarAccent = Color(0xffd0fd3e);
  static const chooserRule = Color(0xffe5e5e5);
  static const chooserFoot = Color(0xfff2f5f6);
  static const chooserFaded = Color(0xffd8dadf);
  static const nextIdle = Color(0xff8d8c92);
  static const monoCard = Color(0xfff2f5f6);
  static const monoCardEdge = Color(0xffd1d4db);
  static const monoInk = Color(0xff374151);
  static const regularDark = Color(0xff111111);
  static const helpBody = Color(0xff4b5564);
  static const flameGreyTop = Color(0xff8a8a8a);
  static const flameGreyBottom = Color(0xffe6e6e6);
  static const historyYellow = Color(0xfffacc15);
  static const resultPage = Color(0xfffafafa);
  static const streakOrange = Color(0xfff97316);
  static const flameTop = Color(0xffef4423);
  static const flameBottom = Color(0xfffcb827);
  static const alertRed = Color(0xffd8232e);
  static const hintWord = Color(0xff713f12);
  static const alertBlue = Color(0xff0a7aff);
  static const alertMessage = Color(0xff6e6e73);
  static const feedbackText = Color(0xff243040);
  static const feedbackTip = Color(0xff374151);
  static const chatBlue = Color(0xff2965ea);
  static const chatArt = Color(0xffebf2fb);
  static const setArt = Color(0xfff3f3f5);
  static const createDisc = Color(0xffdefe77);
  static const skeleton = Color(0xffe6e7e9);
  static const levelGreen = Color(0xff23c55e);
  static const levelLime = Color(0xff84cc16);
  static const levelAmber = Color(0xffe9b408);
  static const levelRed = Color(0xffef4444);
  static const levelDeepRed = Color(0xffdb2625);
  static const levelCurrent = Color(0xffeef7f4);
  static const tipBlue = Color(0xff007bfe);
  static const tipBody = Color(0xff8e9193);
  static const tipClose = Color(0xffe1e4e5);
  static const tipTop = Color(0xfffdfdff);
  static const tipBottom = Color(0xfffafdfe);
  static const tipEdge = Color(0xff9b9e9f);
  static const endlessPurple = Color(0xffa755f6);
  static const endlessIconFill = Color(0xfff7f1fe);
  static const endlessFill = Color(0xfffcfafe);
  static const endlessEdge = Color(0xffeee4fb);

  /// Icon tint per category chip (median of the glyph's pixels; the
  /// reference glyphs are two-tone).
  static const categoryIcons = {
    'Dành cho bạn': Color(0xfff9852f),
    'Giao tiếp': Color(0xff4e93f7),
    'Hằng ngày': Color(0xff42d3bd),
    'Công việc': Color(0xff9a77f8),
    'Du lịch': Color(0xfff15ea7),
    'Mua sắm': Color(0xfff890c5),
    'Ẩm thực': Color(0xff24c78e),
    'Sức khỏe': Color(0xfff35c5b),
    'Phim ảnh': Color(0xfff7b01a),
    'Âm nhạc': Color(0xffb673f9),
    'Trò chơi': Color(0xff7179f4),
    'Thể thao': Color(0xff45d1e8),
    'Văn hóa': Color(0xffa58cfa),
    'Truyện ngắn': Color(0xffd4780b),
    'Tiểu luận': Color(0xff6f7e94),
    'Email': Color(0xff55bff2),
    'Học thuật': Color(0xff707f95),
    'IELTS': Color(0xffea524d),
    'Công nghệ': Color(0xff8795f8),
    'Sân bay & Khách sạn': Color(0xfff15ea7),
    'Văn hóa & Phim ảnh': Color(0xffa58cfa),
    'Học tập & Nghiên cứu': Color(0xff707f95),
    'Vui chơi & Giải trí': Color(0xfff9b01b),
  };
}
