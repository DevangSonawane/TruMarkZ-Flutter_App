import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final batchNameStoreProvider =
    StateNotifierProvider<BatchNameStore, Map<String, String>>((ref) {
      return BatchNameStore();
    });

class BatchNameStore extends StateNotifier<Map<String, String>> {
  BatchNameStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      super(const <String, String>{}) {
    _load();
  }

  static const String _key = 'batch_names_v1';

  final FlutterSecureStorage _storage;

  Future<void> _load() async {
    try {
      final String? raw = await _storage.read(key: _key);
      if (raw == null || raw.trim().isEmpty) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final Map<String, String> map = <String, String>{};
      for (final MapEntry<dynamic, dynamic> e in decoded.entries) {
        final String k = (e.key ?? '').toString().trim();
        final String v = (e.value ?? '').toString().trim();
        if (k.isEmpty || v.isEmpty) continue;
        map[k] = v;
      }
      if (map.isEmpty) return;
      state = map;
    } catch (_) {
      // ignore corrupt storage
    }
  }

  Future<void> setBatchName(String batchId, String batchName) async {
    final String id = batchId.trim();
    final String name = batchName.trim();
    if (id.isEmpty || name.isEmpty) return;
    final Map<String, String> next = Map<String, String>.from(state);
    next[id] = name;
    state = next;
    try {
      await _storage.write(key: _key, value: jsonEncode(next));
    } catch (_) {
      // ignore persistence errors
    }
  }
}
