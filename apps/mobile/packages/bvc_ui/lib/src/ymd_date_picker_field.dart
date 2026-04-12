import 'package:bvc_common/bvc_common.dart';
import 'package:flutter/material.dart';

/// Mở [showDatePicker], trả về `YYYY-MM-DD` hoặc null nếu huỷ.
Future<String?> showYmdDatePicker(
  BuildContext context, {
  required String initialYmd,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final first = firstDate ?? today;
  final last = lastDate ?? today.add(const Duration(days: 730));

  final parsed = parseYmd(initialYmd) ?? first;
  var initial = DateTime(parsed.year, parsed.month, parsed.day);
  if (initial.isBefore(first)) initial = first;
  if (initial.isAfter(last)) initial = last;

  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    locale: const Locale('vi', 'VN'),
  );
  if (picked == null) return null;
  return ymd(picked);
}

/// Ô chọn ngày (hiển thị dd/MM/yyyy), giá trị API vẫn là `YYYY-MM-DD`.
class YmdPickerFormField extends StatelessWidget {
  const YmdPickerFormField({
    super.key,
    required this.ymdValue,
    required this.onChanged,
    required this.decoration,
  });

  final String ymdValue;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final dt = parseYmd(ymdValue);
    final label = dt != null ? dmy(dt) : ymdValue;

    return InkWell(
      onTap: () async {
        final next = await showYmdDatePicker(context, initialYmd: ymdValue);
        if (next != null) onChanged(next);
      },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: decoration,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              Icons.calendar_month_rounded,
              size: 22,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}
