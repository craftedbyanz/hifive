import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../information/information.dart';
import 'collection_screen.dart';
import 'conversation_guide.dart';
import 'generator_screen.dart';

part 'chat_settings_popover.dart';
part 'topic_controls.dart';
part 'topic_tile.dart';

class TopicScreen extends StatefulWidget {
  final StudyMode mode;
  const TopicScreen({super.key, required this.mode});
  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  late Future<List<String>> categories = _loadCategories();
  String? category;
  int refresh = 0;
  Future<List<Topic>>? topics;

  bool popoverOpen = false;

  Future<List<String>> _loadCategories() async {
    final state = AppScope.read(context);
    final list = await state.lessons.categories(state.language, widget.mode);
    if (mounted && list.isNotEmpty && category == null) {
      setState(() {
        category = list.first;
        topics = _loadTopics();
      });
    }
    return list;
  }

  /// A failure is shown by the grid's [FutureBuilder], which may subscribe a
  /// frame later, so the error is marked handled here.
  Future<List<Topic>> _loadTopics() {
    final state = AppScope.read(context);
    return state.lessons.topics(
      state.language,
      widget.mode,
      category!,
      refresh: refresh,
    )..ignore();
  }

  void _select(String c) => setState(() {
    category = c;
    refresh = 0;
    topics = _loadTopics();
  });

  void _refresh() => setState(() {
    refresh++;
    topics = _loadTopics();
  });

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Content scrolls under the floating back and AI buttons and fades out
    // beneath the status bar, as measured on the physical iPhone.
    return Scaffold(
      backgroundColor: D.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<List<String>>(
              future: categories,
              builder: (context, snapshot) {
                Widget below(Widget child) => Padding(
                  padding: EdgeInsets.only(top: top + 60),
                  child: child,
                );
                if (snapshot.hasError) {
                  return below(
                    ErrorView(
                      onRetry: () => setState(() {
                        categories = _loadCategories();
                      }),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data!.isEmpty) {
                  return below(EmptyView(title: context.t.noCategories));
                }
                if (snapshot.connectionState != ConnectionState.done ||
                    topics == null) {
                  return below(const LoadingView());
                }
                return _content(snapshot.data!, top);
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 3,
            child: const IgnorePointer(child: _StatusFade()),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: top,
            child: Row(
              children: [
                HeaderRoundButton(
                  icon: CupertinoIcons.back,
                  iconSize: 31,
                  label: context.t.back,
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                _AiButton(
                  onTap: () => go<void>(context, GeneratorScreen(mode: mode)),
                ),
              ],
            ),
          ),
          if (mode == StudyMode.conversation) ...[
            if (popoverOpen)
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('chat-settings-scrim'),
                  onTap: () => setState(() => popoverOpen = false),
                  child: ColoredBox(color: D.ink.withValues(alpha: .25)),
                ),
              ),
            if (popoverOpen)
              Positioned(
                left: 16,
                right: 16,
                bottom: bottom + 16,
                child: _ChatSettingsPopover(
                  onClose: () => setState(() => popoverOpen = false),
                ),
              )
            else ...[
              // Measured on the physical iPhone: a 50 pt circle whose centre
              // sits 24.7 pt from the right and 20.3 pt above the inset.
              Positioned(
                right: 24.7,
                bottom: bottom + 20.3,
                child: _SettingsButton(
                  onTap: () => setState(() {
                    popoverOpen = true;
                    AppScope.read(context).dismissChatTip();
                  }),
                ),
              ),
              if (!AppScope.of(context).chatTipSeen)
                Positioned(
                  left: 10,
                  bottom: bottom - .3,
                  child: _ChatSettingsTip(
                    onClose: () => AppScope.read(context).dismissChatTip(),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _content(List<String> categoryList, double top) {
    final mode = widget.mode;
    final suggested = category == categoryList.first;
    final title = D.text(
      38,
      weight: FontWeight.w800,
      height: 1.04,
      spacing: -2,
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, top + 69.3, 24, 0),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8.7),
                  Text(context.t.createModeCaps, style: CapsLabel.style),
                ],
              ),
              const SizedBox(height: 11.2),
              Text(mode.headline(context), style: title),
              Text(
                mode.accentTitle(context),
                style: title.copyWith(
                  color: mode == StudyMode.grammar
                      ? Palette.grammarAccent
                      : mode == StudyMode.writing
                      ? Palette.categoryInactive
                      : D.blue,
                ),
              ),
              const SizedBox(height: 27),
              CapsLabel(context.t.categoriesCaps),
              const SizedBox(height: 19.1),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 41,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 22.7),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: categoryList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 11.6),
              itemBuilder: (_, i) => _CategoryChip(
                label: categoryList[i],
                selected: categoryList[i] == category,
                onTap: () => _select(categoryList[i]),
              ),
            ),
          ),
        ),
        FutureBuilder<List<Topic>>(
          future: topics,
          builder: (context, snapshot) {
            final loaded = snapshot.connectionState == ConnectionState.done;
            final list = snapshot.data ?? const <Topic>[];
            final endless = mode == StudyMode.grammar && suggested;
            final count = list.length + (endless ? 1 : 0);
            return SliverMainAxisGroup(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 35.3, 24, 16.2),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: suggested ? 20.5 : 24.3,
                      child: Row(
                        children: [
                          Expanded(
                            child: CapsLabel(
                              suggested
                                  ? context.t.yourTopicsCaps
                                  : context.t.relatedTopicsCaps,
                            ),
                          ),
                          if (!suggested)
                            _RefreshPill(onTap: loaded ? _refresh : null)
                          else if (loaded && !snapshot.hasError)
                            _CountPill(context.t.topicsCount(count)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!loaded)
                  const SliverToBoxAdapter(child: LoadingView())
                else if (snapshot.hasError)
                  SliverToBoxAdapter(
                    child: ErrorView(
                      onRetry: () => setState(() {
                        topics = _loadTopics();
                      }),
                    ),
                  )
                else if (count == 0)
                  SliverToBoxAdapter(
                    child: EmptyView(
                      title: context.t.noTopics,
                      subtitle: context.t.noTopicsBody,
                      icon: Icons.auto_awesome_rounded,
                    ),
                  )
                else
                  SliverPadding(
                    // The last row stops 154 pt above the screen's bottom edge.
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 154),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 11,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 160,
                          ),
                      itemCount: count,
                      itemBuilder: (_, index) {
                        if (endless && index == 0) return const _EndlessTile();
                        final t = list[index - (endless ? 1 : 0)];
                        return TopicTile(
                          topic: t,
                          onTap: () =>
                              go<void>(context, CollectionScreen(topic: t)),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
