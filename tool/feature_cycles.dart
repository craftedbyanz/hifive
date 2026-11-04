// Fails when features import each other in a cycle, directly or through other
// features. Usage: dart run tool/feature_cycles.dart (from the repo root).
import 'dart:io';

final _import = RegExp(r'''^import\s+'\.\./([a-z_]+)/''', multiLine: true);

void main() {
  final root = Directory('lib/features');
  final graph = <String, Set<String>>{};
  for (final area in root.listSync().whereType<Directory>()) {
    final name = area.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    final deps = graph.putIfAbsent(name, () => {});
    for (final file in area.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final m in _import.allMatches(file.readAsStringSync())) {
        if (m[1] != name) deps.add(m[1]!);
      }
    }
  }

  final cycles = <String>{};
  void visit(String node, List<String> path) {
    final at = path.indexOf(node);
    if (at >= 0) {
      final loop = path.sublist(at);
      // Rotate so the same cycle is reported once, from its smallest name.
      final start = loop.indexOf((loop.toList()..sort()).first);
      final ordered = [...loop.sublist(start), ...loop.sublist(0, start)];
      cycles.add([...ordered, ordered.first].join(' -> '));
      return;
    }
    for (final next in graph[node] ?? const <String>{}) {
      visit(next, [...path, node]);
    }
  }

  for (final node in graph.keys) {
    visit(node, []);
  }
  if (cycles.isEmpty) return;
  stderr.writeln('Rule broken: features import each other in a cycle');
  for (final cycle in cycles.toList()..sort()) {
    stderr.writeln('  $cycle');
  }
  exitCode = 1;
}
