// Opens one listening source alone, for checking the YouTube player on a
// simulator or device without signing in. It plays the first episode at
// once and logs what the player reports:
//   flutter run -t tool/listen_preview.dart -d <device>
import 'package:flutter/material.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/core/design/design.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/vocab/vocab.dart';
import 'package:hifive/features/listening/listening.dart';
import 'package:hifive/l10n/l10n.dart';
import 'package:hifive/state/state.dart';

const _source = ListeningSource(
  id: 'reach-a1-podcast',
  title: 'A1 luyện nghe tiếng Anh cơ bản',
  channel: 'REACH',
  level: 'A1',
  description: '',
  playlistId: 'PLqYGyORvIQiz2lBQGAGxKcNoW6UAmmD7S',
  coverVideoId: 'F5QyH36MnVo',
  episodes: [
    Episode(id: 'F5QyH36MnVo', title: 'Bạn trai bị bệnh', seconds: 1216),
    Episode(id: 'CzXqkWprDjY', title: 'Ăn chay', seconds: 1389),
    Episode(id: 'WV0LNIvCfvE', title: 'Thói quen', seconds: 1084),
  ],
);

/// Plays as soon as it loads and logs every report.
class _LoggingPlayer extends YouTubeListenPlayer {
  var _said = '';
  _LoggingPlayer() {
    addListener(() {
      final now =
          'playing=$playing t=${position.toStringAsFixed(1)} '
          'd=${duration.toStringAsFixed(0)} rate=$rate';
      if (now != _said) debugPrint('listen-preview: ${_said = now}');
    });
  }

  @override
  void load(String video, {int start = 0, bool autoplay = false}) {
    debugPrint('listen-preview: load $video start=$start');
    super.load(video, start: start, autoplay: true);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AppScope(
      state: createAppState(store: MemoryRecordStore()),
      child: MaterialApp(
        theme: D.theme,
        locale: const Locale('vi'),
        supportedLocales: supportedAppLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const ListenScreen(source: _source, player: _LoggingPlayer.new),
      ),
    ),
  );
}
