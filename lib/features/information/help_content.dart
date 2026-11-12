import '../../l10n/l10n.dart';

/// The help articles on Home and in Help: app UI copy, the same for every
/// course, in the interface language.
const helpCount = 7;

String helpTitle(AppLocalizations t, int index) => [
  t.helpTitle1,
  t.helpTitle2,
  t.helpTitle3,
  t.helpTitle4,
  t.helpTitle5,
  t.helpTitle6,
  t.helpTitle7,
][index];

/// The reference's own Vietnamese text (survey 93, 100–105), translated.
String helpBody(AppLocalizations t, int index) => [
  t.helpBody1,
  t.helpBody2,
  t.helpBody3,
  t.helpBody4,
  t.helpBody5,
  t.helpBody6,
  t.helpBody7,
][index];
