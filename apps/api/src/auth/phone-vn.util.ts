/**
 * Chuẩn hoá SĐT di động VN về dạng 0xxxxxxxxx (10 số, đầu 03/05/07/08/09).
 * Trả null nếu không hợp lệ.
 */
export function normalizeVietnameseMobilePhone(input: string): string | null {
  let s = input.trim().replace(/[\s.-]/g, '');
  if (s.startsWith('+84')) {
    s = `0${s.slice(4)}`;
  } else if (s.startsWith('84') && s.length >= 11) {
    s = `0${s.slice(2)}`;
  }
  if (!/^0(3|5|7|8|9)[0-9]{8}$/.test(s)) {
    return null;
  }
  return s;
}

/** Email nội bộ cho tài khoản đăng ký bằng SĐT (đảm bảo unique trên cột email). */
export function syntheticEmailFromPhone(normalizedPhone: string): string {
  return `${normalizedPhone}@phone.bvc.local`;
}
