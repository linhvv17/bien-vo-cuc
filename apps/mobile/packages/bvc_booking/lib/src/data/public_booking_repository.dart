import 'package:bvc_network/bvc_network.dart';

/// Gọi API đặt chỗ công khai (khách đã đăng nhập), tách khỏi UI.
class PublicBookingRepository {
  PublicBookingRepository(this._network);

  final NetworkService _network;

  Future<void> createBooking(Map<String, dynamic> body) async {
    final res = await _network.post<Map<String, dynamic>>('/bookings/public', data: body);
    parseApiResponse<dynamic>(res.data ?? const {}, (data) => data);
  }

  Future<void> createComboBooking(Map<String, dynamic> body) async {
    final res = await _network.post<Map<String, dynamic>>('/bookings/public/combo', data: body);
    parseApiResponse<dynamic>(res.data ?? const {}, (data) => data);
  }

  /// Hủy đơn của user (API hủy cả nhóm combo / nhiều phòng nếu cùng nhóm).
  Future<Map<String, dynamic>> cancelMine(String bookingId) async {
    final res = await _network.patch<Map<String, dynamic>>(
      '/bookings/me/$bookingId/cancel',
      data: const <String, dynamic>{},
    );
    return parseApiResponse<Map<String, dynamic>>(
      res.data ?? const {},
      (data) => (data as Map).cast<String, dynamic>(),
    ).data;
  }
}
