/// Chuẩn hoá SĐT di động VN → `0xxxxxxxxx` (10 số). Trả `null` nếu không hợp lệ.
String? normalizeVietnameseMobilePhone(String input) {
  var s = input.trim().replaceAll(RegExp(r'[\s.-]'), '');
  if (s.startsWith('+84')) {
    s = '0${s.substring(4)}';
  } else if (s.startsWith('84') && s.length >= 11) {
    s = '0${s.substring(2)}';
  }
  if (!RegExp(r'^0(3|5|7|8|9)\d{8}$').hasMatch(s)) {
    return null;
  }
  return s;
}

/// Mật khẩu cơ bản: 8–64 ký tự, ít nhất một chữ Latin và một chữ số (khớp backend).
bool isBasicPassword(String password) {
  if (password.length < 8 || password.length > 64) return false;
  return RegExp(r'[A-Za-z]').hasMatch(password) && RegExp(r'\d').hasMatch(password);
}
