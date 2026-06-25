import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/skill_tree_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/file_picker_util.dart';

final skillTreeRepositoryProvider = Provider<SkillTreeRepository>((ref) {
  return SkillTreeRepository(ref.read(apiClientProvider));
});

final mySkillsProvider = FutureProvider.autoDispose<SkillsMeResponse>((ref) {
  return ref.read(skillTreeRepositoryProvider).getMySkills();
});

class SkillTreeRepository {
  SkillTreeRepository(this._api);

  final ApiClient _api;

  Future<SkillsMeResponse> getMySkills() async {
    final Map<String, dynamic> res = await _api.get('/skills/me');
    return SkillsMeResponse.fromJson(res);
  }

  Future<SkillItem> addSkill({
    required SkillTreeSkillType skillType,
    required String skillName,
    String? skillInfo,
    String? institutionName,
    String? degree,
    String? documentLabel,
    List<PickedFile> files = const <PickedFile>[],
  }) async {
    final FormData formData = FormData();
    formData.fields.addAll(<MapEntry<String, String>>[
      MapEntry('skill_type', skillType.value),
      MapEntry('skill_name', skillName.trim()),
      if ((skillInfo ?? '').trim().isNotEmpty)
        MapEntry('skill_info', skillInfo!.trim()),
      if (skillType.requiresInstitution &&
          (institutionName ?? '').trim().isNotEmpty)
        MapEntry('institution_name', institutionName!.trim()),
      if (skillType == SkillTreeSkillType.education &&
          (degree ?? '').trim().isNotEmpty)
        MapEntry('degree', degree!.trim()),
      if ((documentLabel ?? '').trim().isNotEmpty)
        MapEntry('document_label', documentLabel!.trim()),
    ]);

    for (final PickedFile file in files) {
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            file.bytes,
            filename: file.name.trim().isEmpty ? 'document' : file.name.trim(),
          ),
        ),
      );
    }

    final Map<String, dynamic> res = await _api.postMultipart(
      '/skills/add',
      formData,
    );
    return SkillItem.fromJson(res);
  }

  Future<SkillDocument> uploadSkillDocument({
    required String skillId,
    required String documentLabel,
    required PickedFile file,
  }) async {
    final FormData formData = FormData();
    formData.fields.add(
      MapEntry('document_label', documentLabel.trim()),
    );
    formData.files.add(
      MapEntry(
        'file',
        MultipartFile.fromBytes(
          file.bytes,
          filename: file.name.trim().isEmpty ? 'document' : file.name.trim(),
        ),
      ),
    );

    final Map<String, dynamic> res = await _api.postMultipart(
      '/skills/${Uri.encodeComponent(skillId.trim())}/upload-doc',
      formData,
    );
    return SkillDocument(
      id: (res['document_id'] ?? '').toString(),
      documentUrl: (res['document_url'] ?? '').toString(),
      version: int.tryParse((res['version'] ?? '').toString()) ?? 0,
      documentLabel: documentLabel.trim().isEmpty ? null : documentLabel.trim(),
    );
  }
}
