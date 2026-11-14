import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// What the listening screen asks of a video player: show a video, report
/// where it stands, and take the learner's controls. The app plays YouTube
/// in a web view ([YouTubeListenPlayer]); tests pass a stand-in.
abstract class ListenPlayer extends ChangeNotifier {
  /// Seconds into the video and its length; 0 until the video says.
  double position = 0, duration = 0;

  /// The playback speed.
  double rate = 1;
  bool playing = false;

  /// Called when the video plays to its end.
  VoidCallback? onEnded;

  /// The video itself, 16:9.
  Widget view();

  /// Shows [video], from [start] seconds, playing at once when [autoplay].
  void load(String video, {int start = 0, bool autoplay = false});

  /// Shows a whole playlist in YouTube's own player, for sources without
  /// a list of episodes.
  void loadPlaylist(String playlist);

  void play();
  void pause();
  void seekTo(double seconds);
  void setRate(double rate);

  void toggle() => playing ? pause() : play();
}

/// YouTube's own embedded player in a web view.
///
/// It loads YouTube's embed page directly, with a referrer, as YouTube asks
/// of embedding apps; the `youtube_player_iframe` package drew only a black
/// box here (13 November 2026). A script added to the page reports the
/// video element's time, length, state and speed over the `HifivePlayer`
/// channel and takes the controls through YouTube's player. Videos play
/// inline; a link out of the embed opens the YouTube app.
class YouTubeListenPlayer extends ListenPlayer {
  /// Sent as the referrer; YouTube refuses embeds without one.
  static const referrer = 'https://hifive-api.hifive-worker.workers.dev';

  late final WebViewController _web = _build();
  bool _autoplay = false;

  static Uri embedUrl(String path, [Map<String, String> query = const {}]) =>
      Uri.https('www.youtube.com', path, {
        'playsinline': '1',
        'rel': '0',
        ...query,
      });

  WebViewController _build() {
    final params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const {},
          )
        : const PlatformWebViewControllerCreationParams();
    return WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('HifivePlayer', onMessageReceived: _receive)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _web.runJavaScript(_bridge),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null ||
                !request.isMainFrame ||
                uri.path.startsWith('/embed') ||
                !uri.host.endsWith('youtube.com')) {
              return NavigationDecision.navigate;
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      );
  }

  void _receive(JavaScriptMessage message) {
    final m = jsonDecode(message.message) as Map<String, dynamic>;
    final type = m['type'] as String;
    final t = (m['t'] as num).toDouble(), d = (m['d'] as num).toDouble();
    final isPlaying = m['playing'] as bool;
    final r = (m['rate'] as num).toDouble();
    if (type == 'ready' && _autoplay) {
      _autoplay = false;
      play();
    }
    if (t != position || d != duration || isPlaying != playing || r != rate) {
      position = t;
      duration = d.isFinite ? d : 0;
      playing = isPlaying;
      rate = r;
      notifyListeners();
    }
    if (type == 'ended') onEnded?.call();
  }

  void _show(Uri url) {
    position = 0;
    duration = 0;
    playing = false;
    notifyListeners();
    _web.loadRequest(url, headers: const {'Referer': referrer});
  }

  @override
  Widget view() => AspectRatio(
    aspectRatio: 16 / 9,
    child: ColoredBox(
      color: Colors.black,
      child: WebViewWidget(controller: _web),
    ),
  );

  @override
  void load(String video, {int start = 0, bool autoplay = false}) {
    _autoplay = autoplay;
    _show(
      embedUrl('/embed/$video', {
        if (start > 0) 'start': '$start',
        if (autoplay) 'autoplay': '1',
      }),
    );
    position = start.toDouble();
  }

  @override
  void loadPlaylist(String playlist) =>
      _show(embedUrl('/embed/videoseries', {'list': playlist}));

  void _call(String js) =>
      _web.runJavaScript('window.hifive && window.hifive.$js;');

  @override
  void play() => _call('play()');

  @override
  void pause() => _call('pause()');

  @override
  void seekTo(double seconds) {
    position = seconds;
    notifyListeners();
    _call('seek($seconds)');
  }

  @override
  void setRate(double rate) {
    this.rate = rate;
    notifyListeners();
    _call('rate($rate)');
  }

  /// Hooks the page's video element, once per page.
  static const _bridge = '''
(function () {
  if (window.hifive) return;
  function player() { return document.getElementById('movie_player'); }
  function video() { return document.querySelector('video'); }
  function send(type) {
    var v = video();
    if (!v) return;
    HifivePlayer.postMessage(JSON.stringify({
      type: type,
      t: v.currentTime || 0,
      d: isFinite(v.duration) ? v.duration : 0,
      playing: !v.paused && !v.ended,
      rate: v.playbackRate || 1
    }));
  }
  window.hifive = {
    play: function () {
      var p = player();
      if (p && p.playVideo) p.playVideo(); else if (video()) video().play();
    },
    pause: function () {
      var p = player();
      if (p && p.pauseVideo) p.pauseVideo(); else if (video()) video().pause();
    },
    seek: function (s) {
      var p = player();
      if (p && p.seekTo) p.seekTo(s, true); else if (video()) video().currentTime = s;
    },
    rate: function (r) {
      var p = player();
      if (p && p.setPlaybackRate) p.setPlaybackRate(r);
      if (video()) video().playbackRate = r;
    }
  };
  function hook() {
    var v = video();
    if (!v) { setTimeout(hook, 250); return; }
    ['play', 'playing', 'pause', 'ended', 'ratechange', 'seeked', 'loadedmetadata']
      .forEach(function (e) { v.addEventListener(e, function () { send(e); }); });
    setInterval(function () { send('tick'); }, 1000);
    send('ready');
  }
  hook();
})();
''';
}
