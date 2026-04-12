import '../entities/accommodation_detail.dart';
import '../entities/combo_deal.dart';
import '../entities/service_item.dart';

abstract class ServicesRepository {
  Future<List<ServiceItem>> listServices({required String type});
  Future<List<ComboDeal>> listComboDeals({int limit = 12});
  Future<AccommodationDetail> fetchAccommodationDetail({required String serviceId, required String dateYmd});
}

