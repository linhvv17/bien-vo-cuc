import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_auth/bvc_auth.dart';
import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_ui/bvc_ui.dart';
import '../widgets/booking_cards.dart';

/// Đơn của user: chờ auth load xong rồi mới gọi API (tránh gọi khi chưa có JWT → kẹt / lỗi).
final myBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return <Map<String, dynamic>>[];
  }

  final network = ref.read(networkServiceProvider);
  try {
    final res = await network.get<Map<String, dynamic>>('/bookings/me');
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw Exception((data?['message'] as String?) ?? 'Không lấy được dữ liệu');
    }
    final raw = data['data'];
    final list = raw is List ? raw : <dynamic>[];
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }
    rethrow;
  }
});

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBookingsProvider);

    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Đặt chỗ của tôi'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
          ),
          body: async.when(
            loading: () => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4A90C4)),
                  SizedBox(height: 16),
                  Text('Đang tải đơn…', style: TextStyle(color: Color(0xFFA0B4C8))),
                ],
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      e is DioException ? formatDioError(e) : '$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFAB91), height: 1.35),
                    ),
                  ),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return RefreshIndicator(
                  color: const Color(0xFF4A90C4),
                  onRefresh: () => ref.refresh(myBookingsProvider.future),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 56),
                      Icon(Icons.inbox_rounded, size: 56, color: Color(0xFF4A90C4)),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Chưa có đặt chỗ nào',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFA0B4C8), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Các đơn đặt qua app sẽ hiển thị ở đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF8FA8C0), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: const Color(0xFF4A90C4),
                onRefresh: () => ref.refresh(myBookingsProvider.future),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final m = items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BookingItemCard(
                        item: m,
                        onTap: () {
                          final id = (m['id'] as String?) ?? '';
                          context.push('/book/mine/$id', extra: m);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
