class Validators {
  // 이메일 검증
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // 비밀번호 검증 (최소 8자, 영문, 숫자 포함)
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    return hasLetter && hasDigit;
  }

  // 휴대폰 번호 검증
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$');
    return phoneRegex.hasMatch(phone);
  }

  // 빈 문자열 검증
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  // 최소 길이 검증
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  // 최대 길이 검증
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }

  // 숫자만 포함 검증
  static bool isNumeric(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }

  // 한글만 포함 검증
  static bool isKorean(String value) {
    return RegExp(r'^[가-힣]+$').hasMatch(value);
  }
}

