import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bvc_network/bvc_network.dart';

import '../../data/public_booking_repository.dart';

final publicBookingRepositoryProvider = Provider<PublicBookingRepository>((ref) {
  return PublicBookingRepository(ref.watch(networkServiceProvider));
});
