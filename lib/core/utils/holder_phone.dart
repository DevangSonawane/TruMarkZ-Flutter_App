import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Holder mobile number rules for Human batches that resolve to Permission
/// Required — mirrors the backend's accepted format.
///
/// Spaces, dashes, dots and brackets are ignored; an optional leading `+`
/// is allowed; 10–15 digits are required.
String normalizeHolderPhone(String raw) =>
    raw.trim().replaceAll(RegExp(r'[\s\-.()]'), '');

bool isValidHolderPhone(String raw) =>
    RegExp(r'^\+?\d{10,15}$').hasMatch(normalizeHolderPhone(raw));

const String holderPhoneMissingMessage =
    'Phone number is required for Permission Required batches.';
const String holderPhoneInvalidMessage =
    'Enter a valid mobile number: 10–15 digits, optionally starting with +.';

/// Inline validation message, or null when [raw] is acceptable.
String? holderPhoneError(String? raw, {required bool required}) {
  final String value = (raw ?? '').trim();
  if (value.isEmpty) return required ? holderPhoneMissingMessage : null;
  return isValidHolderPhone(value) ? null : holderPhoneInvalidMessage;
}

/// Field label with a red `*` when the field is required.
Widget requiredFieldLabel(String text, {required bool required}) {
  return Text.rich(
    TextSpan(
      text: text,
      children: <InlineSpan>[
        if (required)
          const TextSpan(
            text: ' *',
            style: TextStyle(color: AppColors.error),
          ),
      ],
    ),
  );
}
