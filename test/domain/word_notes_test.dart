import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/vocab/vocab.dart';

/// A card last reviewed [daysAgo] days before [now] with [stability].
FlashWord studied(
  String word,
  DateTime now, {
  double daysAgo = 2,
  double stability = 3,
}) => FlashWord(id: word, word: word, meaning: 'nghĩa $word', status: 'review')
  ..stability = stability
  ..lastReview = now.subtract(Duration(hours: (daysAgo * 24).round()));

FlashWord fresh(String word) =>
    FlashWord(id: word, word: word, meaning: 'nghĩa $word');

void main() {
  final morning = DateTime(2026, 11, 16, 6);

  test('ten times a day, evenly from 08:00 to 21:30', () {
    final times = wordNoteTimes(DateTime(2026, 11, 16));
    expect(times, hasLength(10));
    expect(times.first, DateTime(2026, 11, 16, 8));
    expect(times.last, DateTime(2026, 11, 16, 21, 30));
    expect(times[1], DateTime(2026, 11, 16, 9, 30));
  });

  test('no note lands on the daily reminder', () {
    final times = wordNoteTimes(
      DateTime(2026, 11, 16),
      reminder: (hour: 20, minute: 0),
    );
    // 20:00 moves half an hour before the reminder.
    expect(times, contains(DateTime(2026, 11, 16, 19, 30)));
    expect(times, isNot(contains(DateTime(2026, 11, 16, 20))));
  });

  test('the weakest words come first, settled ones are left out', () {
    final weak = studied('weak', morning, daysAgo: 10, stability: 2);
    final middling = studied('middling', morning, daysAgo: 3, stability: 4);
    final settled = studied('settled', morning, daysAgo: 1, stability: 60);
    final notes = planWordNotes(
      words: [settled, middling, weak],
      now: morning,
      days: 1,
    );
    expect(notes.map((n) => n.word.word), ['weak', 'middling']);
    expect(notes.first.at, DateTime(2026, 11, 16, 8));
  });

  test("new words come only from the learner's own decks, three a day", () {
    final own = [for (var i = 0; i < 5; i++) fresh('own$i')];
    final catalog = fresh('catalog');
    final notes = planWordNotes(
      words: [...own, catalog],
      now: morning,
      chosen: {for (final w in own) w.word},
      days: 1,
    );
    // With no studied words, the room left goes to more of their own words.
    expect(notes.map((n) => n.word.word), isNot(contains('catalog')));
    expect(notes, hasLength(5));

    final many = [for (var i = 0; i < 12; i++) studied('s$i', morning)];
    final mixed = planWordNotes(
      words: [...many, ...own],
      now: morning,
      chosen: {for (final w in own) w.word},
      days: 1,
    );
    expect(mixed, hasLength(10));
    expect(mixed.where((n) => n.word.status == 'new'), hasLength(3));
  });

  test('no word twice a day, and a fresh set the next day', () {
    final words = [for (var i = 0; i < 20; i++) studied('w$i', morning)];
    final notes = planWordNotes(words: words, now: morning);
    expect(notes, hasLength(20));
    final first = notes.where((n) => n.at.day == 16).map((n) => n.word.word);
    final second = notes.where((n) => n.at.day == 17).map((n) => n.word.word);
    expect(first.toSet(), hasLength(10));
    expect(first.toSet().intersection(second.toSet()), isEmpty);
  });

  test('times already past today are skipped', () {
    final words = [for (var i = 0; i < 20; i++) studied('w$i', morning)];
    final noon = DateTime(2026, 11, 16, 12, 45);
    final notes = planWordNotes(words: words, now: noon, days: 1);
    expect(notes.every((n) => n.at.isAfter(noon)), isTrue);
    expect(notes.first.at, DateTime(2026, 11, 16, 14));
  });

  test('a note reads like a dictionary line', () {
    final w = FlashWord(
      id: 'c',
      word: 'catch',
      meaning: 'sự bắt, sự nắm lấy',
      phonetic: '/kætʃ/',
    );
    final text = wordNoteText(w);
    expect(text.title, 'catch  /kætʃ/  (n)');
    expect(text.body, 'sự bắt, sự nắm lấy');
    expect(posShort('ADJECTIVE'), 'adj');
  });
}
