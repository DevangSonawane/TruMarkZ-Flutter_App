class SkillDocument {
  const SkillDocument({
    required this.id,
    required this.documentUrl,
    required this.version,
    required this.documentLabel,
  });

  final String id;
  final String documentUrl;
  final int version;
  final String? documentLabel;

  factory SkillDocument.fromJson(Map<String, dynamic> json) {
    return SkillDocument(
      id: (json['id'] ?? '').toString(),
      documentUrl: (json['document_url'] ?? json['url'] ?? '').toString(),
      version: int.tryParse((json['version'] ?? '').toString()) ?? 0,
      documentLabel: json['document_label']?.toString(),
    );
  }
}

class SkillItem {
  const SkillItem({
    required this.id,
    required this.individualId,
    required this.skillType,
    required this.skillName,
    required this.skillInfo,
    required this.institutionName,
    required this.degree,
    required this.status,
    required this.statusReason,
    required this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.documents,
  });

  final String id;
  final String individualId;
  final String skillType;
  final String skillName;
  final String? skillInfo;
  final String? institutionName;
  final String? degree;
  final String status;
  final String? statusReason;
  final String? verifiedAt;
  final String createdAt;
  final String updatedAt;
  final List<SkillDocument> documents;

  factory SkillItem.fromJson(Map<String, dynamic> json) {
    final dynamic rawDocuments = json['documents'];
    final List<SkillDocument> documents = rawDocuments is List
        ? rawDocuments
              .whereType<Map>()
              .map(
                (Map e) => SkillDocument.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <SkillDocument>[];
    return SkillItem(
      id: (json['id'] ?? '').toString(),
      individualId: (json['individual_id'] ?? '').toString(),
      skillType: (json['skill_type'] ?? '').toString(),
      skillName: (json['skill_name'] ?? '').toString(),
      skillInfo: json['skill_info']?.toString(),
      institutionName: json['institution_name']?.toString(),
      degree: json['degree']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      statusReason: json['status_reason']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      documents: documents,
    );
  }
}

class SkillsMeResponse {
  const SkillsMeResponse({
    required this.individualId,
    required this.total,
    required this.skills,
  });

  final String individualId;
  final int total;
  final List<SkillItem> skills;

  factory SkillsMeResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawSkills = json['skills'];
    return SkillsMeResponse(
      individualId: (json['individual_id'] ?? '').toString(),
      total: int.tryParse((json['total'] ?? '').toString()) ?? 0,
      skills: rawSkills is List
          ? rawSkills
                .whereType<Map>()
                .map(
                  (Map e) =>
                      SkillItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : <SkillItem>[],
    );
  }
}

enum SkillTreeSkillType { technical, soft, education, project }

extension SkillTreeSkillTypeX on SkillTreeSkillType {
  String get value => switch (this) {
    SkillTreeSkillType.technical => 'technical',
    SkillTreeSkillType.soft => 'soft',
    SkillTreeSkillType.education => 'education',
    SkillTreeSkillType.project => 'project',
  };

  String get label => switch (this) {
    SkillTreeSkillType.technical => 'Technical',
    SkillTreeSkillType.soft => 'Soft',
    SkillTreeSkillType.education => 'Education',
    SkillTreeSkillType.project => 'Project',
  };

  String get description => switch (this) {
    SkillTreeSkillType.technical =>
      'Languages, tools, frameworks, and certifications.',
    SkillTreeSkillType.soft =>
      'Communication, teamwork, leadership, and time management.',
    SkillTreeSkillType.education =>
      'Schooling, degrees, qualifications, and institutions.',
    SkillTreeSkillType.project =>
      'Portfolio pieces, launches, awards, and outcomes.',
  };

  String get hint => switch (this) {
    SkillTreeSkillType.technical => 'e.g. Python, Figma, AWS, Flutter',
    SkillTreeSkillType.soft => 'e.g. Team leadership, stakeholder management',
    SkillTreeSkillType.education => 'e.g. B.Tech, 12th, MCA',
    SkillTreeSkillType.project => 'e.g. Internal CRM revamp, Hackathon winner',
  };

  bool get requiresInstitution =>
      this == SkillTreeSkillType.education;
}

SkillTreeSkillType skillTypeFromValue(String value) {
  final String normalized = value.trim().toLowerCase();
  return SkillTreeSkillType.values.firstWhere(
    (SkillTreeSkillType type) => type.value == normalized,
    orElse: () => SkillTreeSkillType.technical,
  );
}
