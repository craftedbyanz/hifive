import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/design/design.dart';
import '../../state/state.dart';
import '../../widgets/app_scroll.dart';
import '../../widgets/common.dart';
import '../profile/profile.dart';
import 'home_footer.dart';
import 'home_intro.dart';
import 'home_lower.dart';
import 'home_menu_motion.dart';
import 'home_menu_overlay.dart';
import 'home_painters.dart';
import 'mode_carousel.dart';

class HomeScreen extends StatefulWidget {
  final bool animateAmbient;
  const HomeScreen({super.key, this.animateAmbient = true});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final PageController _pages = PageController(
    viewportFraction: 349 / 375,
  );
  final _homeScroll = ScrollController();
  late final _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final _menuMotion = AnimationController(
    vsync: this,
    duration: MenuMotion.duration,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The reference keeps its ambient motion under Reduce Motion (physical
    // iPhone, 4 November 2026), so the clone does too.
    if (widget.animateAmbient) {
      if (!_ambient.isAnimating) _ambient.repeat();
    } else {
      _ambient.stop();
    }
  }

  void closeMenu() {
    _menuMotion.reverse().whenComplete(() {
      if (mounted && _menuMotion.status == AnimationStatus.dismissed) {
        setState(() => menu = false);
      }
    });
  }

  bool _scrolledAway = false;
  @override
  void initState() {
    super.initState();
    _refreshMenuBackdrop();
    _homeScroll.addListener(() {
      final next = _homeScroll.offset > 40;
      if (next != _scrolledAway && mounted) {
        setState(() => _scrolledAway = next);
      }
    });
  }

  int selected = 0;
  bool menu = false;
  final _backdropBoundary = GlobalKey();
  ui.Image? _menuBackdrop;
  bool _capturingBackdrop = false;
  void openMenu() {
    setState(() => menu = true);
    _menuMotion.forward(from: 0);
  }

  /// Keeps a ready image behind the menu. Capturing it while the menu opened
  /// stalled the first frames, so the rows appeared to jump open. The image is
  /// heavily blurred, so low resolution and a slightly old frame don't show.
  void _refreshMenuBackdrop() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _capturingBackdrop || menu) return;
      final boundary = _backdropBoundary.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      _capturingBackdrop = true;
      try {
        final image = await boundary.toImage();
        if (!mounted) {
          image.dispose();
          return;
        }
        final previous = _menuBackdrop;
        setState(() => _menuBackdrop = image);
        previous?.dispose();
      } catch (_) {
        // A pending first paint can skip this decorative snapshot.
      } finally {
        _capturingBackdrop = false;
      }
    });
  }

  @override
  void dispose() {
    _menuBackdrop?.dispose();
    _ambient.dispose();
    _menuMotion.dispose();
    _homeScroll.dispose();
    _pages.dispose();
    super.dispose();
  }

  void destination(Widget page) {
    _menuMotion.value = 0;
    setState(() => menu = false);
    go<void>(context, page);
  }

  void _toggleMenu(AppState state) {
    state.feedback.tap();
    if (menu) {
      closeMenu();
    } else {
      openMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), modes = state.modeOrder;
    final color = modes[selected.clamp(0, 2)].color;
    final bottom = MediaQuery.paddingOf(context).bottom + 8;
    return PopScope(
      canPop: !menu,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && menu) closeMenu();
      },
      child: Scaffold(
        body: Stack(
          children: [
            RepaintBoundary(
              key: _backdropBoundary,
              child: ColoredBox(
                color: D.background,
                child: Stack(
                  children: [
                    SafeArea(
                      top: false,
                      bottom: false,
                      child: NotificationListener<ScrollEndNotification>(
                        onNotification: (_) {
                          _refreshMenuBackdrop();
                          return false;
                        },
                        child: SingleChildScrollView(
                          key: const ValueKey('home-scroll'),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: HomeScrollPhysics(),
                          ),
                          controller: _homeScroll,
                          padding: EdgeInsets.only(
                            top: MediaQuery.paddingOf(context).top + 8,
                            bottom: 154,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HomeIntro(ambient: _ambient),
                              const SizedBox(height: 23),
                              ModeCarousel(
                                controller: _pages,
                                modes: modes,
                                selected: selected,
                                onPageChanged: (i) =>
                                    setState(() => selected = i),
                              ),
                              const SizedBox(height: 20),
                              ModeIndicator(
                                count: modes.length,
                                selected: selected,
                              ),
                              const SizedBox(height: 24),
                              const HomeLowerContent(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 66,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [.5, 1],
                              colors: [
                                Palette.statusBand.withValues(alpha: .92),
                                Palette.statusBand.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      right: 16,
                      child: Glass(
                        radius: BorderRadius.circular(14),
                        color: Palette.flagGlass.withValues(alpha: .72),
                        border: const BorderSide(
                          color: Palette.flagBorder,
                          width: .34,
                        ),
                        onTap: () => go<void>(context, const LanguageScreen()),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          child: SizedBox(
                            width: 34,
                            height: 22,
                            child: CustomPaint(painter: FlagPainter()),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 220,
                      child: HomeFooterGlow(
                        color: color,
                        scrolledAway: _scrolledAway,
                      ),
                    ),
                    Positioned(
                      bottom: bottom + 59,
                      left: 0,
                      right: 0,
                      child: _MenuFade(
                        motion: _menuMotion,
                        child: StreakPill(streak: state.streak),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: bottom,
                      child: _MenuFade(
                        motion: _menuMotion,
                        child: HomeBottomBar(
                          onMenu: () => _toggleMenu(state),
                          glass: _scrolledAway
                              ? Palette.glassNeutral
                              : glassTint(color),
                          edge: _scrolledAway
                              ? Palette.edgeNeutral
                              : glassEdge(color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (menu)
              Positioned.fill(
                child: HomeMenuOverlay(
                  motion: _menuMotion,
                  backdrop: _menuBackdrop,
                  onClose: closeMenu,
                  onSelect: destination,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fades and blurs the bottom controls as the menu takes over from them.
class _MenuFade extends StatelessWidget {
  final Animation<double> motion;
  final Widget child;
  const _MenuFade({required this.motion, required this.child});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    child: child,
    builder: (context, child) {
      final m = MenuMotion.at(
        motion.value,
        closing: motion.status == AnimationStatus.reverse,
      );
      return Transform.scale(
        scale: m.barScale,
        child: Opacity(
          opacity: m.barOpacity,
          child: ImageFiltered(
            enabled: m.barBlur > .05,
            imageFilter: ImageFilter.blur(sigmaX: m.barBlur, sigmaY: m.barBlur),
            child: child,
          ),
        ),
      );
    },
  );
}
