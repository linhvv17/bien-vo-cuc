import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_services/bvc_services.dart';
import 'package:bvc_ui/bvc_ui.dart';
import 'package:dio/dio.dart';
import 'package:bvc_network/bvc_network.dart';

import '../providers/public_booking_providers.dart';

IconData _iconForServiceType(String? type) {
  switch (type) {
    case 'ACCOMMODATION':
      return Icons.holiday_village_rounded;
    case 'FOOD':
      return Icons.restaurant_rounded;
    case 'VEHICLE':
      return Icons.directions_car_rounded;
    case 'TOUR':
      return Icons.explore_rounded;
    default:
      return Icons.waves_rounded;
  }
}

String _quantityFieldLabel(String? type) {
  switch (type) {
    case 'VEHICLE':
    case 'TOUR':
      return 'Số chuyến';
    default:
      return 'Số người';
  }
}

IconData _quantityFieldIcon(String? type) {
  switch (type) {
    case 'VEHICLE':
      return Icons.airport_shuttle_rounded;
    case 'TOUR':
      return Icons.route_rounded;
    default:
      return Icons.groups_rounded;
  }
}

/// Hiển thị giá trị quantity đúng đơn vị (chuyến / người) — khớp cách API tính tổng.
String _quantityDisplay(String? type, int quantity) {
  final q = quantity < 1 ? 1 : quantity;
  switch (type) {
    case 'VEHICLE':
    case 'TOUR':
      return q == 1 ? '1 chuyến' : '$q chuyến';
    default:
      return '$q người';
  }
}

/// Gợi ý mặc định khi đổi loại dịch vụ (đêm/chuyến thường 1; ăn uống theo suất/người).
int _defaultQuantityForType(String? type) {
  switch (type) {
    case 'FOOD':
      return 2;
    default:
      return 1;
  }
}

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0; // 0..2
  ServiceItem? _picked;
  String _date = '';
  int _quantity = 1;
  final _name = TextEditingController(text: 'Nguyễn Văn A');
  final _phone = TextEditingController(text: '0912 345 678');
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _date = ymdAddCalendarDays(ymdVietnamToday(), 1);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = ref.watch(servicesByTypeProvider('FOOD')).maybeWhen(data: (v) => v, orElse: () => const <ServiceItem>[]);
    final vehicle = ref.watch(servicesByTypeProvider('VEHICLE')).maybeWhen(data: (v) => v, orElse: () => const <ServiceItem>[]);
    final tour = ref.watch(servicesByTypeProvider('TOUR')).maybeWhen(data: (v) => v, orElse: () => const <ServiceItem>[]);

    /// Lưu trú đặt theo phòng/loại phòng — dùng tab Ăn & Ở → chi tiết (giống OTA), không gộp vào form chung.
    final all = <ServiceItem>[...food, ...vehicle, ...tour];

    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Đặt dịch vụ'),
            leading: _step == 0
                ? null
                : IconButton(
                    onPressed: () => setState(() => _step = (_step - 1).clamp(0, 2)),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _StepperHeader(step: _step),
              const SizedBox(height: 12),
              if (_step == 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.holiday_village_rounded, size: 20, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          const Text(
                            'Đặt phòng / homestay',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Chọn ngày, loại phòng và số phòng — vào tab Ăn & Ở, mở cơ sở lưu trú rồi bấm đặt.',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 12, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => ref.read(shellTabIndexProvider.notifier).setTab(1),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Mở danh sách lưu trú'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Chọn dịch vụ (ăn uống, xe, tour):', style: TextStyle(color: AppColors.mutedForeground)),
                const SizedBox(height: 12),
                if (all.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Chưa có dịch vụ trên hệ thống. Thử tải lại hoặc kiểm tra kết nối.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedForeground),
                    ),
                  )
                else
                  ...all.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PickTile(
                          item: s,
                          selected: _picked?.id == s.id,
                          onTap: () => setState(() {
                            final prevType = _picked?.type;
                            _picked = s;
                            if (prevType != s.type) {
                              _quantity = _defaultQuantityForType(s.type);
                            }
                          }),
                        ),
                      )),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _picked == null || all.isEmpty ? null : () => setState(() => _step = 1),
                  child: const Text('Tiếp tục'),
                ),
              ] else if (_step == 1) ...[
                if (_picked != null) _PickedSummary(item: _picked!),
                const SizedBox(height: 12),
                _Field(
                  icon: Icons.event_rounded,
                  label: 'Ngày',
                  child: YmdPickerFormField(
                    ymdValue: _date,
                    onChanged: (v) => setState(() => _date = v),
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(height: 12),
                _Field(
                  icon: _quantityFieldIcon(_picked?.type),
                  label: _quantityFieldLabel(_picked?.type),
                  child: DropdownButtonFormField<int>(
                    value: _quantity.clamp(
                      1,
                      _picked?.type == 'ACCOMMODATION' ? 30 : 10,
                    ),
                    items: () {
                      final t = _picked?.type;
                      final max = t == 'ACCOMMODATION' ? 30 : 10;
                      return List.generate(max, (i) => i + 1)
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(_quantityDisplay(t, v)),
                            ),
                          )
                          .toList();
                    }(),
                    onChanged: (v) => setState(() => _quantity = v ?? 1),
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(height: 12),
                _Field(
                  icon: Icons.person_rounded,
                  label: 'Họ tên',
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(height: 12),
                _Field(
                  icon: Icons.phone_rounded,
                  label: 'Số điện thoại',
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _picked == null ? null : () => setState(() => _step = 2),
                  child: const Text('Xác nhận'),
                ),
              ] else ...[
                _ConfirmCard(
                  item: _picked,
                  date: _date,
                  quantity: _quantity,
                  name: _name.text.trim(),
                  phone: _phone.text.trim(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(_submitting ? 'Đang gửi…' : 'Gửi đặt dịch vụ'),
                  onPressed: _submitting
                      ? null
                      : () async {
                          final picked = _picked;
                          if (picked == null) return;
                          final name = _name.text.trim();
                          final phone = _phone.text.trim();
                          final messenger = ScaffoldMessenger.of(context);
                          if (name.isEmpty || phone.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập Họ tên và Số điện thoại.')),
                            );
                            return;
                          }
                          setState(() => _submitting = true);
                          try {
                            final repo = ref.read(publicBookingRepositoryProvider);
                            await repo.createBooking(<String, dynamic>{
                              'serviceId': picked.id,
                              'date': _date,
                              'quantity': _quantity < 1 ? 1 : _quantity,
                              'customerName': name,
                              'customerPhone': phone,
                            });
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Đã gửi yêu cầu đặt dịch vụ.')),
                            );
                            setState(() {
                              _step = 0;
                              _picked = null;
                            });
                          } on DioException catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text(formatDioError(e))),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(SnackBar(content: Text('$e')));
                          } finally {
                            if (mounted) setState(() => _submitting = false);
                          }
                        },
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: () => setState(() {
                    _step = 0;
                    _picked = null;
                  }),
                  child: const Text('Đặt lại từ đầu'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperHeader extends StatelessWidget {
  const _StepperHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool active) => Expanded(
          child: Column(
            children: [
              Text(label, style: TextStyle(color: active ? AppColors.primary : AppColors.mutedForeground, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${step + 1}/3', style: const TextStyle(color: AppColors.mutedForeground)),
        const SizedBox(height: 8),
        Row(
          children: [
            seg('Chọn dịch vụ', step == 0),
            const SizedBox(width: 10),
            seg('Chi tiết', step == 1),
            const SizedBox(width: 10),
            seg('Xác nhận', step == 2),
          ],
        ),
      ],
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({required this.item, required this.selected, required this.onTap});
  final ServiceItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.x2l),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadii.x2l),
            border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.65) : AppColors.border.withValues(alpha: 0.55), width: selected ? 1.4 : 1),
            boxShadow: selected ? AppShadows.gold : null,
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadii.base),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
                ),
                child: const Icon(Icons.waves_rounded, color: AppColors.mutedForeground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('${formatVnd(item.price)} VND/${item.type == 'ACCOMMODATION' ? 'đêm' : item.type == 'FOOD' ? 'người' : 'chuyến'}',
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  ],
                ),
              ),
              if (selected)
                Container(
                  height: 28,
                  width: 28,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.background, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickedSummary extends StatelessWidget {
  const _PickedSummary({required this.item});
  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.x2l),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dịch vụ đã chọn', style: TextStyle(color: AppColors.mutedForeground)),
          const SizedBox(height: 6),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text('${formatVnd(item.price)} VND/${item.type == 'ACCOMMODATION' ? 'đêm' : 'người'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.label, required this.child});
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.mutedForeground),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.mutedForeground)),
          ],
        ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.card.withValues(alpha: 0.55),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.base)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.base), borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.55))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.base), borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.item,
    required this.date,
    required this.quantity,
    required this.name,
    required this.phone,
  });
  final ServiceItem? item;
  final String date;
  final int quantity;
  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final q = quantity < 1 ? 1 : quantity;
    final total = (item?.price ?? 0) * q;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.x2l),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.x2l),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.card.withValues(alpha: 0.92),
              AppColors.oceanDeep.withValues(alpha: 0.42),
              AppColors.surface.withValues(alpha: 0.75),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          boxShadow: AppShadows.gold,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -36,
              top: -28,
              child: IgnorePointer(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -24,
              bottom: 80,
              child: IgnorePointer(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.35),
                              AppColors.secondary.withValues(alpha: 0.22),
                            ],
                          ),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 18,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.38)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 17, color: AppColors.warning),
                        SizedBox(width: 5),
                        Text(
                          'Bản nháp — chưa gửi',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tóm tắt đặt chỗ',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Xem lại thông tin. Để hoàn tất, nhấn nút vàng bên dưới.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedForeground, height: 1.4, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadii.base),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.w600, height: 1.38),
                        children: [
                          const TextSpan(text: 'Nút '),
                          TextSpan(
                            text: 'Gửi đặt dịch vụ',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                          ),
                          const TextSpan(text: ' mới gửi yêu cầu đến Biển vô cực.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
                    ),
                    child: Column(
                      children: [
                        _ConfirmDetailRow(
                          icon: _iconForServiceType(item?.type),
                          label: 'Dịch vụ',
                          value: item?.name ?? '—',
                        ),
                        Divider(height: 20, thickness: 1, color: AppColors.border.withValues(alpha: 0.45)),
                        _ConfirmDetailRow(
                          icon: Icons.event_available_rounded,
                          label: 'Ngày',
                          value: date,
                        ),
                        Divider(height: 20, thickness: 1, color: AppColors.border.withValues(alpha: 0.45)),
                        _ConfirmDetailRow(
                          icon: _quantityFieldIcon(item?.type),
                          label: _quantityFieldLabel(item?.type),
                          value: _quantityDisplay(item?.type, quantity),
                        ),
                        Divider(height: 20, thickness: 1, color: AppColors.border.withValues(alpha: 0.45)),
                        _ConfirmDetailRow(
                          icon: Icons.person_rounded,
                          label: 'Liên hệ',
                          value: name.isEmpty ? '—' : name,
                        ),
                        Divider(height: 20, thickness: 1, color: AppColors.border.withValues(alpha: 0.45)),
                        _ConfirmDetailRow(
                          icon: Icons.phone_in_talk_rounded,
                          label: 'SĐT',
                          value: phone.isEmpty ? '—' : phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.14),
                        ],
                      ),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: const Icon(Icons.payments_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tổng tạm tính',
                                style: TextStyle(
                                  color: AppColors.mutedForeground.withValues(alpha: 0.95),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${formatVnd(item?.price ?? 0)} × ${_quantityDisplay(item?.type, q)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatVnd(total),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
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

class _ConfirmDetailRow extends StatelessWidget {
  const _ConfirmDetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: Icon(icon, color: AppColors.oceanLight, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.mutedForeground.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.25),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
