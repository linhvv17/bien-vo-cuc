import 'package:bvc_network/bvc_network.dart';
import '../domain/entities/accommodation_detail.dart';
import '../domain/entities/combo_deal.dart';
import '../domain/entities/service_item.dart';
import '../domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  ServicesRepositoryImpl(this._network);
  final NetworkService _network;

  @override
  Future<List<ServiceItem>> listServices({required String type}) async {
    final res = await _network.get<Map<String, dynamic>>('/services', queryParameters: {'type': type});
    final body = parseApiResponse<List<ServiceItem>>(
      res.data ?? const {},
      (data) => (data as List<dynamic>? ?? const [])
          .map((e) => ServiceItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
    );
    return body.data;
  }

  @override
  Future<AccommodationDetail> fetchAccommodationDetail({required String serviceId, required String dateYmd}) async {
    final res = await _network.get<Map<String, dynamic>>(
      '/services/$serviceId/accommodation-detail',
      queryParameters: {'date': dateYmd},
    );
    final body = parseApiResponse<Map<String, dynamic>>(
      res.data ?? const {},
      (data) => (data as Map).cast<String, dynamic>(),
    );
    return AccommodationDetail.fromJson(body.data);
  }

  @override
  Future<List<ComboDeal>> listComboDeals({int limit = 12}) async {
    final res = await _network.get<Map<String, dynamic>>('/combos/deals', queryParameters: {'limit': limit});
    final body = parseApiResponse<List<ComboDeal>>(
      res.data ?? const {},
      (data) => (data as List<dynamic>? ?? const [])
          .map((e) => ComboDeal.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
    );
    return body.data;
  }
}

