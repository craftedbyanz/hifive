// Renders every screen to PNG, to prove a refactor changes no pixels:
//   flutter test tool/pixel_snapshot_test.dart --dart-define=PIX_OUT=<dir>
// Add --dart-define=PIX_LANG=en (or zh, ko) to render another language.
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
import 'package:hifive/domain/community/community.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/vocab/vocab.dart';
import 'package:hifive/features/community/community.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/game/game.dart';
import 'package:hifive/features/garden/garden.dart';
import 'package:hifive/features/history/history.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/features/information/information.dart';
import 'package:hifive/features/insights/insights.dart';
import 'package:hifive/features/learning/learning.dart';
import 'package:hifive/features/listening/listening.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/features/welcome/welcome.dart';
import 'package:hifive/l10n/l10n.dart';
import 'package:hifive/state/state.dart';

const out = String.fromEnvironment('PIX_OUT');

/// The interface language to render, `vi` unless PIX_LANG names another.
const lang = String.fromEnvironment('PIX_LANG', defaultValue: 'vi');
AppState make({
  ShareRepository? shares,
  CircleRepository? circles,
  AuthService? auth,
}) => createAppState(
  store: MemoryRecordStore(),
  shares: shares,
  circles: circles,
  auth: auth,
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
    'onboarding': (s) => const OnboardingScreen(),
    'appearance': (s) => const AppearanceScreen(),
    'notification': (s) => const NotificationScreen(),
    'listening': (s) {
      s.listening = parseListening(
        File('worker/catalog/en/3.json').readAsStringSync(),
      );
      final e = s.listening.single.episodes;
      s
        ..listened(e[0].id, position: e[0].seconds, heard: 400, done: true)
        ..listened(e[1].id, position: 300, heard: 300);
      return const ListeningScreen();
    },
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
    for (var i = 0; i < helpCount; i++) 'help_$i': (s) => HelpScreen(index: i),
    if (topic != null) 'collection': (s) => CollectionScreen(topic: topic),
  };
  Future<AppState> mount(
    WidgetTester t,
    Widget Function(AppState) f, {
    AppState? state,
  }) async {
    t.view.physicalSize = const Size(786, 1704);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final s = state ?? make();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AppScope(
          state: s,
          child: MaterialApp(
            theme: D.theme,
            debugShowCheckedModeBanner: false,
            locale: const Locale(lang),
            supportedLocales: supportedAppLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
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
    await t.tap(find.text(lookupAppLocalizations(const Locale(lang)).menu));
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
    await t.tap(
      find.byTooltip(lookupAppLocalizations(const Locale(lang)).next),
    );
    await settle(t);
    await shot(t, 'practice_wrong');
    await t.tap(find.text(lookupAppLocalizations(const Locale(lang)).editVi));
    await settle(t);
    await t.enterText(
      find.byKey(const ValueKey('answer-input')),
      MockLessonRepository.practiceNow(
        'T',
        StudyMode.grammar,
      ).questions.first.answer,
    );
    await t.pump();
    await t.tap(
      find.byTooltip(lookupAppLocalizations(const Locale(lang)).next),
    );
    await settle(t);
    await shot(t, 'practice_correct');
  });
  testWidgets('focus', (t) async {
    var now = DateTime(2026, 11, 1, 9, 30);
    await mount(t, (s) => FocusScreen(clock: () => now));
    await shot(t, 'focus_setup');
    await t.tap(find.byKey(const ValueKey('focus-change-tree')));
    await settle(t);
    await shot(t, 'focus_picker');
    await t.tapAt(const Offset(20, 40));
    await settle(t);
    await t.tap(find.byKey(const ValueKey('focus-start')));
    now = now.add(const Duration(seconds: 4));
    await settle(t);
    await shot(t, 'focus_cancel');
    now = now.add(const Duration(minutes: 6));
    await settle(t);
    await shot(t, 'focus_running');
  });
  testWidgets('share', (t) async {
    final repo = MemoryShareRepository();
    final state = make(
      shares: repo,
      auth: MemoryAuthService(
        signedIn: const AuthUser(uid: 'u', method: AuthMethod.email),
      ),
    );
    await mount(t, (s) => DeckScreen(deck: s.decks.first), state: state);
    await t.tap(
      find.byTooltip(lookupAppLocalizations(const Locale(lang)).deckOptions),
    );
    await settle(t);
    await t.tap(
      find.text(lookupAppLocalizations(const Locale(lang)).shareDeck),
    );
    await settle(t);
    await shot(t, 'share_sheet');
    await t.pumpWidget(const SizedBox());
    await mount(t, (s) => const DeckListScreen(), state: state);
    await t.tap(find.byKey(const ValueKey('deck-import')));
    await settle(t);
    await t.enterText(find.byKey(const ValueKey('import-code')), 'AAAAA2');
    await t.tap(find.byKey(const ValueKey('import-open')));
    await settle(t);
    await shot(t, 'import_sheet');
    await t.pumpWidget(const SizedBox());
    await repo.publish(
      'token-other',
      'd1',
      SharedDeck.fromJson({
        'title': 'Travel words for beginners',
        'language': 'en',
        'words': [
          {'word': 'ticket', 'meaning': 'vé'},
        ],
      }),
      public: true,
      author: 'Minh',
    );
    await mount(t, (s) => const ExploreScreen(), state: state);
    await shot(t, 'explore');
  });
  testWidgets('help_cards', (t) async {
    await mount(
      t,
      (s) => Scaffold(
        backgroundColor: D.background,
        body: Center(
          child: FittedBox(
            child: SizedBox(
              width: 176.0 * helpCount,
              height: 191,
              child: Row(
                children: [
                  for (final i in helpOrder)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: HomeHelpCard(index: i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await shot(t, 'help_cards');
  });
  testWidgets('deck_edit', (t) async {
    final s = await mount(t, (s) => const DeckListScreen());
    await t.tap(
      find.byTooltip(lookupAppLocalizations(const Locale(lang)).addDeck),
    );
    await settle(t);
    await t.enterText(find.byKey(const ValueKey('deck-topic')), 'Du lịch Nhật');
    await settle(t);
    await shot(t, 'deck_new');
    await t.tap(find.byKey(const ValueKey('deck-create')));
    await settle(t);
    await t.tap(find.byKey(const ValueKey('deck-header-icon')));
    await settle(t);
    await t.tap(find.byKey(const ValueKey('deck-icon-2')));
    await settle(t);
    await shot(t, 'deck_edit');
    await t.tap(find.byKey(const ValueKey('deck-edit-save')));
    await settle(t);
    await t.tap(
      find.byTooltip(lookupAppLocalizations(const Locale(lang)).deckOptions),
    );
    await settle(t);
    await shot(t, 'deck_menu');
    await t.tap(find.text(lookupAppLocalizations(const Locale(lang)).addWords));
    await settle(t);
    await shot(t, 'deck_add_words');
    expect(s.decks.last.icon, 2);
  });
  testWidgets('circles', (t) async {
    final shares = MemoryShareRepository();
    final circles = MemoryCircleRepository(shares: shares);
    final state = make(
      shares: shares,
      circles: circles,
      auth: MemoryAuthService(
        signedIn: const AuthUser(uid: 'u', method: AuthMethod.google),
      ),
    );
    final group = await circles.create(
      'token-u',
      kind: CircleKind.group,
      name: 'Nhóm IELTS buổi sáng',
      goal: 4,
    );
    for (final (who, name, days) in [
      (
        'token-a',
        'Minh',
        ['2026-10-26', '2026-10-27', '2026-10-28', '2026-10-30'],
      ),
      ('token-b', 'Lan', ['2026-10-27', '2026-10-29']),
    ]) {
      await circles.join(who, group.code);
      circles
        ..names[who] = name
        ..studied[who] = {...days};
    }
    circles.studied['token-u'] = {'2026-10-26', '2026-11-01'};
    await mount(t, (s) => const CommunityScreen(initialTab: 1), state: state);
    await shot(t, 'community_groups');
    await t.pumpWidget(const SizedBox());
    await mount(t, (s) => CircleScreen(circle: group), state: state);
    await shot(t, 'circle_group');
    await t.pumpWidget(const SizedBox());
    final klass = await circles.create(
      'token-u',
      kind: CircleKind.classroom,
      name: 'Lớp 6A',
    );
    for (final who in ['token-a', 'token-b']) {
      await circles.join(who, klass.code);
    }
    final deck = state.decks.first;
    await state.assignDeck(klass.id, deck, DateTime(2026, 11, 8));
    final a = circles.assignments[klass.id]!.single;
    circles.learned['token-a'] = {...a.words};
    circles.learned['token-b'] = {...a.words.take(4)};
    await mount(t, (s) => CircleScreen(circle: klass), state: state);
    await t.tap(find.byKey(ValueKey('assignment-open-${a.id}')));
    await settle(t);
    await shot(t, 'circle_class');
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
