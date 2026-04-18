/// Pure, context-free validators. Form widgets wrap them in a localized
/// error message rather than baking l10n here.
class Validators {
  const Validators._();

  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'required';
    final re = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');
    return re.hasMatch(v.trim()) ? null : 'invalid_email';
  }

  static String? minLength(String? v, int n) {
    if (v == null || v.length < n) return 'min_length_$n';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 15) return 'invalid_phone';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'required';
    if (v.length < 6) return 'min_length_6';
    return null;
  }
}
