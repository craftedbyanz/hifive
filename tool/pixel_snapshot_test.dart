// Renders every screen to PNG, to prove a refactor changes no pixels:
//   flutter test tool/pixel_snapshot_test.dart --dart-define=PIX_OUT=<dir>
// Run it before and after the change with separate empty directories, then
// compare them with `diff -rq`. PIX_OUT must exist and sit outside the repo.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/core/design/design.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/game/game.dart';
import 'package:hifive/features/history/history.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/features/information/information.dart';
import 'package:hifive/features/insights/insights.dart';
import 'package:hifive/features/learning/learning.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/features/welcome/welcome.dart';
import 'package:hifive/state/state.dart';

const out = String.fromEnvironment('PIX_OUT');
AppState make() => createAppState(
  store: MemoryRecordStore(),
  feedback: SilentFeedback(),
  includeExamples: true,
  now: () => DateTime(2026, 11, 1, 9, 30),
);
final key = GlobalKey();
Future<void> shot(WidgetTester t, String name) async {
  final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await t.runAsync(() async {
    final img = await b.toImage(pixelRatio: 2);
    final d = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return d!.buffer.asUint8List();
  });
  File('$out/$name.png').writeAsBytesSync(bytes!);
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  setUpAll(() async {
    final m =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final f in m.cast<Map<String, dynamic>>()) {
      final l = FontLoader(f['family'] as String);
      for (final a in (f['fonts'] as List).cast<Map<String, dynamic>>()) {
        l.addFont(rootBundle.load(a['asset'] as String));
      }
      await l.load();
    }
  });
  final topic = MockLessonRepository.topicsNow(
    StudyMode.grammar,
    'Dành cho bạn',
  ).firstOrNull;
  final scenes = <String, Widget Function(AppState)>{
    'home': (s) => const HomeScreen(animateAmbient: false),
    'decks': (s) => const DeckListScreen(),
    'deck': (s) => DeckScreen(deck: s.decks.first),
    'review': (s) =>
        ReviewScreen(deck: s.decks.first, words: s.decks.first.words),
    'game_home': (s) => const GameHomeScreen(),
    'game_settings': (s) => const GameSettingsScreen(),
    'game_difficulty': (s) => const GameDifficultyScreen(),
    'game_help': (s) => const GameHelpScreen(),
    'game': (s) => GameScreen(words: s.decks.first.words, title: 'T'),
    'history': (s) => const HistoryScreen(),
    'insight': (s) => const InsightScreen(),
    'streak': (s) => const StreakScreen(),
    'plus': (s) => const PlusScreen(),
    'article': (s) => const ArticleScreen(title: 'A', body: 'B'),
    'profile': (s) => const ProfileScreen(),
    'edit_profile': (s) => const EditProfileScreen(),
    'language': (s) => const LanguageScreen(),
    'level': (s) => const LevelPickerScreen(),
    'lesson_settings': (s) => const LessonSettingsScreen(),
    'voice': (s) => const VoiceScreen(),
    'welcome': (s) => const WelcomeScreen(),
    'sign_in': (s) => const Scaffold(body: SafeArea(child: EmailSignInForm())),
    'onboarding': (s) => const OnboardingScreen(),
    'appearance': (s) => const AppearanceScreen(),
    'notification': (s) => const NotificationScreen(),
    for (final m in StudyMode.values) ...{
      'topic_${m.name}': (s) => TopicScreen(mode: m),
      'gen_${m.name}': (s) => GeneratorScreen(mode: m),
      'practice_${m.name}': (s) =>
          PracticeScreen(lesson: MockLessonRepository.practiceNow('T', m)),
    },
    for (var i = 0; i < 3; i++) ...{
      'result_$i': (s) => ResultScreen(session: s.history[i]),
      'completion_$i': (s) => CompletionScreen(session: s.history[i]),
    },
    for (var i = 0; i < 7; i++) 'help_$i': (s) => HelpScreen(index: i),
    if (topic != null) 'collection': (s) => CollectionScreen(topic: topic),
  };
  Future<AppState> mount(WidgetTester t, Widget Function(AppState) f) async {
    t.view.physicalSize = const Size(786, 1704);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final s = make();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AppScope(
          state: s,
          child: MaterialApp(
            theme: D.theme,
            debugShowCheckedModeBanner: false,
            home: f(s),
          ),
        ),
      ),
    );
    await settle(t);
    return s;
  }

  scenes.forEach((name, f) {
    testWidgets(name, (t) async {
      await mount(t, f);
      await shot(t, name);
    });
  });
  testWidgets('home_menu', (t) async {
    await mount(t, scenes['home']!);
    await t.tap(find.text('Menu'));
    await settle(t);
    await shot(t, 'home_menu');
  });
  testWidgets('home_low', (t) async {
    await mount(t, scenes['home']!);
    for (final y in [800.0, 1078.0]) {
      await t.drag(
        find.byKey(const ValueKey('home-scroll')),
        Offset(0, -y / 2),
      );
      await settle(t);
      await shot(t, 'home_low_$y');
    }
  });
  testWidgets('home_cards', (t) async {
    await mount(t, scenes['home']!);
    for (final d in [-300.0, 600.0]) {
      await t.drag(find.byKey(const ValueKey('mode-carousel')), Offset(d, 0));
      await settle(t);
      await shot(t, 'home_card_$d');
    }
  });
  testWidgets('practice_feedback', (t) async {
    await mount(t, scenes['practice_grammar']!);
    await t.enterText(find.byKey(const ValueKey('answer-input')), 'zzz qqq');
    await t.pump();
    await t.tap(find.byTooltip('Chuyển tiếp'));
    await settle(t);
    await shot(t, 'practice_wrong');
    await t.tap(find.text('Sửa'));
    await settle(t);
    await t.enterText(
      find.byKey(const ValueKey('answer-input')),
      MockLessonRepository.practiceNow(
        'T',
        StudyMode.grammar,
      ).questions.first.answer,
    );
    await t.pump();
    await t.tap(find.byTooltip('Chuyển tiếp'));
    await settle(t);
    await shot(t, 'practice_correct');
  });
  testWidgets('review_flip', (t) async {
    await mount(t, scenes['review']!);
    await t.tap(find.byKey(const ValueKey('review-card')));
    await settle(t);
    await shot(t, 'review_back');
  });
  testWidgets('onboarding_steps', (t) async {
    await mount(t, scenes['onboarding']!);
    Future<void> next() async {
      await t.tap(find.byKey(const ValueKey('onboarding-next')));
      await settle(t);
    }

    await next();
    await shot(t, 'onboarding_cards');
    await t.tap(find.byKey(const ValueKey('onboarding-card')));
    await settle(t);
    await shot(t, 'onboarding_card_back');
    for (final name in ['writing', 'grammar', 'chat', 'name']) {
      await next();
      await shot(t, 'onboarding_$name');
    }
    await t.enterText(find.byKey(const ValueKey('onboarding-name')), 'Lan');
    await settle(t);
    await next();
    await shot(t, 'onboarding_level');
    await t.tap(find.byKey(const ValueKey('onboarding-level-B1')));
    await settle(t);
    await next();
    await shot(t, 'onboarding_goals');
  });
}
