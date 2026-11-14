import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/listening/listening.dart';

ListenDay _day(
  String video,
  String day, {
  int position = 0,
  int heard = 0,
  bool done = false,
  int hour = 9,
}) => ListenDay(
  video: video,
  day: day,
  position: position,
  heard: heard,
  done: done,
  at: DateTime.parse('$day 0$hour:00:00'),
);

void main() {
  test('a day record keeps its video and day through storage', () {
    final d = _day('a-b@c', '2026-11-14', position: 90, heard: 80, done: true);
    final back = ListenDay.fromJson(d.id, d.toJson());
    expect(back.video, 'a-b@c');
    expect(back.day, '2026-11-14');
    expect((back.position, back.heard, back.done), (90, 80, true));
    expect(back.at, d.at);
  });

  test('progress takes the latest position and stays done once done', () {
    final log = ListenLog([
      _day('v', '2026-11-12', position: 1200, done: true),
      _day('v', '2026-11-14', position: 30),
      _day('w', '2026-11-13', position: 70),
    ]);
    final v = log.progress['v']!;
    expect(v.position, 30);
    expect(v.done, isTrue);
    expect(log.progress['w']!.position, 70);
  });

  test('a day counts for the streak from a minute heard, across videos', () {
    final log = ListenLog([
      _day('v', '2026-11-13', heard: 40),
      _day('w', '2026-11-13', heard: 25),
      _day('v', '2026-11-14', heard: 59),
    ]);
    expect(log.heardOn('2026-11-13'), 65);
    expect(log.studyDays, {'2026-11-13'});
  });
}
