import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_services/bvc_services.dart';
import 'package:bvc_ui/bvc_ui.dart';

import '../providers/public_booking_providers.dart';

const Color _kMuted = Color(0xFFA0B4C8);
const Color _kGold = Color(0xFFF2C94C);

class BookServiceScreen extends ConsumerStatefulWidget {
  const BookServiceScreen({
    super.key,
    required this.title,
    required this.type,
    this.serviceId,
    this.serviceName,
  });

  final String title;
  final String type;
  final String? serviceId;
  final String? serviceName;

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _qty = TextEditingController(text: '1');
  late String _dateYmd;

  bool _submitting = false;
  String? _pickedServiceId;

  Color get _accent => widget.type == 'ACCOMMODATION'
      ? const Color(0xFF4A90C4)
      : widget.type == 'FOOD'
          ? const Color(0xFFE8834A)
          : Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _dateYmd = ymd(DateTime.now().add(const Duration(days: 1)));
    _pickedServiceId = widget.serviceId;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    _qty.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 22, color: _accent.withValues(alpha: 0.9)) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _accent.withValues(alpha: 0.65), width: 1.4)),
      labelStyle: const TextStyle(color: _kMuted, fontWeight: FontWeight.w600),
    );
  }

  Future<void> _submit(String? serviceId) async {
    if (serviceId == null || serviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có dịch vụ để đặt.')));
      return;
    }
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập tên và SĐT.')));
      return;
    }
    final q = int.tryParse(_qty.text.trim()) ?? 1;
    if (q <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số lượng phải >= 1.')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(publicBookingRepositoryProvider);
    setState(() => _submitting = true);
    try {
      await repo.createBooking(<String, dynamic>{
        'serviceId': serviceId,
        'date': _dateYmd,
        'quantity': q,
        'customerName': name,
        'customerPhone': phone,
        if (_note.text.trim().isNotEmpty) 'customerNote': _note.text.trim(),
      });
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu đặt chỗ.')));
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(formatDioError(e))));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _form({required String? serviceId, required ServiceItem? picked, required List<ServiceItem> all}) {
    final q = int.tryParse(_qty.text.trim()) ?? 1;
    final estTotal = (picked?.price ?? 0) * (q <= 0 ? 1 : q);
    final unit = (picked?.type == 'ACCOMMODATION')
        ? '/đêm'
        : (picked?.type == 'FOOD')
            ? '/suất'
            : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (picked != null) ...[
          _ServicePreview(item: picked, accent: _accent),
          const SizedBox(height: 16),
        ],
        if (all.length > 1) ...[
          _SectionLabel(icon: Icons.apps_rounded, title: 'Chọn dịch vụ', accent: _accent),
          const SizedBox(height: 10),
          _BookGlassCard(
            child: DropdownButtonFormField<String>(
              value: serviceId,
              dropdownColor: const Color(0xFF1A2D3E),
              decoration: _dec('Dịch vụ', icon: Icons.list_alt_rounded),
              items: all
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (v) => setState(() => _pickedServiceId = v),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _SectionLabel(icon: Icons.event_rounded, title: 'Thời gian & số lượng', accent: _accent),
        const SizedBox(height: 10),
        _BookGlassCard(
          child: Column(
            children: [
              YmdPickerFormField(
                ymdValue: _dateYmd,
                onChanged: (v) => setState(() => _dateYmd = v),
                decoration: _dec('Ngày', icon: Icons.edit_calendar_rounded),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: _dec('Số lượng', icon: Icons.numbers_rounded),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        if (picked != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [_accent.withValues(alpha: 0.14), const Color(0xFF1A2D3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _accent.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: _kGold, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tạm tính', style: TextStyle(color: _kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        formatVnd(estTotal),
                        style: const TextStyle(color: _kGold, fontWeight: FontWeight.w900, fontSize: 22),
                      ),
                      Text(
                        '${formatVnd(picked.price)}$unit × ${q <= 0 ? 1 : q}',
                        style: const TextStyle(color: _kMuted, fontSize: 12, height: 1.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _SectionLabel(icon: Icons.person_rounded, title: 'Thông tin của bạn', accent: _accent),
        const SizedBox(height: 10),
        _BookGlassCard(
          child: Column(
            children: [
              TextField(controller: _name, decoration: _dec('Họ tên', icon: Icons.badge_outlined)),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _dec('Số điện thoại', hint: 'Trùng SĐT tài khoản để tra cứu đơn', icon: Icons.phone_android_rounded),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: _dec('Ghi chú', hint: 'Tuỳ chọn', icon: Icons.notes_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting ? null : () => _submit(serviceId),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_submitting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else ...[
                const Icon(Icons.send_rounded, size: 22),
                const SizedBox(width: 8),
              ],
              Text(_submitting ? 'Đang gửi…' : 'Gửi đặt chỗ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accommodationEntry(BuildContext context) {
    final async = ref.watch(servicesByTypeProvider('ACCOMMODATION'));
    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text(widget.title),
            centerTitle: true,
          ),
          body: async.when(
            loading: () => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4A90C4)),
                  SizedBox(height: 16),
                  Text('Đang tải…', style: TextStyle(color: _kMuted)),
                ],
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: _kMuted)),
              ),
            ),
            data: (items) {
              if (widget.serviceId != null) {
                final id = widget.serviceId!;
                final exists = items.any((x) => x.id == id);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(
                      exists ? (widget.serviceName ?? 'Cơ sở lưu trú') : 'Không tìm thấy dịch vụ',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Đặt theo loại phòng và số phòng còn trống trong ngày — giống app đặt phòng thông dụng.',
                      style: TextStyle(color: _kMuted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    if (exists) ...[
                      FilledButton(
                        onPressed: () => context.push('/book/accommodation/$id?date=${Uri.encodeComponent(_dateYmd)}'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Đặt phòng (chọn loại phòng)', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push('/services/accommodation/$id'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: _accent,
                          side: BorderSide(color: _accent.withValues(alpha: 0.5)),
                        ),
                        child: const Text('Xem chi tiết & ảnh'),
                      ),
                    ],
                  ],
                );
              }
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa có cơ sở lưu trú.', textAlign: TextAlign.center, style: TextStyle(color: _kMuted)),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const Text('Chọn cơ sở', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Mỗi nơi có các loại phòng (đơn, đôi, gia đình…) và giá theo phòng/đêm. Bạn chọn ngày và số phòng ở bước sau.',
                    style: TextStyle(color: _kMuted, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  ...items.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/services/accommodation/${s.id}'),
                          borderRadius: BorderRadius.circular(20),
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Từ ${formatVnd(s.price)}/đêm',
                                        style: TextStyle(color: _accent.withValues(alpha: 0.95), fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: _accent.withValues(alpha: 0.9)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'ACCOMMODATION') {
      return _accommodationEntry(context);
    }

    Widget body(AsyncValue<List<ServiceItem>> async) {
      return async.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF4A90C4)),
              SizedBox(height: 16),
              Text('Đang tải dịch vụ…', style: TextStyle(color: _kMuted)),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: _kMuted)),
          ),
        ),
        data: (items) {
          if (widget.serviceId != null) {
            final picked = items.firstWhereOrNull((x) => x.id == widget.serviceId);
            return _form(serviceId: widget.serviceId, picked: picked, all: items);
          }
          final effectiveId = (_pickedServiceId != null && items.any((x) => x.id == _pickedServiceId))
              ? _pickedServiceId
              : (items.isNotEmpty ? items.first.id : null);
          final picked = effectiveId == null ? null : items.firstWhere((x) => x.id == effectiveId);
          return _form(serviceId: effectiveId, picked: picked, all: items);
        },
      );
    }

    if (widget.serviceId != null) {
      final async = ref.watch(servicesByTypeProvider(widget.type));
      return Stack(
        children: [
          const Positioned.fill(child: WavesBackground()),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: Text(widget.title),
              centerTitle: true,
            ),
            body: body(async),
          ),
        ],
      );
    }

    final async = ref.watch(servicesByTypeProvider(widget.type));
    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text(widget.title),
            centerTitle: true,
          ),
          body: body(async),
        ),
      ],
    );
  }
}

extension FirstWhereOrNullX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final x in this) {
      if (test(x)) return x;
    }
    return null;
  }
}

class _BookGlassCard extends StatelessWidget {
  const _BookGlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title, required this.accent});
  final IconData icon;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: accent.withValues(alpha: 0.95)),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ],
    );
  }
}

class _ServicePreview extends StatelessWidget {
  const _ServicePreview({required this.item, required this.accent});
  final ServiceItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.18), const Color(0xFF1A2D3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: item.images.isNotEmpty
                  ? SafeNetworkImage(
                      url: item.images.first,
                      height: 88,
                      width: 108,
                      fit: BoxFit.cover,
                      errorWidget: _PreviewFallback(accent: accent),
                    )
                  : _PreviewFallback(accent: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (item.providerName != null && item.providerName!.isNotEmpty)
                    Text(item.providerName!, style: const TextStyle(color: _kMuted, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kMuted, height: 1.25, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      width: 108,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.28), const Color(0xFF0F2232)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_rounded, color: Colors.white.withValues(alpha: 0.75)),
    );
  }
}
