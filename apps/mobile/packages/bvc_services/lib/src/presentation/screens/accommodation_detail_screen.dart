import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_ui/bvc_ui.dart';

import '../../domain/accommodation_booking_args.dart';
import '../../domain/entities/accommodation_detail.dart';
import '../providers/services_providers.dart';

class AccommodationDetailScreen extends ConsumerStatefulWidget {
  const AccommodationDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<AccommodationDetailScreen> createState() => _AccommodationDetailScreenState();
}

const Color _kAccent = Color(0xFF4A90C4);
const Color _kMuted = Color(0xFFA0B4C8);
const Color _kGold = Color(0xFFF2C94C);

class _AccommodationDetailScreenState extends ConsumerState<AccommodationDetailScreen> {
  late String _dateYmd;
  final Map<String, int> _qtyByType = {};

  @override
  void initState() {
    super.initState();
    _dateYmd = ymdAddCalendarDays(ymdVietnamToday(), 1);
  }

  ({String serviceId, String dateYmd}) get _key => (serviceId: widget.serviceId, dateYmd: _dateYmd);

  int _totalRoomsPicked(AccommodationDetail data) {
    var n = 0;
    for (final g in data.effectiveRoomTypeGroups) {
      n += _qtyByType[g.roomType] ?? 0;
    }
    return n;
  }

  int _estimateTotalVnd(AccommodationDetail data) {
    var sum = 0;
    for (final g in data.effectiveRoomTypeGroups) {
      sum += (_qtyByType[g.roomType] ?? 0) * g.pricePerNight;
    }
    return sum;
  }

  void _setQty(String roomType, int v, int maxAvail) {
    final next = v.clamp(0, maxAvail);
    setState(() {
      if (next == 0) {
        _qtyByType.remove(roomType);
      } else {
        _qtyByType[roomType] = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(accommodationDetailProvider(_key));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chỗ nghỉ')),
      body: Stack(
        children: [
          const Positioned.fill(child: WavesBackground()),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: YmdPickerFormField(
                  ymdValue: _dateYmd,
                  onChanged: (v) => setState(() {
                    _dateYmd = v;
                    _qtyByType.clear();
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Ngày nhận phòng',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
                  data: (data) => _DetailScroll(
                    data: data,
                    qtyByType: _qtyByType,
                    onQtyChanged: _setQty,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (data) {
          if (data.effectiveRoomTypeGroups.isEmpty) return null;
          final total = _totalRoomsPicked(data);
          final vnd = _estimateTotalVnd(data);
          return SafeArea(
            child: Material(
              elevation: 12,
              color: const Color(0xFF0D1B2A),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            total == 0 ? 'Chọn số phòng từng loại' : '$total phòng · ${formatVnd(vnd)} / đêm',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (total > 0)
                            Text(
                              'Ước tính — thanh toán theo xác nhận NCC',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: total == 0
                          ? null
                          : () {
                              final lines = <String, int>{};
                              for (final g in data.effectiveRoomTypeGroups) {
                                final q = _qtyByType[g.roomType] ?? 0;
                                if (q > 0) lines[g.roomType] = q;
                              }
                              Modular.to.pushNamed(
                                Uri(
                                  path: '/book/accommodation/${widget.serviceId}',
                                  queryParameters: {
                                    'date': _dateYmd,
                                    if (lines.isNotEmpty)
                                      'rl': lines.entries.map((e) => '${e.key}:${e.value}').join(','),
                                  },
                                ).toString(),
                                arguments: AccommodationBookingArgs(roomLines: lines),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Text('Đặt phòng'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _DetailScroll extends StatelessWidget {
  const _DetailScroll({
    required this.data,
    required this.qtyByType,
    required this.onQtyChanged,
  });

  final AccommodationDetail data;
  final Map<String, int> qtyByType;
  final void Function(String roomType, int value, int maxAvail) onQtyChanged;

  @override
  Widget build(BuildContext context) {
    final s = data.service;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (s.images.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: SafeNetworkImage(
                url: s.images.first,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: const Color(0xFF1A2D3E),
                  alignment: Alignment.center,
                  child: Icon(Icons.hotel_rounded, size: 48, color: _kAccent.withValues(alpha: 0.45)),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 8),
        Text(s.description, style: const TextStyle(color: Color(0xFFA0B4C8), height: 1.35)),
        if (s.addressLine != null && s.addressLine!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place_outlined, size: 18, color: _kAccent.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Expanded(child: Text(s.addressLine!, style: const TextStyle(color: Color(0xFF8FA8C0)))),
            ],
          ),
        ],
        if (s.locationSummary != null && s.locationSummary!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(s.locationSummary!, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 13)),
        ],
        if (s.provider != null) ...[
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.storefront_outlined, text: s.provider!.name ?? ''),
          if (s.provider!.phone != null && s.provider!.phone!.isNotEmpty)
            _InfoRow(icon: Icons.phone_outlined, text: s.provider!.phone!),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text(formatVnd(s.price), style: const TextStyle(color: _kGold, fontWeight: FontWeight.w900, fontSize: 18)),
            const Text(' / phòng / đêm', style: TextStyle(color: Color(0xFFA0B4C8), fontSize: 13)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Chọn loại phòng & số lượng', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          'Dùng nút − / + dưới mỗi loại để chọn số phòng. Mỗi dòng hiện còn bao nhiêu phòng trống trong ngày.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 12),
        if (data.effectiveRoomTypeGroups.isEmpty)
          const Text('Chưa phân loại phòng — vẫn đặt theo cơ sở từ bước sau.', style: TextStyle(color: _kMuted))
        else
          ...data.effectiveRoomTypeGroups.map((g) {
            final q = qtyByType[g.roomType] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoomTypeQtyCard(
                group: g,
                quantity: q,
                onChanged: (v) => onQtyChanged(g.roomType, v, g.availableCount),
              ),
            );
          }),
        if (data.rooms.isNotEmpty) ...[
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.white12),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Danh sách phòng cụ thể', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              children: data.rooms.map((r) => _RoomTile(room: r)).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoomTypeQtyCard extends StatelessWidget {
  const _RoomTypeQtyCard({
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

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});
  final RoomItem room;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Icon(
        room.available ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
        color: room.available ? const Color(0xFF81C784) : const Color(0xFFE57373),
        size: 22,
      ),
      title: Text('${room.code} · ${room.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(
        '${roomTypeLabelVi(room.roomType)} · tối đa ${room.maxGuests} khách',
        style: const TextStyle(color: _kMuted, fontSize: 12),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8FA8C0)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF8FA8C0)))),
        ],
      ),
    );
  }
}
