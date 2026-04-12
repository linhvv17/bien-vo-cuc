import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bvc_network/bvc_network.dart';
import '../../data/home_repository_impl.dart';
import '../../domain/entities/home_data.dart';
import '../../data/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(ref.watch(networkServiceProvider));
});

final homeDataProvider = FutureProvider<HomeData>((ref) {
  return ref.watch(homeRepositoryProvider).fetchHomeData();
});
