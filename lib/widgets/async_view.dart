import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/design/design.dart';
import 'common.dart';

/// Centered spinner with an optional caption, for content still loading.
class LoadingView extends StatelessWidget {
  final String label;
  const LoadingView({super.key, this.label = 'Đang tải...'});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 9),
          const SizedBox(width: 10),
          Text(label, style: D.text(14, color: D.muted)),
        ],
      ),
    ),
  );
}

/// A failed request, with a retry button. Shown for network and AI errors.
class ErrorView extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback onRetry;
  const ErrorView({
    super.key,
    required this.onRetry,
    this.title = 'Không tải được nội dung',
    this.subtitle = 'Kiểm tra kết nối mạng rồi thử lại.',
  });
  @override
  Widget build(BuildContext context) => EmptyView(
    title: title,
    subtitle: subtitle,
    icon: Icons.wifi_off_rounded,
    action: SizedBox(
      width: 180,
      child: ActionButton(
        'Thử lại',
        key: const ValueKey('async-retry'),
        onTap: onRetry,
        icon: Icons.refresh_rounded,
      ),
    ),
  );
}

/// Runs [load] and shows loading, error (with retry), empty or [builder].
/// Changing [loadKey] starts a new load.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Object? loadKey;
  final String loadingLabel;

  /// Shown while loading instead of the spinner, such as a skeleton.
  final Widget? loading;
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loadKey,
    this.loadingLabel = 'Đang tải...',
    this.loading,
  });
  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> future = _start();

  /// Marks the error as handled here; [FutureBuilder] still receives it.
  Future<T> _start() => widget.load()..ignore();
  @override
  void didUpdateWidget(AsyncView<T> old) {
    super.didUpdateWidget(old);
    if (old.loadKey != widget.loadKey) future = _start();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return widget.loading ?? LoadingView(label: widget.loadingLabel);
      }
      if (snapshot.hasError) {
        return ErrorView(
          onRetry: () => setState(() {
            future = _start();
          }),
        );
      }
      final data = snapshot.data as T;
      if (widget.isEmpty?.call(data) ?? false) {
        return widget.empty ??
            const EmptyView(
              title: 'Chưa có nội dung',
              subtitle: 'Hãy thử danh mục khác hoặc làm mới.',
            );
      }
      return widget.builder(context, data);
    },
  );
}
