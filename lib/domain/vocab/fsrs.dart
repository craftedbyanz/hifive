import 'dart:math' as math;

/// FSRS-5, the free spaced-repetition scheduler (open-spaced-repetition),
/// with its published default parameters.
///
/// A card's memory is a stability S (days until recall falls to 90%) and a
/// difficulty D (1 to 10). Recall decays as R(t) = (1 + F·t/S)^-0.5. A
/// review rated [again] lowers S (a lapse, never to zero); [hard], [good]
/// and [easy] raise it, more when the card was nearly forgotten. Ratings on
/// the same day only nudge S. The next review is due when R reaches the
/// target retention.
abstract final class Fsrs {
  static const again = 1, hard = 2, good = 3, easy = 4;

  /// FSRS-5 defaults.
  static const w = [
    0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, //
    1.54575, 0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, //
    2.9898, 0.51655, 0.6621,
  ];

  static const _decay = -0.5;
  static const _factor = 19 / 81;

  /// Share of reviews the learner should still remember when a card is due.
  static const retention = .9;
  static const maxDays = 36500;

  /// Recall probability after [days] with stability [s].
  static double recall(double days, double s) =>
      math.pow(1 + _factor * days / s, _decay).toDouble();

  /// Days until recall falls to [retention].
  static double interval(double s, [double retention = retention]) =>
      s / _factor * (math.pow(retention, 1 / _decay) - 1);

  static double initialStability(int g) => w[g - 1];

  static double initialDifficulty(int g) =>
      (w[4] - math.exp(w[5] * (g - 1)) + 1).clamp(1, 10);

  static double nextDifficulty(double d, int g) {
    final delta = -w[6] * (g - 3);
    final damped = d + delta * (10 - d) / 9;
    // Mean reversion towards the difficulty of a first "easy".
    return (w[7] * initialDifficulty(easy) + (1 - w[7]) * damped).clamp(1, 10);
  }

  /// Stability after a successful review ([hard], [good] or [easy]).
  static double recallStability(double d, double s, double r, int g) {
    final hardPenalty = g == hard ? w[15] : 1.0;
    final easyBonus = g == easy ? w[16] : 1.0;
    return s *
        (math.exp(w[8]) *
                (11 - d) *
                math.pow(s, -w[9]) *
                (math.exp(w[10] * (1 - r)) - 1) *
                hardPenalty *
                easyBonus +
            1);
  }

  /// Stability after a lapse; never more than before it.
  static double forgetStability(double d, double s, double r) => math.min(
    s,
    w[11] *
        math.pow(d, -w[12]) *
        (math.pow(s + 1, w[13]) - 1) *
        math.exp(w[14] * (1 - r)),
  );

  /// Stability after a review on the same day as the last one.
  static double shortTermStability(double s, int g) =>
      s * math.exp(w[17] * (g - 3 + w[18]));
}
