import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/community/community.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/features/community/community.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

/// A deck someone else shared publicly.
SharedDeck _deck(String title) => SharedDeck(
  title: title,
  language: 'en',
  words: [FlashWord(id: '', word: 'ticket', meaning: 'vé')],
);

void main() {
  setUpAll(loadAppFonts);

  late MemoryShareRepository repo;
  late AppState state;
  setUp(() {
    repo = MemoryShareRepository();
    state = fresh(auth: signedIn(), shares: repo)..name = 'Lan';
  });

  Future<String> other(String title, {String author = 'Minh'}) => repo.publish(
    'token-other',
    title,
    _deck(title),
    public: true,
    author: author,
  );

  testWidgets('making a deck public asks for the rules once, then lists it', (
    tester,
  ) async {
    final deck = state.decks.first;
    await mount(tester, state, DeckScreen(deck: deck));
    await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chia sẻ bộ thẻ'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chỉ ai có mã hoặc liên kết mới mở được.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('share-public')));
    await tester.pumpAndSettle();
    expect(find.text('Quy tắc cộng đồng'), findsOneWidget);
    await tester.tap(find.text('Tôi đồng ý'));
    await tester.pumpAndSettle();
    expect(state.communityRules, isTrue);
    expect(state.publicDecks, {deck.id});
    expect(repo.public, {'AAAAA2': 'Lan'});
    expect(
      find.text('Mọi người đều tìm thấy bộ thẻ này. Tên hiển thị: Lan'),
      findsOneWidget,
    );

    // Off again, with no rules this time; the code stays.
    await tester.tap(find.byKey(const ValueKey('share-public')));
    await tester.pumpAndSettle();
    expect(find.text('Quy tắc cộng đồng'), findsNothing);
    expect(repo.public, isEmpty);
    expect(state.sharedDecks[deck.id], 'AAAAA2');
  });

  testWidgets('declining the rules leaves the deck private', (tester) async {
    await mount(tester, state, DeckScreen(deck: state.decks.first));
    await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chia sẻ bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share-public')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ').last);
    await tester.pumpAndSettle();
    expect(state.communityRules, isFalse);
    expect(repo.public, isEmpty);
  });

  testWidgets('a public deck is found, added and counted for its owner', (
    tester,
  ) async {
    final travel = await other('Travel words');
    await other('Kitchen words');
    final before = state.decks.length;
    await mount(tester, state, const DeckListScreen());
    await tester.tap(find.byKey(const ValueKey('deck-explore')));
    await tester.pumpAndSettle();
    expect(find.text('Travel words'), findsOneWidget);
    expect(find.text('Kitchen words'), findsOneWidget);
    expect(find.text('1 từ · Minh'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey('explore-search')),
      'trav',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Kitchen words'), findsNothing);

    await tester.tap(find.byKey(ValueKey('explore-deck-$travel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-add')));
    await tester.pumpAndSettle();
    expect(state.decks, hasLength(before + 1));
    expect(state.decks.last.title, 'Travel words');
    expect(find.byType(DeckScreen), findsOneWidget);
    expect(repo.adds[travel], {'token-u-test'});
  });

  testWidgets('reporting a deck takes it off the reporter\'s list', (
    tester,
  ) async {
    final bad = await other('Bad deck');
    await mount(tester, state, const ExploreScreen());
    await tester.tap(find.byKey(ValueKey('explore-deck-$bad')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('explore-report')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-spam')));
    await tester.pumpAndSettle();
    expect(repo.reports[bad], {'token-u-test': ReportReason.spam});
    expect(
      find.text('Cảm ơn bạn. Bộ thẻ này sẽ không hiện với bạn nữa.'),
      findsOneWidget,
    );
    expect(find.text('Bad deck'), findsNothing);
  });

  testWidgets('blocking an owner hides their decks until unblocked', (
    tester,
  ) async {
    final one = await other('One');
    await repo.publish(
      'token-third',
      'x',
      _deck('Other'),
      public: true,
      author: 'Ha',
    );
    await mount(tester, state, const ExploreScreen());
    await tester.tap(find.byKey(ValueKey('explore-deck-$one')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('explore-block')));
    await tester.pumpAndSettle();
    expect(find.text('Chặn Minh?'), findsOneWidget);
    await tester.tap(find.text('Chặn người tạo').last);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing);
    expect(find.text('Other'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('explore-unblock')));
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOneWidget);
  });

  testWidgets('with nothing public, Explore says so; offline, it can retry', (
    tester,
  ) async {
    await mount(tester, state, const ExploreScreen());
    expect(find.byKey(const ValueKey('explore-empty')), findsOneWidget);
    repo.failWith = ShareError.unavailable;
    await tester.tap(find.byKey(const ValueKey('explore-sort-newest')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('explore-error')), findsOneWidget);
    repo.failWith = null;
    await tester.tap(find.byKey(const ValueKey('explore-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('explore-empty')), findsOneWidget);
  });

  test('which decks are public survives a restart', () async {
    final store = MemoryRecordStore();
    final a = fresh(store: store, auth: signedIn(), shares: repo);
    await a.load();
    await a.shareDeck(a.decks.first, public: true);
    await a.flush();
    final b = fresh(store: store, auth: signedIn(), shares: repo);
    await b.load();
    expect(b.publicDecks, {b.decks.first.id});
    // Sharing again without saying keeps it public.
    await b.shareDeck(b.decks.first);
    expect(repo.public.keys, ['AAAAA2']);
  });
}
