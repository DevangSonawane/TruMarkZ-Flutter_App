/// Rewords backend field names for people, e.g. `phone_number` →
/// "phone number", and drops FastAPI's "Value error, " prefix.
String friendlyFieldText(String text) {
  return text
      .replaceFirst(RegExp(r'^Value error,\s*'), '')
      .replaceAll(RegExp(r"['`\x22]?phone_number['`\x22]?"), 'phone number');
}
