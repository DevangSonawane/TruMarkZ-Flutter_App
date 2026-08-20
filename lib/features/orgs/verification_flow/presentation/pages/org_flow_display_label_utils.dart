import '../../../../../core/models/auth_models.dart';

class OrgFlowDisplayLabelUtils {
  static String resolveOrganizationLabel({
    required UserProfile? profile,
    required String fallback,
  }) {
    final String cleanedFallback = fallback.trim();
    if (cleanedFallback.isEmpty) return cleanedFallback;

    if (_looksLikeOpaqueIdentifier(cleanedFallback)) {
      final String organizationName = profile?.organizationName?.trim() ?? '';
      if (organizationName.isNotEmpty) return organizationName;

      final String fullName = profile?.fullName?.trim() ?? '';
      if (fullName.isNotEmpty) return fullName;
    }

    return cleanedFallback;
  }

  static bool _looksLikeOpaqueIdentifier(String value) {
    final String cleaned = value.trim();
    if (cleaned.isEmpty) return false;
    if (cleaned.contains(' ')) return false;

    final String normalized = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (normalized.length >= 24) return true;

    return RegExp(r'^[0-9a-f]{8,}$', caseSensitive: false).hasMatch(normalized);
  }
}
