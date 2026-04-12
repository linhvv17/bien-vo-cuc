import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bvc_network/bvc_network.dart';
import '../../data/services_repository_impl.dart';
import '../../domain/entities/accommodation_detail.dart';
import '../../domain/entities/combo_deal.dart';
import '../../domain/entities/service_item.dart';
import '../../domain/repositories/services_repository.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  final network = ref.watch(networkServiceProvider);
  return ServicesRepositoryImpl(network);
});

final hotelsProvider = FutureProvider<List<ServiceItem>>((ref) async {
  final repo = ref.watch(servicesRepositoryProvider);
  return repo.listServices(type: 'ACCOMMODATION');
});

final foodProvider = FutureProvider<List<ServiceItem>>((ref) async {
  final repo = ref.watch(servicesRepositoryProvider);
  return repo.listServices(type: 'FOOD');
});

final comboDealsProvider = FutureProvider<List<ComboDeal>>((ref) async {
  final repo = ref.watch(servicesRepositoryProvider);
  return repo.listComboDeals(limit: 12);
});

/// Load services for a single type (booking, detail screens).
final servicesByTypeProvider = FutureProvider.family<List<ServiceItem>, String>((ref, type) async {
  final repo = ref.watch(servicesRepositoryProvider);
  return repo.listServices(type: type);
});

/// `(serviceId, dateYmd)` — chi tiết khách sạn + phòng trống.
final accommodationDetailProvider =
    FutureProvider.family<AccommodationDetail, ({String serviceId, String dateYmd})>((ref, key) async {
  final repo = ref.watch(servicesRepositoryProvider);
  return repo.fetchAccommodationDetail(serviceId: key.serviceId, dateYmd: key.dateYmd);
});

