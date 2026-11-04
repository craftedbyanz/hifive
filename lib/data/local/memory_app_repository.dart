import 'dart:async';
import 'dart:convert';

import '../../domain/repositories/app_repository.dart';

class MemoryAppRepository implements AppRepository {
  Map<String, dynamic>? data;
  @override
  Future<Map<String, dynamic>?> load() async => data == null
      ? null
      : Map<String, dynamic>.from(jsonDecode(jsonEncode(data)) as Map);
  @override
  Future<void> save(Map<String, dynamic> value) async {
    data = Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  }
}
