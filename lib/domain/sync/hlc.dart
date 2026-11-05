/// A hybrid logical clock stamp: wall-clock milliseconds, a counter for
/// stamps within the same millisecond, and the device that made it. Stamps
/// order writes across devices even when their clocks disagree, and the
/// string form sorts in the same order as [compareTo].
class Hlc implements Comparable<Hlc> {
  final int millis, counter;
  final String node;
  const Hlc(this.millis, this.counter, this.node);

  static const zero = Hlc(0, 0, '');

  static Hlc parse(String text) {
    final parts = text.split(':');
    if (parts.length != 3) throw FormatException('Not an HLC stamp', text);
    return Hlc(int.parse(parts[0]), int.parse(parts[1], radix: 36), parts[2]);
  }

  @override
  int compareTo(Hlc other) {
    if (millis != other.millis) return millis.compareTo(other.millis);
    if (counter != other.counter) return counter.compareTo(other.counter);
    return node.compareTo(other.node);
  }

  bool operator >(Hlc other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) => other is Hlc && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(millis, counter, node);

  @override
  String toString() =>
      '${millis.toString().padLeft(15, '0')}:'
      '${counter.toRadixString(36).padLeft(4, '0')}:$node';
}

/// Hands out [Hlc] stamps for one device. Each stamp is greater than every
/// stamp this clock made or [receive]d before, even if the wall clock moves
/// backwards.
class HlcClock {
  final String node;
  final DateTime Function() now;
  Hlc _last;
  HlcClock({required this.node, required this.now, Hlc? last})
    : _last = last ?? Hlc.zero;

  Hlc get last => _last;

  /// A stamp for a local write.
  Hlc tick() {
    final wall = now().millisecondsSinceEpoch;
    _last = wall > _last.millis
        ? Hlc(wall, 0, node)
        : Hlc(_last.millis, _last.counter + 1, node);
    return _last;
  }

  /// Moves past a stamp from another device, so later local writes win
  /// over it.
  void receive(Hlc remote) {
    if (remote > _last) _last = Hlc(remote.millis, remote.counter, node);
  }
}
