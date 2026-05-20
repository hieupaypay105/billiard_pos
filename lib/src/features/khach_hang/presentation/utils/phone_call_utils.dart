String? normalizePhoneNumber(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }

  final normalized = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
  if (normalized.isEmpty) {
    return null;
  }

  if (normalized.startsWith('+')) {
    final digitsOnly = normalized.substring(1).replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }
    return '+$digitsOnly';
  }

  final digitsOnly = normalized.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.isEmpty) {
    return null;
  }

  return digitsOnly;
}
