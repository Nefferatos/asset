import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';

class AuthService {
  static const String _webUsersKey = 'asset_inventory_web_users';

  Future<bool> login(String username, String password) async {
    if (kIsWeb) {
      final users = await _getWebUsers();
      return users.any(
            (u) => u['username'] == username && u['password'] == password,
          ) ||
          (username == 'admin' && password == 'admin123');
    }

    try {
      final db = await DBHelper.instance.database;
      final result = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (_) {
      return username == 'admin' && password == 'admin123';
    }
  }

  Future<void> createUser(String username, String password) async {
    if (kIsWeb) {
      final users = await _getWebUsers();
      final exists = users.any(
        (u) => (u['username'] as String).toLowerCase() == username.toLowerCase(),
      );
      if (exists) {
        throw Exception('Username already exists');
      }

      users.add({'username': username, 'password': password});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webUsersKey, jsonEncode(users));
      return;
    }

    await DBHelper.instance.createUser(username: username, password: password);
  }

  Future<List<Map<String, String>>> _getWebUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webUsersKey);
    if (raw == null || raw.isEmpty) return <Map<String, String>>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, String>>[];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, String>.from(item))
        .toList();
  }
}
