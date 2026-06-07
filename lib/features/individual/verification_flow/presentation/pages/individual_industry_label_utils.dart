const List<String> kIndividualIndustryOptions = <String>[
  'Education',
  'Employment',
  'Finance',
  'Healthcare',
  'Transport',
  'Others',
];

String summarizeIndividualIndustryLabel(
  String raw, {
  String fallback = '',
}) {
  final String value = raw.trim();
  if (value.isEmpty) return fallback;

  final List<String> parts = _parseParts(value);
  if (parts.isEmpty) return _formatPart(value);

  final Set<String> normalizedParts = parts
      .map(_normalize)
      .where((String s) => s.isNotEmpty)
      .toSet();
  final Set<String> normalizedOptions = kIndividualIndustryOptions
      .map(_normalize)
      .toSet();

  if (normalizedParts.containsAll(normalizedOptions)) {
    return 'All';
  }

  if (parts.length == 1) {
    return _formatPart(parts.first);
  }

  return '${_formatPart(parts.first)} +${parts.length - 1}';
}

List<String> _parseParts(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) return <String>[];
  if (value.startsWith('[') && value.endsWith(']')) {
    return value
        .substring(1, value.length - 1)
        .split(',')
        .map((String s) => s.replaceAll('"', '').trim())
        .where((String s) => s.isNotEmpty)
        .toList();
  }
  if (value.contains(',')) {
    return value
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
  }
  return <String>[value];
}

String _formatPart(String value) {
  final String cleaned = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (cleaned.isEmpty) return '';
  final List<String> tokens = cleaned
      .split(' ')
      .where((String token) => token.trim().isNotEmpty)
      .toList();
  return tokens
      .map(
        (String token) => token.isEmpty
            ? token
            : '${token[0].toUpperCase()}${token.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _normalize(String value) => value.trim().toLowerCase();
