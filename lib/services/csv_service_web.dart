import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../models/asset.dart';
import 'asset_service.dart';

class CSVService {
  final assetService = AssetService();

  String _normalizeCondition(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value == 'found') return 'Found';
    if (value == 'defective') return 'Defective';
    return 'Not Found';
  }

  Future<void> importCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null) return;

    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty) return;

    final content = utf8.decode(file.bytes!);
    final rows = const CsvToListConverter().convert(content);
    if (rows.isEmpty) return;

    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList(growable: false);
    final hasHeader = header.contains('asset_number');

    final assetNumberIndex = hasHeader ? header.indexOf('asset_number') : 0;
    final descriptionIndex = hasHeader ? header.indexOf('description') : 1;
    final locationIndex = hasHeader ? header.indexOf('location') : 2;
    final remarksIndex = hasHeader ? header.indexOf('remarks') : 3;
    final conditionIndex = hasHeader ? header.indexOf('condition') : -1;
    final validateIndex = hasHeader ? header.indexOf('validate') : 4;
    final createdAtIndex = hasHeader ? header.indexOf('created_at') : -1;
    final updatedAtIndex = hasHeader ? header.indexOf('updated_at') : -1;
    final startRow = hasHeader ? 1 : 0;

    for (int i = startRow; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 3 || assetNumberIndex < 0 || descriptionIndex < 0 || locationIndex < 0) {
        continue;
      }

      String valueAt(int index, [String fallback = '']) {
        if (index < 0 || index >= r.length) return fallback;
        return r[index].toString();
      }

      final conditionValue = conditionIndex >= 0
          ? valueAt(conditionIndex)
          : valueAt(validateIndex);

      await assetService.addAsset(
        Asset(
          assetNumber: valueAt(assetNumberIndex),
          description: valueAt(descriptionIndex),
          location: valueAt(locationIndex),
          remarks: valueAt(remarksIndex),
          validate: _normalizeCondition(conditionValue),
          createdAt: valueAt(createdAtIndex),
          updatedAt: valueAt(updatedAtIndex),
        ),
      );
    }
  }

  Future<void> exportCSV(List<Asset> assets) async {
    final sortedAssets = List<Asset>.from(assets)
      ..sort((a, b) => a.assetNumber.compareTo(b.assetNumber));
    final generatedAt = DateTime.now().toIso8601String();

    final rows = [
      [
        'asset_number',
        'description',
        'location',
        'remarks',
        'condition',
        'validate',
        'created_at',
        'updated_at',
        'csv_generated_at',
      ],
      ...sortedAssets.map(
        (a) => [
          a.assetNumber.trim(),
          a.description.trim(),
          a.location.trim(),
          a.remarks.trim(),
          _normalizeCondition(a.validate),
          _normalizeCondition(a.validate),
          a.createdAt ?? '',
          a.updatedAt ?? '',
          generatedAt,
        ],
      ),
    ];
    final csvText = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(utf8.encode(csvText));
    final fileName =
        'asset_report_${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}.csv';

    await FilePicker.platform.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: bytes,
    );
  }
}
