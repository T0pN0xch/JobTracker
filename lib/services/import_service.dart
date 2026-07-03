import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import '../models/job_application.dart';

class ImportResult {
  final int imported;
  final int skipped;

  const ImportResult({required this.imported, required this.skipped});
}

class ImportService {
  ImportService._internal();
  static final ImportService instance = ImportService._internal();

  static const _hasImportedKey = 'hasImported';

  Future<bool> hasImported() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasImportedKey) ?? false;
  }

  Future<void> _markImported() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasImportedKey, true);
  }

  /// Opens a file picker for an .xlsx file and imports rows into the
  /// database. Returns null if the user cancelled the picker.
  Future<ImportResult?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;

    final bytes = await File(path).readAsBytes();
    final importResult = await _importFromBytes(bytes);
    await _markImported();
    return importResult;
  }

  Future<ImportResult> _importFromBytes(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final table = excel.tables[excel.tables.keys.first];
    if (table == null || table.rows.isEmpty) {
      return const ImportResult(imported: 0, skipped: 0);
    }

    final headerRow = table.rows.first;
    final headerIndex = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final value = headerRow[i]?.value;
      if (value == null) continue;
      headerIndex[value.toString().trim().toUpperCase()] = i;
    }

    String? cellText(List<Data?> row, String column) {
      final index = headerIndex[column];
      if (index == null || index >= row.length) return null;
      final value = row[index]?.value;
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    var imported = 0;
    var skipped = 0;

    for (var r = 1; r < table.rows.length; r++) {
      final row = table.rows[r];

      final company = cellText(row, 'COMPANY');
      if (company == null) {
        skipped++;
        continue;
      }

      final position = cellText(row, 'POSITION');
      final source = cellText(row, 'SOURCE');
      final location = cellText(row, 'LOCATION');
      final tiering = cellText(row, 'TIERING');
      var link = cellText(row, 'LINK');
      final statusText = cellText(row, 'STATUS');
      final benefits = cellText(row, 'BENEFITS');
      // CRED is intentionally never read — it holds plaintext credentials
      // in the source data and must not be persisted.

      final priority = tiering != null ? int.tryParse(tiering) : null;

      final status = _classifyStatus(
        position: position,
        statusText: statusText,
        link: link,
      );

      if (status == JobStatus.applied &&
          link == null &&
          statusText != null &&
          statusText.toLowerCase().startsWith('http')) {
        link = statusText;
      }

      final notesParts = <String>[];
      if (statusText != null &&
          !statusText.toLowerCase().startsWith('http')) {
        notesParts.add('Status note: $statusText');
      }
      if (benefits != null) {
        notesParts.add('Benefits: $benefits');
      }
      final notes = notesParts.isEmpty ? null : notesParts.join('. ');

      final application = JobApplication(
        company: company,
        position: position,
        status: status,
        source: source,
        location: location,
        priority: priority,
        link: link,
        notes: notes,
      );

      await DatabaseHelper.instance.insert(application);
      imported++;
    }

    return ImportResult(imported: imported, skipped: skipped);
  }

  JobStatus _classifyStatus({
    required String? position,
    required String? statusText,
    required String? link,
  }) {
    final hasPosition = position != null && position.isNotEmpty;
    final hasStatus = statusText != null && statusText.isNotEmpty;
    final hasLink = link != null && link.isNotEmpty;

    if (!hasPosition && !hasStatus && !hasLink) {
      return JobStatus.wishlist;
    }

    if (hasStatus) {
      final lower = statusText.toLowerCase();
      if (lower.contains('interview')) {
        return JobStatus.interview;
      }
      if (lower.startsWith('http')) {
        return JobStatus.applied;
      }
      return JobStatus.applied;
    }

    return JobStatus.applied;
  }
}
