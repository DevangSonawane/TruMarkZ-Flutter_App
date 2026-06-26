import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/skill_tree_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/token_storage.dart';
import '../../../core/utils/file_picker_util.dart';

final skillTreeRepositoryProvider = Provider<SkillTreeRepository>((ref) {
  return SkillTreeRepository(ref.read(apiClientProvider));
});

final skillTreeCompletedProvider = FutureProvider<bool>((ref) async {
  return ref.read(tokenStorageProvider).isSkillTreeCompleted();
});

final mySkillsProvider = FutureProvider<SkillsMeResponse>((ref) {
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
    final List<MultipartFile> fileParts = files
        .map(
          (PickedFile file) => MultipartFile.fromBytes(
            file.bytes,
            filename: file.name.trim().isEmpty ? 'document' : file.name.trim(),
          ),
        )
        .toList();
    final Map<String, dynamic> payload = <String, dynamic>{
      'skill_type': skillType.value,
      'skill_name': skillName.trim(),
      if ((skillInfo ?? '').trim().isNotEmpty) 'skill_info': skillInfo!.trim(),
      if (skillType.requiresInstitution &&
          (institutionName ?? '').trim().isNotEmpty)
        'institution_name': institutionName!.trim(),
      if (skillType == SkillTreeSkillType.education &&
          (degree ?? '').trim().isNotEmpty)
        'degree': degree!.trim(),
      if ((documentLabel ?? '').trim().isNotEmpty)
        'document_label': documentLabel!.trim(),
      if (fileParts.isNotEmpty) 'files': fileParts,
    };
    final FormData formData = FormData.fromMap(payload);

    final Map<String, dynamic> res = await _api.postMultipart(
      '/skills/add',
      formData,
    );
    return SkillItem.fromJson(res);
  }

  Future<SkillItem> editSkill({
    required String skillId,
    required String skillName,
    String? skillInfo,
    String? institutionName,
    String? degree,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'skill_name': skillName.trim(),
    };
    if ((skillInfo ?? '').trim().isNotEmpty) {
      payload['skill_info'] = skillInfo!.trim();
    }
    if ((institutionName ?? '').trim().isNotEmpty) {
      payload['institution_name'] = institutionName!.trim();
    }
    if ((degree ?? '').trim().isNotEmpty) {
      payload['degree'] = degree!.trim();
    }

    final Map<String, dynamic> res = await _api.patch(
      '/skills/${Uri.encodeComponent(skillId.trim())}/edit',
      data: payload,
    );
    return SkillItem.fromJson(res);
  }

  Future<void> deleteSkill({required String skillId}) async {
    await _api.deleteAny('/skills/${Uri.encodeComponent(skillId.trim())}');
  }

  Future<void> deleteAllSkills() async {
    final SkillsMeResponse current = await getMySkills();
    final String individualId = current.individualId.trim();
    if (individualId.isEmpty) {
      throw const ApiException(
        statusCode: null,
        message: 'Could not determine your skill tree owner.',
      );
    }
    await _api.deleteAny(
      '/skills/all/${Uri.encodeComponent(individualId)}',
    );
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
