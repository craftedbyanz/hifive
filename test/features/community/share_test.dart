import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/community/community.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  late MemoryShareRepository repo;
  late RecordingSystemActions system;
  setUp(() {
    repo = MemoryShareRepository();
    system = RecordingSystemActions();
  });

  AppState make({bool signed = true}) =>
      fresh(auth: signed ? signedIn() : null, shares: repo, system: system);

  Future<void> openShare(WidgetTester tester, AppState state, Deck deck) async {
    await mount(tester, state, DeckScreen(deck: deck));
    await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chia sẻ bộ thẻ'));
    await tester.pumpAndSettle();
  }

  testWidgets('sharing a deck shows its code and link and sends them', (
    tester,
  ) async {
    final state = make();
    final deck = state.decks.first;
    await openShare(tester, state, deck);

    expect(find.text('AAAAA2'), findsOneWidget);
    expect(find.text('https://hifive.test/s/AAAAA2'), findsOneWidget);
    expect(state.sharedDecks[deck.id], 'AAAAA2');
    final shared = repo.decks['AAAAA2']!;
    expect(shared.title, deck.title);
    expect(shared.words.map((w) => w.word), deck.words.map((w) => w.word));

    await tester.tap(find.byKey(const ValueKey('share-send')));
    await tester.pump();
    expect(system.texts.single, contains('https://hifive.test/s/AAAAA2'));
    expect(system.texts.single, contains('AAAAA2'));
    expect(system.texts.single, contains(deck.title));
  });

  testWidgets('sharing again keeps the code; stopping ends the link', (
    tester,
  ) async {
    final state = make();
    final deck = state.decks.first;
    await state.shareDeck(deck);
    await openShare(tester, state, deck);
    expect(find.text('AAAAA2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('share-stop')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ngừng chia sẻ').last);
    await tester.pumpAndSettle();
    expect(find.text('Đã ngừng chia sẻ'), findsOneWidget);
    expect(state.sharedDecks, isEmpty);
    expect(repo.decks, isEmpty);
  });

  testWidgets('without an account, sharing says so and can retry', (
    tester,
  ) async {
    final state = make(signed: false);
    await openShare(tester, state, state.decks.first);
    expect(
      find.text('Bạn cần đăng nhập và có kết nối mạng để chia sẻ.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('share-retry')), findsOneWidget);
    // Once signed in, trying again shares it.
    await state.auth.signInWithGoogle();
    await tester.tap(find.byKey(const ValueKey('share-retry')));
    await tester.pumpAndSettle();
    expect(find.text('AAAAA2'), findsOneWidget);
  });

  testWidgets('a shared deck is added from its link, with fresh progress', (
    tester,
  ) async {
    final state = make();
    final deck = state.decks.first;
    state.rate(deck.words.first, 3);
    await state.shareDeck(deck);
    final before = state.decks.length;

    await mount(tester, state, const DeckListScreen());
    await tester.tap(find.byKey(const ValueKey('deck-import')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('import-code')),
      'xem bộ này nhé https://hifive.test/s/aaaaa2',
    );
    await tester.tap(find.byKey(const ValueKey('import-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('import-preview')), findsOneWidget);
    expect(find.text(deck.words.first.word), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('import-add')));
    await tester.pumpAndSettle();
    expect(state.decks, hasLength(before + 1));
    final copy = state.decks.last;
    expect(copy.title, deck.title);
    expect(copy.id, isNot(deck.id));
    expect(copy.words.map((w) => w.word), deck.words.map((w) => w.word));
    expect(
      copy.words.map((w) => w.id).toSet().intersection({
        for (final w in deck.words) w.id,
      }),
      isEmpty,
    );
    // The copy opens, and nothing of the sharer's progress came with it.
    expect(find.byType(DeckScreen), findsOneWidget);
    expect(copy.words.first.reviews, 0);
  });

  testWidgets('a malformed code is caught before asking the server', (
    tester,
  ) async {
    await mount(tester, make(), const DeckListScreen());
    await tester.tap(find.byKey(const ValueKey('deck-import')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('import-code')), 'AB0');
    await tester.tap(find.byKey(const ValueKey('import-open')));
    await tester.pumpAndSettle();
    expect(find.text('Mã gồm 6 chữ và số, ví dụ K7M2QX.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('import-code')), 'k7m2qx');
    await tester.tap(find.byKey(const ValueKey('import-open')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Không tìm thấy bộ thẻ với mã này. Có thể nó đã ngừng được chia sẻ.',
      ),
      findsOneWidget,
    );
    repo.failWith = ShareError.unavailable;
    await tester.tap(find.byKey(const ValueKey('import-open')));
    await tester.pumpAndSettle();
    expect(
      find.text('Không kết nối được. Kiểm tra mạng rồi thử lại.'),
      findsOneWidget,
    );
  });

  testWidgets('without a server there is no sharing', (tester) async {
    final state = fresh();
    await mount(tester, state, DeckScreen(deck: state.decks.first));
    await tester.tap(find.byTooltip('Tùy chọn bộ thẻ'));
    await tester.pumpAndSettle();
    expect(find.text('Chia sẻ bộ thẻ'), findsNothing);
    await mount(tester, state, const DeckListScreen());
    expect(find.byKey(const ValueKey('deck-import')), findsNothing);
  });

  test('a code is found in what was typed or pasted', () {
    expect(shareCodeIn('K7M2QX'), 'K7M2QX');
    expect(shareCodeIn(' k7m-2qx '), 'K7M2QX');
    expect(shareCodeIn('Học nè: https://x.dev/s/k7m2qx'), 'K7M2QX');
    expect(shareCodeIn('K7M2Q0'), isNull);
    expect(shareCodeIn('K7M2Q'), isNull);
    expect(shareCodeIn('hello world'), isNull);
  });

  test(
    'which decks are shared survives a restart; stopping removes it',
    () async {
      final store = MemoryRecordStore();
      final state = fresh(store: store, auth: signedIn(), shares: repo);
      await state.load();
      final deck = state.decks.first;
      await state.shareDeck(deck);
      await state.flush();

      final again = fresh(store: store, auth: signedIn(), shares: repo);
      await again.load();
      expect(again.sharedDecks, {deck.id: 'AAAAA2'});
      await again.unshareDeck(again.decks.first);
      await again.flush();

      final third = fresh(store: store, auth: signedIn(), shares: repo);
      await third.load();
      expect(third.sharedDecks, isEmpty);
    },
  );
}
