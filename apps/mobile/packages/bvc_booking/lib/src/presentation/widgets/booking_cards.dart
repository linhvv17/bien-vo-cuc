import 'package:flutter/material.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_ui/bvc_ui.dart';

typedef JsonMap = Map<String, dynamic>;

String bookingStatusVi(String s) => switch (s) {
      'PENDING' => 'Chờ xử lý',
      'CONFIRMED' => 'Đã xác nhận',
      'CANCELLED' => 'Đã hủy',
      _ => s,
    };

Color bookingStatusColor(String s) => switch (s) {
      'CONFIRMED' => const Color(0xFF2ECC71),
      'CANCELLED' => const Color(0xFFE74C3C),
      _ => const Color(0xFFF2C94C),
    };

String serviceTypeVi(String s) => switch (s) {
      'ACCOMMODATION' => 'Nhà nghỉ / lưu trú',
      'FOOD' => 'Ăn uống',
      'VEHICLE' => 'Xe / vận chuyển',
      'TOUR' => 'Chụp ảnh / tour',
      _ => s,
    };

IconData serviceTypeIcon(String s) => switch (s) {
      'ACCOMMODATION' => Icons.hotel_rounded,
      'FOOD' => Icons.restaurant_rounded,
      'VEHICLE' => Icons.directions_car_rounded,
      'TOUR' => Icons.photo_camera_rounded,
      _ => Icons.local_offer_rounded,
    };

/// Định dạng ISO / chuỗi ngày từ API để hiển thị (dd/MM/yyyy HH:mm).
String formatBookingDateTime(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$mi';
  } catch (_) {
    return iso;
  }
}

class BookingItemCard extends StatelessWidget {
  const BookingItemCard({super.key, required this.item, this.onTap});
  final JsonMap item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final service = (item['service'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final provider = (service['provider'] as Map?)?.cast<String, dynamic>();
    final combo = (item['combo'] as Map?)?.cast<String, dynamic>();

    final status = (item['status'] as String?) ?? '—';
    final statusLabel = bookingStatusVi(status);
    final accent = bookingStatusColor(status);

    final type = (service['type'] as String?) ?? '';
    final typeLabel = serviceTypeVi(type);
    final icon = serviceTypeIcon(type);

    final name = (service['name'] as String?) ?? '—';
    final providerName = (provider?['name'] as String?) ?? '';

    final images = <String>[
      ...((service['images'] as List?)?.whereType<String>() ?? const <String>[]),
    ];

    final date = (item['date'] as String?) ?? '';
    final createdAt = (item['createdAt'] as String?) ?? '';
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final total = (item['totalPrice'] as num?)?.toInt() ?? 0;
    final note = (item['customerNote'] as String?) ?? '';
    final gid = item['bookingGroupId'] as String?;

    Widget hero;
    if (images.isNotEmpty) {
      hero = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SafeNetworkImage(
          url: images.first,
          height: 78,
          width: 110,
          fit: BoxFit.cover,
          errorWidget: _HeroFallback(height: 78, width: 110, icon: icon, accent: accent),
        ),
      );
    } else {
      hero = _HeroFallback(height: 78, width: 110, icon: icon, accent: accent);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hero,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: accent.withValues(alpha: 0.14),
                              border: Border.all(color: accent.withValues(alpha: 0.25)),
                            ),
                            child: Text(statusLabel, style: TextStyle(fontWeight: FontWeight.w900, color: accent)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              typeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      if (providerName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded, size: 15, color: accent.withValues(alpha: 0.95)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                providerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF8FA8C0), fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(icon: Icons.event_rounded, label: 'Ngày dùng: ${formatBookingDateTime(date)}'),
                if (createdAt.isNotEmpty) _Pill(icon: Icons.schedule_rounded, label: 'Đặt lúc: ${formatBookingDateTime(createdAt)}'),
                _Pill(icon: Icons.confirmation_number_rounded, label: 'SL × $qty'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    combo != null ? 'Tổng (mỗi dòng dịch vụ):' : 'Tổng:',
                    style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12),
                  ),
                ),
                Text(
                  formatVnd(total),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF2C94C)),
                ),
              ],
            ),
            if (gid != null && gid.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Nhóm combo: ${gid.length > 12 ? '${gid.substring(0, 12)}…' : gid}',
                style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12),
              ),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Text(
                  'Ghi chú: $note',
                  style: const TextStyle(color: Color(0xFFE6EEF8), height: 1.25),
                ),
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.height, required this.width, required this.icon, required this.accent});
  final double height;
  final double width;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.20),
            const Color(0xFF1A2D3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.90), size: 34),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFA0B4C8)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

