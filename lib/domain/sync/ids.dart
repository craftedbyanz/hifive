import 'dart:math';

final _random = Random.secure();

/// A UUID version 7: 48 bits of Unix milliseconds, then random bits. Ids made
/// on different devices don't collide, and they sort roughly by creation.
String uuidV7(DateTime time, {Random? random}) {
  final r = random ?? _random;
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  final ms = time.millisecondsSinceEpoch;
  for (var i = 0; i < 6; i++) {
    bytes[i] = (ms >> (8 * (5 - i))) & 0xff;
  }
  bytes[6] = 0x70 | (bytes[6] & 0x0f);
  bytes[8] = 0x80 | (bytes[8] & 0x3f);
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}

/// The id of a saved dictionary word. It comes from the word itself, so
/// saving one word on two devices gives one card after sync.
String savedWordId(String word) => 'saved:${word.trim().toLowerCase()}';
