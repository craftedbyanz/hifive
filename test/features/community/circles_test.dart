import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/community/community.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/community/community.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

// fresh()'s clock is Sunday 1 November 2026: the week runs from 26 October.
const _me = 'token-u-test';

void main() {
  setUpAll(loadAppFonts);

  late MemoryShareRepository shares;
  late MemoryCircleRepository circles;
  late RecordingSystemActions system;
  late AppState state;
  setUp(() {
    shares = MemoryShareRepository();
    circles = MemoryCircleRepository(shares: shares);
    system = RecordingSystemActions();
    state = fresh(
      auth: signedIn(),
      shares: shares,
      circles: circles,
      system: system,
    );
  });

  Future<void> openTab(WidgetTester tester, int tab, {List<Deck>? opened}) =>
      mount(
        tester,
        state,
        CommunityScreen(
          initialTab: tab,
          onOpenDeck: (_, deck) => opened?.add(deck),
        ),
      );

  testWidgets('a group is made with a goal, and its week shows who studied', (
    tester,
  ) async {
    await openTab(tester, 1);
    expect(find.byKey(const ValueKey('circles-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('circle-create')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('circle-name')),
      'Nhóm sáng',
    );
    await tester.tap(find.byKey(const ValueKey('circle-goal-more')));
    await tester.pump();
    expect(find.text('4 ngày'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('circle-save')));
    await tester.pumpAndSettle();

    // The new group opens with its code.
    final id = circles.circles.keys.single;
    final code = circles.circles[id]!.circle.code;
    expect(find.byType(CircleScreen), findsOneWidget);
    expect(find.text(code), findsOneWidget);
    expect(circles.circles[id]!.circle.goal, 4);

    // A friend joins and both study; the week shows it.
    await circles.join('token-friend', code);
    circles
      ..names['token-friend'] = 'Minh'
      ..studied['token-friend'] = {
        '2026-10-26',
        '2026-10-27',
        '2026-10-28',
        '2026-10-30',
      }
      ..studied[_me] = {'2026-11-01', '2026-10-20'};
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('circle-$id')));
    await tester.pumpAndSettle();
    expect(find.text('Minh'), findsOneWidget);
    expect(find.text('Bạn'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('circle-invite')));
    await tester.pump();
    expect(system.texts.single, contains(code));
    expect(system.texts.single, contains('Nhóm sáng'));
  });

  testWidgets('joining checks the code, then opens the group', (tester) async {
    final made = await circles.create(
      'token-owner',
      kind: CircleKind.group,
      name: 'IELTS',
    );
    await openTab(tester, 1);
    await tester.tap(find.byKey(const ValueKey('circle-join')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('circle-code')), 'ABC');
    await tester.tap(find.byKey(const ValueKey('circle-join-go')));
    await tester.pumpAndSettle();
    expect(find.text('Mã gồm 6 chữ và số, ví dụ K7M2QX.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('circle-code')), 'K7M2QX');
    await tester.tap(find.byKey(const ValueKey('circle-join-go')));
    await tester.pumpAndSettle();
    expect(
      find.text('Không tìm thấy nhóm hoặc lớp với mã này.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('circle-code')),
      made.code.toLowerCase(),
    );
    await tester.tap(find.byKey(const ValueKey('circle-join-go')));
    await tester.pumpAndSettle();
    expect(find.byType(CircleScreen), findsOneWidget);
    expect(circles.members[made.id], ['token-owner', _me]);
  });

  testWidgets('the owner removes a member; leaving closes the group', (
    tester,
  ) async {
    final made = await state.createCircle(CircleKind.group, 'G');
    await circles.join('token-x', made.code);
    circles.names['token-x'] = 'Xuân';
    await mount(tester, state, CircleScreen(circle: made));
    final person = find.ancestor(
      of: find.text('Xuân'),
      matching: find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key! as ValueKey).value}'.startsWith('circle-person-'),
      ),
    );
    final key = '${(tester.widget(person).key! as ValueKey).value}'
        .replaceFirst('circle-person-', '');
    await tester.tap(find.byKey(ValueKey('circle-remove-$key')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mời ra').last);
    await tester.pumpAndSettle();
    expect(circles.members[made.id], [_me]);
    expect(find.text('Xuân'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('circle-leave')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rời nhóm').last);
    await tester.pumpAndSettle();
    expect(circles.circles, isEmpty);
  });

  testWidgets('a teacher sets a deck and sees who finished or is late', (
    tester,
  ) async {
    final made = await state.createCircle(CircleKind.classroom, 'Lớp 6A');
    await circles.join('token-an', made.code);
    await circles.join('token-binh', made.code);
    circles
      ..names['token-an'] = 'An'
      ..names['token-binh'] = 'Bình';
    final deck = state.decks.first;
    await mount(tester, state, CircleScreen(circle: made));
    expect(find.byKey(const ValueKey('class-no-assignments')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('class-assign')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('assign-deck-${deck.id}')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assign-go')));
    await tester.pumpAndSettle();
    final a = circles.assignments[made.id]!.single;
    expect(a.title, deck.title);
    expect(a.due, '2026-11-08');
    expect(state.sharedDecks[deck.id], a.code);

    // An learned every word; Bình learned none and the due date passes.
    circles.learned['token-an'] = {...a.words};
    circles.assignments[made.id]![0] = (
      id: a.id,
      code: a.code,
      title: a.title,
      words: a.words,
      due: '2026-10-30',
    );
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await mount(tester, state, CircleScreen(circle: made));
    expect(find.text('Hạn 30 thg 10 · 1/2 học sinh đã xong'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('assignment-open-${a.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Xong'), findsOneWidget);
    expect(find.text('Trễ hạn'), findsOneWidget);
  });

  testWidgets('a student sees their own progress and studies the deck', (
    tester,
  ) async {
    const teacher = 'token-teacher';
    final source = state.decks.first;
    final code = await shares.publish(
      teacher,
      'd1',
      SharedDeck.of(source, 'en'),
    );
    final made = await circles.create(
      teacher,
      kind: CircleKind.classroom,
      name: 'Lớp 7B',
    );
    await circles.join(_me, made.code);
    await circles.assign(teacher, made.id, code, '2026-11-08');
    circles.learned[_me] = {source.words.first.word.toLowerCase()};
    final opened = <Deck>[];
    final before = state.decks.length;
    await openTab(tester, 2, opened: opened);
    await tester.tap(find.byKey(ValueKey('circle-${made.id}')));
    await tester.pumpAndSettle();
    expect(
      find.text('Hạn 8 thg 11 · 1/${source.words.length} từ'),
      findsOneWidget,
    );

    final study = find.byKey(
      ValueKey('assignment-study-${circles.assignments[made.id]!.single.id}'),
    );
    await tester.tap(study);
    await tester.pumpAndSettle();
    expect(state.decks, hasLength(before + 1));
    expect(opened.single.source, code);
    // Studying again opens the same copy.
    await tester.tap(study);
    await tester.pumpAndSettle();
    expect(state.decks, hasLength(before + 1));
    expect(opened, hasLength(2));
    expect(opened.last, same(opened.first));
  });
}
