import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/app_repository.dart';

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
