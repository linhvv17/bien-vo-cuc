import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_services/bvc_services.dart';
import 'package:bvc_ui/bvc_ui.dart';

import '../providers/public_booking_providers.dart';

/// Đặt phòng: theo loại (đoàn) hoặc một phòng ngẫu nhiên / chọn phòng + tiêu chí.
class AccommodationBookingScreen extends ConsumerStatefulWidget {
  const AccommodationBookingScreen({
    super.key,
    required this.serviceId,
    required this.dateYmd,
    this.initialRoomLines,
  });

  final String serviceId;
  final String dateYmd;

  /// Từ màn chi tiết: map `roomType` → số phòng đã chọn.
  final Map<String, int>? initialRoomLines;

  @override
  ConsumerState<AccommodationBookingScreen> createState() => _AccommodationBookingScreenState();
}

const Color _kAccent = Color(0xFF4A90C4);
const Color _kMuted = Color(0xFFA0B4C8);
const Color _kGold = Color(0xFFF2C94C);

class _AccommodationBookingScreenState extends ConsumerState<AccommodationBookingScreen> {
  late String _dateYmd;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  final Set<String> _prefs = {};

  bool _submitting = false;

  /// Số phòng theo loại (chế độ đoàn).
  final Map<String, int> _roomQty = {};
  String? _roomQtySyncedKey;

  @override
  void initState() {
    super.initState();
    final parsed = parseYmd(widget.dateYmd.trim());
    _dateYmd = parsed != null ? ymd(parsed) : ymd(DateTime.now().add(const Duration(days: 1)));
    final init = widget.initialRoomLines;
    if (init != null) {
      for (final e in init.entries) {
        if (e.value > 0) _roomQty[e.key] = e.value;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  ({String serviceId, String dateYmd}) get _detailKey => (serviceId: widget.serviceId, dateYmd: _dateYmd);

  /// Cùng ngày lịch với [widget.dateYmd] (đã chuẩn hoá từ router).
  bool _sameCalendarDayAsRoute() {
    final a = parseYmd(_dateYmd.trim());
    final b = parseYmd(widget.dateYmd.trim());
    if (a != null && b != null) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }
    return _dateYmd.trim() == widget.dateYmd.trim();
  }

  void _setRoomQty(String roomType, int v, int maxAvail) {
    final next = v.clamp(0, maxAvail);
    setState(() {
      if (next == 0) {
        _roomQty.remove(roomType);
      } else {
        _roomQty[roomType] = next;
      }
    });
  }

  int _totalMultiRooms(AccommodationDetail d) {
    var n = 0;
    for (final g in d.effectiveRoomTypeGroups) {
      n += _roomQty[g.roomType] ?? 0;
    }
    return n;
  }

  int _estimateMultiVnd(AccommodationDetail d) {
    var sum = 0;
    for (final g in d.effectiveRoomTypeGroups) {
      sum += (_roomQty[g.roomType] ?? 0) * g.pricePerNight;
    }
    return sum;
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 22, color: _kAccent.withValues(alpha: 0.9)) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.65), width: 1.4)),
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

    final detail = await ref.read(accommodationDetailProvider(_detailKey).future);
    if (!mounted) return;

    final multi = detail.effectiveRoomTypeGroups.isNotEmpty;
    final lines = <Map<String, dynamic>>[];
    if (multi) {
      for (final g in detail.effectiveRoomTypeGroups) {
        final q = (_roomQty[g.roomType] ?? 0).clamp(0, g.availableCount);
        if (q > 0) lines.add({'roomType': g.roomType, 'quantity': q});
      }
      if (lines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn ít nhất một phòng.')),
        );
        return;
      }
    }

    final repo = ref.read(publicBookingRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'serviceId': widget.serviceId,
        'date': _dateYmd,
        'customerName': name,
        'customerPhone': phone,
        if (_note.text.trim().isNotEmpty) 'customerNote': _note.text.trim(),
        if (multi) ...{
          'roomLines': lines,
        } else ...{
          'quantity': 1,
        },
        if (_prefs.isNotEmpty) 'guestPreferences': _prefs.toList(),
      };

      await repo.createBooking(body);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Đã gửi đặt phòng.')));
      context.pop();
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
    final async = ref.watch(accommodationDetailProvider(_detailKey));

    ref.listen<AsyncValue<AccommodationDetail>>(accommodationDetailProvider(_detailKey), (previous, next) {
      next.whenData((detail) {
        final syncKey = '${widget.serviceId}|$_dateYmd';
        if (_roomQtySyncedKey == syncKey) return;
        setState(() {
          _roomQtySyncedKey = syncKey;
          _roomQty.clear();
          final init = widget.initialRoomLines;
          final applyInit = init != null && init.isNotEmpty && _sameCalendarDayAsRoute();
          for (final g in detail.effectiveRoomTypeGroups) {
            final raw = applyInit ? (init[g.roomType] ?? 0) : 0;
            final q = raw.clamp(0, g.availableCount);
            if (q > 0) _roomQty[g.roomType] = q;
          }
        });
      });
    });

    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: const Text('Đặt phòng'),
            centerTitle: true,
          ),
          body: async.when(
            loading: () => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _kAccent),
                  SizedBox(height: 16),
                  Text('Đang tải thông tin cơ sở…', style: TextStyle(color: _kMuted)),
                ],
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 40, color: Colors.orange.shade300),
                      const SizedBox(height: 12),
                      Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: _kMuted, height: 1.35)),
                    ],
                  ),
                ),
              ),
            ),
            data: (detail) {
              final s = detail.service;
              final groups = detail.effectiveRoomTypeGroups;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  const SizedBox(height: 8),
                  Text(
                    s.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, height: 1.25),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(icon: Icons.calendar_today_rounded, title: 'Ngày nhận phòng'),
                  const SizedBox(height: 10),
                  _GlassCard(
                    child: YmdPickerFormField(
                      ymdValue: _dateYmd,
                      onChanged: (v) => setState(() {
                        _dateYmd = v;
                        _roomQtySyncedKey = null;
                      }),
                      decoration: _dec('Ngày nhận phòng', icon: Icons.edit_calendar_rounded),
                    ),
                  ),
                  if (groups.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kAccent.withValues(alpha: 0.42)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: _kAccent.withValues(alpha: 0.95), size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Chọn số lượng phòng: bấm − hoặc + trong từng ô bên dưới (theo loại phòng còn trống).',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionTitle(icon: Icons.groups_rounded, title: 'Số phòng theo loại'),
                    const SizedBox(height: 6),
                    Text(
                      'Không vượt quá số phòng trống từng loại trong ngày đã chọn.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    ...groups.map((g) {
                      final q = _roomQty[g.roomType] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BookingRoomTypeCard(
                          group: g,
                          quantity: q,
                          onChanged: (v) => _setRoomQty(g.roomType, v, g.availableCount),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 18),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.images.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: SafeNetworkImage(
                                url: s.images.first,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: const Color(0xFF1A2D3E),
                                  alignment: Alignment.center,
                                  child: Icon(Icons.hotel_rounded, size: 48, color: _kAccent.withValues(alpha: 0.5)),
                                ),
                              ),
                            ),
                          ),
                        if (s.images.isNotEmpty) const SizedBox(height: 14),
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, height: 1.2)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.payments_rounded, size: 18, color: _kGold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                groups.isNotEmpty
                                    ? (_totalMultiRooms(detail) > 0
                                        ? '${formatVnd(_estimateMultiVnd(detail))} / đêm (ước tính)'
                                        : '${formatVnd(s.price)} / phòng / đêm (chọn số lượng ở trên)')
                                    : '${formatVnd(s.price)} / đêm',
                                style: const TextStyle(color: _kGold, fontWeight: FontWeight.w800, fontSize: 17),
                              ),
                            ),
                          ],
                        ),
                        if (s.addressLine != null && s.addressLine!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.place_outlined, size: 18, color: _kAccent.withValues(alpha: 0.95)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s.addressLine!, style: const TextStyle(color: _kMuted, height: 1.3))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (detail.preferenceOptions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionTitle(icon: Icons.tune_rounded, title: 'Ưu tiên (tuỳ chọn)'),
                    const SizedBox(height: 10),
                    _GlassCard(
                      child: Column(
                        children: detail.preferenceOptions.map((o) {
                          final on = _prefs.contains(o.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: on ? _kAccent.withValues(alpha: 0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (on) {
                                      _prefs.remove(o.key);
                                    } else {
                                      _prefs.add(o.key);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        on ? Icons.check_circle_rounded : Icons.circle_outlined,
                                        size: 22,
                                        color: on ? _kAccent : _kMuted,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(o.label, style: TextStyle(color: on ? Colors.white : _kMuted, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _SectionTitle(icon: Icons.person_rounded, title: 'Thông tin liên hệ'),
                  const SizedBox(height: 10),
                  _GlassCard(
                    child: Column(
                      children: [
                        TextField(controller: _name, decoration: _dec('Họ tên', icon: Icons.badge_outlined)),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: _dec('Số điện thoại', icon: Icons.phone_android_rounded),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _note,
                          maxLines: 3,
                          decoration: _dec('Ghi chú', hint: 'Giờ đến, yêu cầu đặc biệt…', icon: Icons.notes_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ||
                            (detail.effectiveRoomTypeGroups.isNotEmpty && _totalMultiRooms(detail) == 0)
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_submitting) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                        ] else ...[
                          const Icon(Icons.hotel_class_rounded, size: 22),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _submitting
                              ? 'Đang gửi…'
                              : detail.effectiveRoomTypeGroups.isNotEmpty
                                  ? (_totalMultiRooms(detail) == 0
                                      ? 'Chọn số phòng ở trên'
                                      : 'Xác nhận đặt ${_totalMultiRooms(detail)} phòng')
                                  : 'Xác nhận đặt 1 phòng',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
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
}

class _BookingRoomTypeCard extends StatelessWidget {
  const _BookingRoomTypeCard({
    required this.group,
    required this.quantity,
    required this.onChanged,
  });

  final RoomTypeGroup group;
  final int quantity;
  final ValueChanged<int> onChanged;

  static ButtonStyle _stepperBtn(Color bg) {
    return IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: bg,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = group.availableCount == 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bed_rounded, color: disabled ? _kMuted : _kAccent, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.labelVi,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disabled
                            ? 'Hết phòng loại này cho ngày đã chọn'
                            : 'Còn ${group.availableCount} phòng trống · tối đa ${group.maxGuests} khách/phòng',
                        style: TextStyle(color: disabled ? _kMuted : const Color(0xFF8FA8C0), fontSize: 12, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (disabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB71C1C).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Hết', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccent.withValues(alpha: 0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số lượng đặt',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: disabled || quantity <= 0 ? null : () => onChanged(quantity - 1),
                        icon: const Icon(Icons.remove_rounded, size: 22),
                        style: _stepperBtn(_kAccent.withValues(alpha: 0.28)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: disabled || quantity >= group.availableCount ? null : () => onChanged(quantity + 1),
                        icon: const Icon(Icons.add_rounded, size: 22),
                        style: _stepperBtn(_kAccent.withValues(alpha: 0.4)),
                      ),
                    ],
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _kAccent.withValues(alpha: 0.95)),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.2)),
      ],
    );
  }
}
