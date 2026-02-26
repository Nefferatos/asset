import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/asset.dart';

class AssetService {
  final db = DBHelper.instance;
  static final List<Asset> _webAssets = <Asset>[];
  static int _webNextId = 1;
  static bool _webLoaded = false;
  static const String _webAssetsKey = 'asset_inventory_web_assets';

  Future<void> _ensureWebLoaded() async {
    if (!kIsWeb || _webLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webAssetsKey);
    if (raw == null || raw.isEmpty) {
      _webLoaded = true;
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      _webAssets
        ..clear()
        ..addAll(
          decoded.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return Asset.fromMap(map);
          }),
        );
      final maxId = _webAssets
          .map((a) => a.id ?? 0)
          .fold<int>(0, (prev, current) => current > prev ? current : prev);
      _webNextId = maxId + 1;
    }

    _webLoaded = true;
  }

  Future<void> _saveWebAssets() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = _webAssets
        .map(
          (a) => {
            'id': a.id,
            'asset_number': a.assetNumber,
            'description': a.description,
            'location': a.location,
            'remarks': a.remarks,
            'validate': a.validate,
            'created_at': a.createdAt ?? '',
            'updated_at': a.updatedAt ?? '',
          },
        )
        .toList(growable: false);
    await prefs.setString(_webAssetsKey, jsonEncode(payload));
  }

  Future<List<Asset>> getAssets() async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final copy = List<Asset>.from(_webAssets);
      copy.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      return copy;
    }

    final database = await db.database;
    final res = await database.query('assets', orderBy: 'id DESC');
    return res.map((e) => Asset.fromMap(e)).toList();
  }

  Future<void> addAsset(Asset asset) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final exists = _webAssets.any(
        (a) => a.assetNumber.toLowerCase() == asset.assetNumber.toLowerCase(),
      );
      if (exists) {
        throw Exception('Asset number already exists');
      }

      _webAssets.add(
        Asset(
          id: _webNextId++,
          assetNumber: asset.assetNumber,
          description: asset.description,
          location: asset.location,
          remarks: asset.remarks,
          validate: asset.validate,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await _saveWebAssets();
      return;
    }

    final database = await db.database;
    await database.insert(
      'assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateAsset(Asset asset) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webAssets.indexWhere((a) => a.id == asset.id);
      if (index == -1) {
        throw Exception('Asset not found');
      }

      final duplicate = _webAssets.any(
        (a) =>
            a.id != asset.id &&
            a.assetNumber.toLowerCase() == asset.assetNumber.toLowerCase(),
      );
      if (duplicate) {
        throw Exception('Asset number already exists');
      }

      _webAssets[index] = Asset(
        id: asset.id,
        assetNumber: asset.assetNumber,
        description: asset.description,
        location: asset.location,
        remarks: asset.remarks,
        validate: asset.validate,
        createdAt: _webAssets[index].createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _saveWebAssets();
      return;
    }

    final database = await db.database;
    final rows = await database.update(
      'assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
    if (rows == 0) {
      throw Exception('Asset not found');
    }
  }

  Future<void> deleteAsset(int id) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webAssets.removeWhere((a) => a.id == id);
      await _saveWebAssets();
      return;
    }

    final database = await db.database;
    await database.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<Asset?> validateAsset(String number) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webAssets.indexWhere(
        (a) => a.assetNumber.toLowerCase() == number.toLowerCase().trim(),
      );
      if (index == -1) return null;

      final current = _webAssets[index];
      final updated = Asset(
        id: current.id,
        assetNumber: current.assetNumber,
        description: current.description,
        location: current.location,
        remarks: current.remarks,
        validate: 'Found',
        createdAt: current.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      _webAssets[index] = updated;
      await _saveWebAssets();
      return updated;
    }

    final database = await db.database;
    final res = await database.query(
      'assets',
      where: 'LOWER(asset_number) = ?',
      whereArgs: [number.toLowerCase().trim()],
    );

    if (res.isEmpty) return null;

    await database.update(
      'assets',
      {
        'validate': 'Found',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [res.first['id']],
    );

    return Asset.fromMap(res.first);
  }
}
