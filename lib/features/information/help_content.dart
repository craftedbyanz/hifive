import '../../l10n/l10n.dart';

/// The help articles on Home and in Help: app UI copy, the same for every
/// course, in the interface language.
const helpCount = 11;

/// The order articles show in: hifive's story, then the garden, listening
/// and community (8 to 10, which also say what is coming), then the rest.
/// Article numbers stay fixed, so links to them keep working.
const helpOrder = [0, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7];

/// The first explains the logo, the garden and the promise; the rest are
/// the features.
String helpTitle(AppLocalizations t, int index) => [
  t.helpTitle0,
  t.helpTitle1,
  t.helpTitle2,
  t.helpTitle3,
  t.helpTitle4,
  t.helpTitle5,
  t.helpTitle6,
  t.helpTitle7,
  t.helpTitle8,
  t.helpTitle9,
  t.helpTitle10,
][index];

/// After hifive's own first article, the reference's own Vietnamese text
/// (survey 93, 100–105), translated.
String helpBody(AppLocalizations t, int index) => [
  t.helpBody0,
  t.helpBody1,
  t.helpBody2,
  t.helpBody3,
  t.helpBody4,
  t.helpBody5,
  t.helpBody6,
  t.helpBody7,
  t.helpBody8,
  t.helpBody9,
  t.helpBody10,
][index];
