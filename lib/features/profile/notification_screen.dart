import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
import '../../core/services/screen_lock.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'settings_kit.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  static final _boxDecoration = ShapeDecoration(
    color: Palette.settingsPage,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Palette.settingsPanel),
    ),
  );

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

/// Reads whether iOS lets hifive notify when the page opens and each time
/// the learner comes back from Settings, so the switch and the push row
/// show what will really happen.
class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  var _access = NotificationAccess.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final access = await ScreenLock.access();
    if (mounted && access != _access) setState(() => _access = access);
  }

  /// Asks iOS when it has never been asked; otherwise only Settings can
  /// change the answer.
  Future<void> _allowOrOpenSettings(AppState s) async {
    if (_access == NotificationAccess.unasked) {
      await ScreenLock.askPermission();
      return _refresh();
    }
    final shown = await s.system.openAppSettings();
    if (!shown && mounted) toast(context, context.t.cannotOpenSettings);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final unasked = _access == NotificationAccess.unasked;
    final today = s.now();
    return SettingsPage(
      title: context.t.profileNotifications,
      background: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 132, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LockScreenArt(
            date: DateFormat.MMMMEEEEd(context.t.localeName).format(today),
          ),
          const SizedBox(height: 24),
          _ReminderCard(state: s, access: _access, onAsked: _refresh),
          const SizedBox(height: 12),
          _WordNotesCard(state: s, access: _access, onAsked: _refresh),
          const SizedBox(height: 16),
          Container(
            height: 76,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            decoration: NotificationScreen._boxDecoration,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Palette.pushDisc,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.bell_fill,
                    size: 23,
                    color: Palette.pushBell,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t.pushNotifications,
                        style: D.text(
                          14.8,
                          weight: FontWeight.w700,
                          height: 20 / 14.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        switch (_access) {
                          NotificationAccess.allowed => context.t.pushAllowed,
                          NotificationAccess.unasked => context.t.pushUnasked,
                          _ => context.t.notEnabledInSettings,
                        },
                        key: const ValueKey('push-status'),
                        style: D.text(
                          12.5,
                          color: Palette.settingsMuted,
                          height: 17 / 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                PressFade(
                  key: const ValueKey('notification-settings'),
                  onTap: () => _allowOrOpenSettings(s),
                  child: Container(
                    width: 70,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Palette.pushPill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      unasked ? context.t.pushAllow : context.t.settingsAction,
                      style: D.text(
                        12.5,
                        weight: FontWeight.w600,
                        color: Palette.ctaGreen,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 21, 20, 21),
            decoration: NotificationScreen._boxDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sparkles,
                      size: 19,
                      color: Palette.smartSpark,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      context.t.smartReminders,
                      style: D.text(
                        14.8,
                        weight: FontWeight.w700,
                        height: 20 / 14.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  context.t.smartRemindersBody,
                  style: D.text(
                    13,
                    color: Palette.settingsMuted,
                    height: 20.5 / 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A lock screen drawn from vector shapes: the reference's wallpaper image and
/// glass numerals are not bundled.
class _LockScreenArt extends StatelessWidget {
  final String date;
  const _LockScreenArt({required this.date});
  @override
  Widget build(BuildContext context) => ClipRSuperellipse(
    borderRadius: BorderRadius.circular(38),
    child: SizedBox(
      height: 380,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _WallpaperPainter()),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 56,
            child: Text(
              date,
              textAlign: TextAlign.center,
              style: D.text(
                16,
                weight: FontWeight.w600,
                color: Colors.white.withValues(alpha: .88),
                height: 22 / 16,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 96,
            child: Center(
              child: Transform.scale(
                scaleX: .85,
                scaleY: 1.32,
                child: Stack(
                  children: [
                    Text(
                      '09:00',
                      style: D.text(
                        84,
                        weight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: .34),
                        height: 92 / 84,
                      ),
                    ),
                    Text(
                      '09:00',
                      style: D
                          .text(84, weight: FontWeight.w800, height: 92 / 84)
                          .copyWith(
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2
                              ..color = Colors.white.withValues(alpha: .82),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 26,
            right: 26,
            top: 254,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 245,
            child: Container(
              height: 74,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: Palette.sheetEdge.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Flower(size: 28, strong: true),
                  const SizedBox(width: 22),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (width, height) in const [
                        (80.0, 10.0),
                        (159.0, 7.0),
                        (99.0, 7.0),
                      ])
                        Container(
                          width: width,
                          height: height,
                          margin: const EdgeInsets.symmetric(vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .85),
                            borderRadius: BorderRadius.circular(height / 2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WallpaperPainter extends CustomPainter {
  const _WallpaperPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Palette.wallMist);
    canvas.drawCircle(
      Offset(size.width * .78, -size.height * .12),
      size.width * .62,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.wallBlue, Palette.wallDeep],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(-size.width * .1, size.height * 1.02),
      size.width * .82,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.wallTeal, Palette.wallMint],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * .98, size.height * .92),
      size.width * .46,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.96, .84),
          radius: .62,
          colors: [
            Palette.wallBlue.withValues(alpha: .55),
            Palette.wallBlue.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WallpaperPainter oldDelegate) => false;
}

/// The daily review reminder: on or off, and the time, picked on a wheel.
/// While notifications are off in Settings the switch shows off and says
/// why, since no reminder could arrive.
class _ReminderCard extends StatelessWidget {
  final AppState state;
  final NotificationAccess access;
  final VoidCallback onAsked;
  const _ReminderCard({
    required this.state,
    required this.access,
    required this.onAsked,
  });

  bool get _blocked => state.reminderOn && access == NotificationAccess.denied;

  Future<void> _pickTime(BuildContext context) async {
    final parts = state.reminderTime.split(':');
    var picked = DateTime(2026, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    await sheet<void>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.t.reminderPickTime,
              style: D.text(16, weight: FontWeight.w700),
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                key: const ValueKey('reminder-wheel'),
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                minuteInterval: 5,
                initialDateTime: DateTime(
                  2026,
                  1,
                  1,
                  picked.hour,
                  picked.minute - picked.minute % 5,
                ),
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
            PressFade(
              key: const ValueKey('reminder-done'),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.t.reminderDone,
                  style: D.text(16, weight: FontWeight.w700, color: D.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    state.setReminder(
      time:
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: NotificationScreen._boxDecoration,
    child: Row(
      children: [
        Expanded(
          child: PressFade(
            key: const ValueKey('reminder-time'),
            onTap: () => _pickTime(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.reminderTitle,
                  style: D.text(14.8, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  context.t.reminderAt(state.reminderTime),
                  style: D.text(12.5, color: Palette.settingsMuted),
                ),
                if (_blocked) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.t.reminderBlocked,
                    key: const ValueKey('reminder-blocked'),
                    style: D.text(12.5, color: Palette.wrong),
                  ),
                ],
              ],
            ),
          ),
        ),
        CupertinoSwitch(
          key: const ValueKey('reminder-toggle'),
          value: state.reminderOn && !_blocked,
          activeTrackColor: D.green,
          onChanged: (on) async {
            if (!on) return state.setReminder(on: false);
            // Turned on only if iOS lets hifive send notifications.
            final t = context.t;
            final allowed = await ScreenLock.askPermission();
            onAsked();
            if (allowed == false) {
              if (context.mounted) toast(context, t.reminderDenied);
              return;
            }
            state.setReminder(on: true);
          },
        ),
      ],
    ),
  );
}

/// Word notes (`WordNotes`): on or off. Like the reminder, the switch shows
/// off and says why while notifications are off in Settings.
class _WordNotesCard extends StatelessWidget {
  final AppState state;
  final NotificationAccess access;
  final VoidCallback onAsked;
  const _WordNotesCard({
    required this.state,
    required this.access,
    required this.onAsked,
  });

  bool get _blocked => state.wordNotesOn && access == NotificationAccess.denied;

  static String _clock(int minutes) =>
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: NotificationScreen._boxDecoration,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.wordNotesTitle,
                style: D.text(14.8, weight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                context.t.wordNotesBody(
                  WordNotes.perDay,
                  _clock(WordNotes.firstMinute),
                  _clock(WordNotes.lastMinute),
                ),
                style: D.text(12.5, color: Palette.settingsMuted),
              ),
              if (_blocked) ...[
                const SizedBox(height: 4),
                Text(
                  context.t.reminderBlocked,
                  key: const ValueKey('word-notes-blocked'),
                  style: D.text(12.5, color: Palette.wrong),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        CupertinoSwitch(
          key: const ValueKey('word-notes-toggle'),
          value: state.wordNotesOn && !_blocked,
          activeTrackColor: D.green,
          onChanged: (on) async {
            if (!on) return state.setWordNotes(false);
            final t = context.t;
            final allowed = await ScreenLock.askPermission();
            onAsked();
            if (allowed == false) {
              if (context.mounted) toast(context, t.reminderDenied);
              return;
            }
            state.setWordNotes(true);
          },
        ),
      ],
    ),
  );
}
