import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

class SpreadsheetPreview {
  const SpreadsheetPreview({
    required this.sheetName,
    required this.columns,
    required this.rows,
    required this.totalRows,
  });

  final String sheetName;
  final List<String> columns;
  final List<List<String>> rows;
  final int totalRows;
}

class SpreadsheetPreviewUtil {
  static SpreadsheetPreview parse({
    required Uint8List bytes,
    required String extension,
    int maxColumns = 8,
    int maxRows = 10,
  }) {
    final String ext = extension.toLowerCase().replaceAll('.', '').trim();
    if (ext == 'csv') {
      return _parseCsv(bytes: bytes, maxColumns: maxColumns, maxRows: maxRows);
    }
    if (ext == 'xls') {
      throw const FormatException(
        'Preview for legacy .xls is not supported. Please upload .xlsx or .csv.',
      );
    }
    if (ext == 'xlsx') {
      return _parseExcel(bytes: bytes, maxColumns: maxColumns, maxRows: maxRows);
    }
    throw FormatException('Unsupported file type: .$ext');
  }

  static SpreadsheetPreview _parseCsv({
    required Uint8List bytes,
    required int maxColumns,
    required int maxRows,
  }) {
    final String raw = utf8.decode(bytes, allowMalformed: true);
    final List<List<dynamic>> table = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(raw);

    if (table.isEmpty) {
      return const SpreadsheetPreview(
        sheetName: 'CSV',
        columns: <String>[],
        rows: <List<String>>[],
        totalRows: 0,
      );
    }

    final List<dynamic> header = table.first;
    final List<String> columns = _normalizeHeader(
      header.map((dynamic e) => e?.toString() ?? '').toList(),
      maxColumns: maxColumns,
    );

    final List<List<String>> rows = <List<String>>[];
    for (int i = 1; i < table.length && rows.length < maxRows; i++) {
      final List<dynamic> r = table[i];
      if (_isRowEmpty(r)) continue;
      rows.add(_normalizeRow(r, columns.length));
    }

    final int totalRows = table.skip(1).where((List<dynamic> r) => !_isRowEmpty(r)).length;
    return SpreadsheetPreview(
      sheetName: 'CSV',
      columns: columns,
      rows: rows,
      totalRows: totalRows,
    );
  }

  static SpreadsheetPreview _parseExcel({
    required Uint8List bytes,
    required int maxColumns,
    required int maxRows,
  }) {
    // XLSX files are ZIP containers; most invalid/renamed files will not start
    // with the PK signature.
    if (bytes.length < 2 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw const FormatException(
        'Invalid .xlsx file. Please export/download as .xlsx (not .xls) and try again.',
      );
    }

    Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (_) {
      throw const FormatException(
        'Unable to read this .xlsx file. Please re-export it as a standard Excel (.xlsx) or upload as .csv.',
      );
    }
    final List<String> sheetNames = excel.tables.keys.toList();
    if (sheetNames.isEmpty) {
      return const SpreadsheetPreview(
        sheetName: 'Sheet1',
        columns: <String>[],
        rows: <List<String>>[],
        totalRows: 0,
      );
    }

    final String sheetName = sheetNames.first;
    final Sheet? sheet = excel.tables[sheetName];
    if (sheet == null) {
      return SpreadsheetPreview(
        sheetName: sheetName,
        columns: const <String>[],
        rows: const <List<String>>[],
        totalRows: 0,
      );
    }

    final List<List<Data?>> all = sheet.rows;
    if (all.isEmpty) {
      return SpreadsheetPreview(
        sheetName: sheetName,
        columns: const <String>[],
        rows: const <List<String>>[],
        totalRows: 0,
      );
    }

    // Find first non-empty row to use as header.
    int headerIndex = 0;
    while (headerIndex < all.length && _isExcelRowEmpty(all[headerIndex])) {
      headerIndex += 1;
    }
    if (headerIndex >= all.length) {
      return SpreadsheetPreview(
        sheetName: sheetName,
        columns: const <String>[],
        rows: const <List<String>>[],
        totalRows: 0,
      );
    }

    final List<String> header = all[headerIndex]
        .map((Data? d) => d?.value?.toString() ?? '')
        .toList();
    final List<String> columns = _normalizeHeader(header, maxColumns: maxColumns);

    final List<List<String>> rows = <List<String>>[];
    for (int i = headerIndex + 1; i < all.length && rows.length < maxRows; i++) {
      final List<Data?> r = all[i];
      if (_isExcelRowEmpty(r)) continue;
      rows.add(r.take(columns.length).map((Data? d) => (d?.value?.toString() ?? '').trim()).toList());
    }

    final int totalRows =
        all.skip(headerIndex + 1).where((List<Data?> r) => !_isExcelRowEmpty(r)).length;
    return SpreadsheetPreview(
      sheetName: sheetName,
      columns: columns,
      rows: rows,
      totalRows: totalRows,
    );
  }

  static List<String> _normalizeHeader(List<String> header, {required int maxColumns}) {
    final List<String> trimmed = header.map((String s) => s.trim()).toList();
    final int length = trimmed.where((String c) => c.isNotEmpty).isEmpty
        ? trimmed.length
        : trimmed.indexWhere((String c) => c.isEmpty) == -1
            ? trimmed.length
            : trimmed.indexWhere((String c) => c.isEmpty);
    final int cols = (length == 0 ? trimmed.length : length).clamp(1, maxColumns);

    final List<String> out = <String>[];
    for (int i = 0; i < cols; i++) {
      final String name = (i < trimmed.length ? trimmed[i] : '').trim();
      out.add(name.isEmpty ? 'col_${i + 1}' : name);
    }
    return out;
  }

  static List<String> _normalizeRow(List<dynamic> row, int colCount) {
    final List<String> out = <String>[];
    for (int i = 0; i < colCount; i++) {
      out.add((i < row.length ? (row[i]?.toString() ?? '') : '').trim());
    }
    return out;
  }

  static bool _isRowEmpty(List<dynamic> row) {
    for (final dynamic v in row) {
      final String s = (v?.toString() ?? '').trim();
      if (s.isNotEmpty) return false;
    }
    return true;
  }

  static bool _isExcelRowEmpty(List<Data?> row) {
    for (final Data? v in row) {
      final String s = (v?.value?.toString() ?? '').trim();
      if (s.isNotEmpty) return false;
    }
    return true;
  }
}
