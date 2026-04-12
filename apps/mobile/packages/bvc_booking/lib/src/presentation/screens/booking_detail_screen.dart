import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_ui/bvc_ui.dart';

import '../providers/public_booking_providers.dart';
import '../widgets/booking_cards.dart';
import 'my_bookings_screen.dart';

Widget _bookingDetailImageError(double width, double height) {
  return Container(
    width: width,
    height: height,
    color: const Color(0xFF1A2D3E),
    alignment: Alignment.center,
    child: Icon(Icons.image_not_supported_outlined, size: width > 90 ? 28 : 20, color: Colors.white.withValues(alpha: 0.28)),
  );
}

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.item, this.routeBookingId});

  final JsonMap item;

  /// ID từ URL `/book/mine/:bookingId` — dùng khi [item] thiếu hoặc sai kiểu `id`.
  final String? routeBookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  late Map<String, dynamic> _item;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    final pathId = widget.routeBookingId?.trim();
    final rawId = _item['id'];
    final hasId = rawId != null && '$rawId'.trim().isNotEmpty;
    if (!hasId && pathId != null && pathId.isNotEmpty) {
      _item['id'] = pathId;
    }
  }

  bool get _canCancel {
    final s = (_item['status'] as String?) ?? '';
    return s == 'PENDING' || s == 'CONFIRMED';
  }

  /// Chuẩn hóa id (API / JSON decode đôi khi không phải [String]).
  String? _resolveBookingId() {
    final raw = _item['id'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw != null && '$raw'.trim().isNotEmpty) return '$raw'.trim();
    final p = widget.routeBookingId?.trim();
    if (p != null && p.isNotEmpty) return p;
    return null;
  }

  Future<void> _copyPhone(BuildContext context, String phone) async {
    final t = phone.trim();
    if (t.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: t));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã copy: $t'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final id = _resolveBookingId();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã đặt chỗ. Quay lại danh sách và mở lại đơn.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Feedback.forTap(context);
    final gid = _item['bookingGroupId'] as String?;
    final isGroup = gid != null && gid.isNotEmpty;

    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đặt chỗ?'),
        content: Text(
          isGroup
              ? 'Toàn bộ đơn trong cùng nhóm combo / nhiều phòng sẽ được hủy. Bạn chắc chắn?'
              : 'Bạn chắc chắn muốn hủy đặt chỗ này?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đặt chỗ'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    setState(() => _cancelling = true);
    try {
      final repo = ref.read(publicBookingRepositoryProvider);
      final updated = await repo.cancelMine(id);
      ref.invalidate(myBookingsProvider);
      if (!context.mounted) return;
      setState(() {
        _item = updated;
        _cancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đặt chỗ'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (context.mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is DioException ? formatDioError(e) : '$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = (_item['service'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final provider = (service['provider'] as Map?)?.cast<String, dynamic>();
    final combo = (_item['combo'] as Map?)?.cast<String, dynamic>();

    final status = (_item['status'] as String?) ?? '—';
    final accent = bookingStatusColor(status);
    final statusLabel = bookingStatusVi(status);

    final type = (service['type'] as String?) ?? '';
    final typeLabel = serviceTypeVi(type);
    final icon = serviceTypeIcon(type);

    final name = (service['name'] as String?) ?? '—';
    final desc = (service['description'] as String?) ?? '';
    final price = (service['price'] as num?)?.toInt() ?? 0;
    final maxCap = (service['maxCapacity'] as num?)?.toInt() ?? 0;

    final qty = (_item['quantity'] as num?)?.toInt() ?? 1;
    final total = (_item['totalPrice'] as num?)?.toInt() ?? 0;

    final customerName = (_item['customerName'] as String?) ?? '—';
    final customerPhone = (_item['customerPhone'] as String?) ?? '';
    final customerNote = (_item['customerNote'] as String?) ?? '';

    final date = (_item['date'] as String?) ?? '';
    final createdAt = (_item['createdAt'] as String?) ?? '';
    final gid = _item['bookingGroupId'] as String?;

    final images = <String>[
      ...((service['images'] as List?)?.whereType<String>() ?? const <String>[]),
    ];

    final providerName = (provider?['name'] as String?) ?? '';
    final providerPhone = (provider?['phone'] as String?) ?? '';
    final providerAddr = (provider?['address'] as String?) ?? '';

    final dateUseLabel = date.isNotEmpty ? formatBookingDateTime(date) : '—';
    final createdLabel = createdAt.isNotEmpty ? formatBookingDateTime(createdAt) : '—';

    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Chi tiết đặt chỗ'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  children: [
                    _TopSummary(
                      accent: accent,
                      icon: icon,
                      title: name,
                      statusLabel: statusLabel,
                      typeLabel: typeLabel,
                      providerName: providerName,
                      heroUrl: images.isNotEmpty ? images.first : null,
                    ),
                    const SizedBox(height: 14),
                    if (images.length > 1) _Gallery(images: images),
                    if (images.length > 1) const SizedBox(height: 14),
                    _Section(
                      title: 'Thông tin sử dụng',
                      child: Column(
                        children: [
                          _RowKV(label: 'Ngày dùng', value: dateUseLabel),
                          _RowKV(label: 'Đặt lúc', value: createdLabel),
                          _RowKV(label: 'Số lượng', value: '$qty'),
                          _RowKV(label: 'Sức chứa tối đa', value: maxCap > 0 ? '$maxCap' : '—'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Thanh toán',
                      child: Column(
                        children: [
                          _RowKV(
                            label: 'Đơn giá niêm yết',
                            value:
                                '${formatVnd(price)}${type == 'ACCOMMODATION' ? '/đêm' : type == 'FOOD' ? '/suất' : ''}',
                          ),
                          _RowKV(label: 'Thành tiền', value: formatVnd(total), highlight: true),
                          if (gid != null && gid.isNotEmpty) _RowKV(label: 'Nhóm combo', value: gid),
                        ],
                      ),
                    ),
                    if (combo != null) ...[
                      const SizedBox(height: 12),
                      _ComboSection(combo: combo),
                    ],
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Khách đặt',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RowKV(label: 'Họ tên', value: customerName),
                          _RowKV(label: 'SĐT', value: customerPhone.isEmpty ? '—' : customerPhone),
                          if (customerNote.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.black.withValues(alpha: 0.18),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                              ),
                              child: Text('Ghi chú: $customerNote', style: const TextStyle(height: 1.25)),
                            ),
                          ],
                          if (customerPhone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _copyPhone(context, customerPhone),
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Copy số khách'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Nhà cung cấp',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RowKV(label: 'Tên', value: providerName.isEmpty ? '—' : providerName),
                          _RowKV(label: 'SĐT', value: providerPhone.isEmpty ? '—' : providerPhone),
                          _RowKV(label: 'Địa chỉ', value: providerAddr.isEmpty ? '—' : providerAddr),
                          if (providerPhone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _copyPhone(context, providerPhone),
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Copy SĐT NCC'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Section(
                        title: 'Mô tả dịch vụ',
                        child: Text(desc, style: const TextStyle(color: Color(0xFFE6EEF8), height: 1.35)),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (_canCancel)
                SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cancelling ? null : () => _confirmCancel(context),
                      icon: _cancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: Text(_cancelling ? 'Đang hủy…' : 'Hủy đặt chỗ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8A80),
                        side: const BorderSide(color: Color(0x66E57373)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopSummary extends StatelessWidget {
  const _TopSummary({
    required this.accent,
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.typeLabel,
    required this.providerName,
    required this.heroUrl,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String statusLabel;
  final String typeLabel;
  final String providerName;
  final String? heroUrl;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            const Color(0xFF152A3D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: heroUrl != null
                  ? SafeNetworkImage(
                      url: heroUrl!,
                      height: 92,
                      width: 128,
                      fit: BoxFit.cover,
                      errorWidget: _HeroFallback(accent: accent, icon: icon),
                    )
                  : _HeroFallback(accent: accent, icon: icon),
            ),
            const SizedBox(width: 14),
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
                          color: accent.withValues(alpha: 0.16),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(statusLabel, style: TextStyle(fontWeight: FontWeight.w900, color: accent)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          typeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFA0B4C8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, height: 1.2),
                  ),
                  if (providerName.isNotEmpty) ...[
                    const SizedBox(height: 8),
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
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.accent, required this.icon});
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: 128,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.32), const Color(0xFF0F2232)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.90), size: 38),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SafeNetworkImage(
            url: images[i],
            width: 108,
            height: 72,
            fit: BoxFit.cover,
            errorWidget: _bookingDetailImageError(108, 72),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.055),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _RowKV extends StatelessWidget {
  const _RowKV({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final vStyle = highlight
        ? const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF2C94C))
        : const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE6EEF8));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Color(0xFFA0B4C8), height: 1.25)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.right, style: vStyle),
          ),
        ],
      ),
    );
  }
}

class _ComboSection extends StatelessWidget {
  const _ComboSection({required this.combo});
  final Map<String, dynamic> combo;

  @override
  Widget build(BuildContext context) {
    final hotel = (combo['hotel'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final food = (combo['food'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final discount = (combo['discountPercent'] as num?)?.toInt() ?? 10;
    final title = (combo['title'] as String?) ?? '';
    final hotelImages = (hotel['images'] as List?)?.whereType<String>().toList(growable: false) ?? const <String>[];
    final foodImages = (food['images'] as List?)?.whereType<String>().toList(growable: false) ?? const <String>[];

    return _Section(
      title: 'Combo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('-$discount%  ${title.isEmpty ? '' : '• $title'}', style: const TextStyle(color: Color(0xFFA0B4C8))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Mini(
                  title: 'Khách sạn',
                  name: (hotel['name'] as String?) ?? '—',
                  imageUrl: hotelImages.isNotEmpty ? hotelImages.first : null,
                  accent: const Color(0xFF4A90C4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Mini(
                  title: 'Ăn uống',
                  name: (food['name'] as String?) ?? '—',
                  imageUrl: foodImages.isNotEmpty ? foodImages.first : null,
                  accent: const Color(0xFFE8834A),
                ),
              ),
            ],
          ),
          if (hotelImages.length + foodImages.length > 2) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...hotelImages.take(2).map((src) => _Thumb(src: src)),
                  ...foodImages.take(2).map((src) => _Thumb(src: src)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.title, required this.name, required this.imageUrl, required this.accent});
  final String title;
  final String name;
  final String? imageUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? SafeNetworkImage(
                      url: imageUrl!,
                      height: 44,
                      width: 44,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        height: 44,
                        width: 44,
                        color: accent.withValues(alpha: 0.20),
                        alignment: Alignment.center,
                        child: Icon(Icons.image_not_supported_outlined, size: 20, color: accent.withValues(alpha: 0.5)),
                      ),
                    )
                  : Container(
                      height: 44,
                      width: 44,
                      color: accent.withValues(alpha: 0.20),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_rounded, size: 20),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.src});
  final String src;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SafeNetworkImage(
          url: src,
          width: 88,
          height: 58,
          fit: BoxFit.cover,
          errorWidget: _bookingDetailImageError(88, 58),
        ),
      ),
    );
  }
}
