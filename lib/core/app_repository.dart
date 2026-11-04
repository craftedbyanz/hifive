import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AppRepository {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> data);
}

class LocalAppRepository implements AppRepository {
  final SharedPreferencesAsync preferences;
  LocalAppRepository({SharedPreferencesAsync? preferences})
    : preferences = preferences ?? SharedPreferencesAsync();
  @override
  Future<Map<String, dynamic>?> load() async {
    final json = await preferences.getString('hifive.local.v1');
    return json == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(json) as Map);
  }

  @override
  Future<void> save(Map<String, dynamic> data) =>
      preferences.setString('hifive.local.v1', jsonEncode(data));
}

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
