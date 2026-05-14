import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

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
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: <String>['xlsx', 'xls'],
    );
    return _fromResult(result);
  }

  static Future<PickedFile?> pickImage() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    return _fromResult(result);
  }

  static Future<PickedFile?> pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: <String>['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );
    return _fromResult(result);
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
