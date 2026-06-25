import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class PickedFile {
  const PickedFile({
    required this.name,
    required this.bytes,
    required this.extension,
  });

  final String name;
  final Uint8List bytes;
  final String extension; // 'xlsx', 'pdf', 'jpg', etc.
}

class FilePickerUtil {
  static Future<PickedFile?> pickExcel() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: <String>['xlsx', 'csv'],
      );
      return _fromResult(result);
    } on MissingPluginException {
      debugPrint(
        '[FilePickerUtil] file_picker plugin not registered. '
        'Do a full stop/re-run (not hot restart).',
      );
      return null;
    } on PlatformException {
      debugPrint('[FilePickerUtil] pickExcel failed (PlatformException).');
      return null;
    }
  }

  static Future<PickedFile?> pickImage() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      return _fromResult(result);
    } on MissingPluginException {
      debugPrint(
        '[FilePickerUtil] file_picker plugin not registered. '
        'Do a full stop/re-run (not hot restart).',
      );
      return null;
    } on PlatformException {
      debugPrint('[FilePickerUtil] pickImage failed (PlatformException).');
      return null;
    }
  }

  static Future<PickedFile?> pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: <String>['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      return _fromResult(result);
    } on MissingPluginException {
      debugPrint(
        '[FilePickerUtil] file_picker plugin not registered. '
        'Do a full stop/re-run (not hot restart).',
      );
      return null;
    } on PlatformException {
      debugPrint('[FilePickerUtil] pickDocument failed (PlatformException).');
      return null;
    }
  }

  static Future<List<PickedFile>> pickDocuments() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        withData: true,
        allowedExtensions: <String>['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (result == null || result.files.isEmpty) return <PickedFile>[];
      final List<PickedFile> files = <PickedFile>[];
      for (final PlatformFile file in result.files) {
        final Uint8List? bytes = file.bytes;
        if (bytes == null) continue;
        final String name = (file.name).trim();
        final String ext = (file.extension ?? '')
            .toLowerCase()
            .replaceAll('.', '')
            .trim();
        files.add(
          PickedFile(
            name: name.isEmpty ? 'file' : name,
            bytes: bytes,
            extension: ext,
          ),
        );
      }
      return files;
    } on MissingPluginException {
      debugPrint(
        '[FilePickerUtil] file_picker plugin not registered. '
        'Do a full stop/re-run (not hot restart).',
      );
      return <PickedFile>[];
    } on PlatformException {
      debugPrint('[FilePickerUtil] pickDocuments failed (PlatformException).');
      return <PickedFile>[];
    }
  }

  static PickedFile? _fromResult(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) return null;
    final PlatformFile file = result.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) return null;
    final String name = (file.name).trim();
    final String ext = (file.extension ?? '')
        .toLowerCase()
        .replaceAll('.', '')
        .trim();
    return PickedFile(
      name: name.isEmpty ? 'file' : name,
      bytes: bytes,
      extension: ext,
    );
  }
}
