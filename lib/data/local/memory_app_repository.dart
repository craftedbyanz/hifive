import 'dart:async';
import 'dart:convert';

import '../../domain/repositories/app_repository.dart';

/// An old JSON blob held in memory, for import tests.
class MemoryAppRepository implements AppRepository {
  Map<String, dynamic>? data;
  @override
  Future<Map<String, dynamic>?> load() async => data == null
      ? null
      : Map<String, dynamic>.from(jsonDecode(jsonEncode(data)) as Map);
}
