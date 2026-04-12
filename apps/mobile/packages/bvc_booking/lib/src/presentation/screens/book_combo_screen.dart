import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_ui/bvc_ui.dart';

import '../providers/public_booking_providers.dart';

const Color _kMuted = Color(0xFFA0B4C8);
const Color _kGold = Color(0xFFF2C94C);
const Color _kBlue = Color(0xFF4A90C4);
const Color _kOrange = Color(0xFFE8834A);

class BookComboScreen extends ConsumerStatefulWidget {
  const BookComboScreen({super.key, required this.comboId});

  final String comboId;

  @override
  ConsumerState<BookComboScreen> createState() => _BookComboScreenState();
}

class _BookComboScreenState extends ConsumerState<BookComboScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _qty = TextEditingController(text: '1');
  late String _dateYmd;

  bool _submitting = false;
  Map<String, dynamic>? _combo;
  bool _loadingCombo = false;
  String? _comboError;

  @override
  void initState() {
    super.initState();
    _dateYmd = ymd(DateTime.now().add(const Duration(days: 1)));
    _loadCombo();
  }

  Future<void> _loadCombo() async {
    final network = ref.read(networkServiceProvider);
    setState(() {
      _loadingCombo = true;
      _comboError = null;
    });
    try {
      final res = await network.get<Map<String, dynamic>>('/combos');
      final body = parseApiResponse<List<dynamic>>(res.data ?? const {}, (data) => (data as List<dynamic>? ?? const []));
      final found = body.data.whereType<Map>().map((e) => e.cast<String, dynamic>()).firstWhere(
            (e) => e['id'] == widget.comboId,
            orElse: () => const <String, dynamic>{},
          );
      if (!mounted) return;
      setState(() => _combo = found.isEmpty ? null : found);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _comboError = formatDioError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _comboError = '$e');
    } finally {
      if (mounted) setState(() => _loadingCombo = false);
    }
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
      prefixIcon: icon != null ? Icon(icon, size: 22, color: _kGold.withValues(alpha: 0.95)) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _kGold.withValues(alpha: 0.55), width: 1.4)),
      labelStyle: const TextStyle(color: _kMuted, fontWeight: FontWeight.w600),
    );
  }

  Future<void> _submit() async {
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
      await repo.createComboBooking(<String, dynamic>{
        'comboId': widget.comboId,
        'date': _dateYmd,
        'quantity': q,
        'customerName': name,
        'customerPhone': phone,
        if (_note.text.trim().isNotEmpty) 'customerNote': _note.text.trim(),
      });
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Đã gửi đặt combo (2 dịch vụ).')));
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

  @override
  Widget build(BuildContext context) {
    final combo = _combo;
    final hotel = (combo?['hotel'] as Map?)?.cast<String, dynamic>();
    final food = (combo?['food'] as Map?)?.cast<String, dynamic>();
    final discount = (combo?['discountPercent'] as num?)?.toInt() ?? 10;
    final hotelPrice = (hotel?['price'] as num?)?.toInt() ?? 0;
    final foodPrice = (food?['price'] as num?)?.toInt() ?? 0;
    final original = hotelPrice + foodPrice;
    final q = int.tryParse(_qty.text.trim()) ?? 1;
    final qty = q <= 0 ? 1 : q;
    final discounted = (original * qty * (100 - discount) / 100).round();

    Widget body;
    if (_loadingCombo) {
      body = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kGold),
            SizedBox(height: 16),
            Text('Đang tải combo…', style: TextStyle(color: _kMuted)),
          ],
        ),
      );
    } else if (_comboError != null) {
      body = Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            _ComboGlassCard(
              child: Column(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 44, color: Colors.orange.shade300),
                  const SizedBox(height: 12),
                  Text(_comboError!, textAlign: TextAlign.center, style: const TextStyle(color: _kMuted, height: 1.35)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadCombo,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kGold.withValues(alpha: 0.25),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (combo == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ComboGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded, size: 48, color: _kMuted),
                const SizedBox(height: 12),
                Text('Không tìm thấy combo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('ID: ${widget.comboId}', style: const TextStyle(color: _kMuted, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _ComboPreview(combo: combo),
          const SizedBox(height: 20),
          _ComboSectionLabel(icon: Icons.event_rounded, title: 'Ngày & số lượng'),
          const SizedBox(height: 10),
          _ComboGlassCard(
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
                  decoration: _dec('Số lượng combo', icon: Icons.numbers_rounded),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          if (original > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [_kGold.withValues(alpha: 0.12), const Color(0xFF1A2D3E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _kGold.withValues(alpha: 0.28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_offer_rounded, color: _kGold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tạm tính sau giảm', style: TextStyle(color: _kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(formatVnd(discounted), style: const TextStyle(color: _kGold, fontWeight: FontWeight.w900, fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(
                          'Giá gốc ${formatVnd(original * qty)}  ·  −$discount%',
                          style: const TextStyle(color: _kMuted, fontSize: 12, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _ComboSectionLabel(icon: Icons.person_rounded, title: 'Thông tin của bạn'),
          const SizedBox(height: 10),
          _ComboGlassCard(
            child: Column(
              children: [
                TextField(controller: _name, decoration: _dec('Họ tên', icon: Icons.badge_outlined)),
                const SizedBox(height: 14),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('Số điện thoại', hint: 'Trùng SĐT tài khoản', icon: Icons.phone_android_rounded),
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
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _kGold.withValues(alpha: 0.92),
              foregroundColor: const Color(0xFF0D1B2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_submitting)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF0D1B2A)),
                  )
                else ...[
                  const Icon(Icons.restaurant_menu_rounded, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(
                  _submitting ? 'Đang gửi…' : 'Gửi đặt combo',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: const Text('Đặt combo'),
            centerTitle: true,
          ),
          body: body,
        ),
      ],
    );
  }
}

class _ComboGlassCard extends StatelessWidget {
  const _ComboGlassCard({required this.child});
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

class _ComboSectionLabel extends StatelessWidget {
  const _ComboSectionLabel({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _kGold.withValues(alpha: 0.95)),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ],
    );
  }
}

class _ComboPreview extends StatelessWidget {
  const _ComboPreview({required this.combo});
  final Map<String, dynamic> combo;

  @override
  Widget build(BuildContext context) {
    final hotel = (combo['hotel'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final food = (combo['food'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final discount = (combo['discountPercent'] as num?)?.toInt() ?? 10;
    final title = (combo['title'] as String?) ?? '';

    final hotelImages = (hotel['images'] as List?)?.whereType<String>().toList(growable: false) ?? const <String>[];
    final foodImages = (food['images'] as List?)?.whereType<String>().toList(growable: false) ?? const <String>[];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            _kGold.withValues(alpha: 0.16),
            _kOrange.withValues(alpha: 0.12),
            const Color(0xFF1A2D3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _kGold.withValues(alpha: 0.22),
                    border: Border.all(color: _kGold.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.percent_rounded, size: 16, color: _kGold),
                      const SizedBox(width: 4),
                      Text('−$discount%', style: const TextStyle(fontWeight: FontWeight.w900, color: _kGold, fontSize: 14)),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.layers_rounded, color: Colors.white.withValues(alpha: 0.5), size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title.isEmpty ? 'Combo 2 dịch vụ' : title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, height: 1.2),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniService(
                    accent: _kBlue,
                    icon: Icons.hotel_rounded,
                    title: 'Lưu trú',
                    name: (hotel['name'] as String?) ?? '—',
                    imageUrl: hotelImages.isNotEmpty ? hotelImages.first : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniService(
                    accent: _kOrange,
                    icon: Icons.restaurant_rounded,
                    title: 'Ăn uống',
                    name: (food['name'] as String?) ?? '—',
                    imageUrl: foodImages.isNotEmpty ? foodImages.first : null,
                  ),
                ),
              ],
            ),
            if (hotelImages.length + foodImages.length > 2) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 60,
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
      ),
    );
  }
}

class _MiniService extends StatelessWidget {
  const _MiniService({
    required this.accent,
    required this.icon,
    required this.title,
    required this.name,
    required this.imageUrl,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.2),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
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
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover,
                      errorWidget: _MiniFallback(accent: accent, icon: icon),
                    )
                  : _MiniFallback(accent: accent, icon: icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: accent.withValues(alpha: 0.95), fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniFallback extends StatelessWidget {
  const _MiniFallback({required this.accent, required this.icon});
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.35), const Color(0xFF0F2232)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 22),
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
          width: 92,
          height: 60,
          fit: BoxFit.cover,
          errorWidget: Container(
            width: 92,
            height: 60,
            color: const Color(0xFF1A2D3E),
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined, size: 22, color: Color(0x44FFFFFF)),
          ),
        ),
      ),
    );
  }
}
