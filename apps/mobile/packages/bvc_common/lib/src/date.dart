import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _vietnamTzInitialized = false;

/// Gọi một lần ở `main()` (khuyến nghị); nếu không gọi, [ymdVietnamToday] sẽ tự khởi tạo lần đầu.
void ensureVietnamTimeZonesInitialized() {
  if (_vietnamTzInitialized) return;
  tz_data.initializeTimeZones();
  _vietnamTzInitialized = true;
}

String ymd(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Định dạng hiển thị (vd. chọn ngày trên UI).
String dmy(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final m = d.month.toString().padLeft(2, '0');
  return '$day/$m/${d.year}';
}

/// Parse `YYYY-MM-DD`; trả về null nếu không hợp lệ.
DateTime? parseYmd(String s) {
  final t = s.trim();
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(t);
  if (m == null) return null;
  final y = int.tryParse(m.group(1)!);
  final mo = int.tryParse(m.group(2)!);
  final day = int.tryParse(m.group(3)!);
  if (y == null || mo == null || day == null) return null;
  if (mo < 1 || mo > 12 || day < 1 || day > 31) return null;
  final dt = DateTime(y, mo, day);
  if (dt.year != y || dt.month != mo || dt.day != day) return null;
  return dt;
}

/// Ngày lịch **hôm nay** theo múi giờ IANA `Asia/Ho_Chi_Minh` (Việt Nam).
String ymdVietnamToday() {
  ensureVietnamTimeZonesInitialized();
  final loc = tz.getLocation('Asia/Ho_Chi_Minh');
  final now = tz.TZDateTime.now(loc);
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Cộng [days] ngày dương lịch vào một chuỗi `YYYY-MM-DD`.
String ymdAddCalendarDays(String ymdStr, int days) {
  final p = parseYmd(ymdStr);
  if (p == null) return ymdStr;
  final d = DateTime(p.year, p.month, p.day).add(Duration(days: days));
  return ymd(d);
}
