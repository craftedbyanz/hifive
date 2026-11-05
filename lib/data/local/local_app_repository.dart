import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/app_repository.dart';

/// Reads the JSON blob saved under `hifive.local.v1` before records. The
/// blob is kept as it was; nothing writes it any more.
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
}
