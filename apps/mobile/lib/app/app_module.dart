import 'package:bvc_auth/bvc_auth.dart';
import 'package:bvc_booking/bvc_booking.dart';
import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_services/bvc_services.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app_auth_guard.dart';
import 'root_shell_page.dart';

final _authGuard = AppAuthGuard();

Map<String, int>? _parseRoomLinesQuery(Uri uri) {
  final raw = uri.queryParameters['rl'];
  if (raw == null || raw.isEmpty) return null;
  final out = <String, int>{};
  for (final part in raw.split(',')) {
    final i = part.indexOf(':');
    if (i <= 0 || i >= part.length - 1) continue;
    final k = part.substring(0, i).trim();
    final v = int.tryParse(part.substring(i + 1).trim());
    if (k.isNotEmpty && v != null && v > 0) out[k] = v;
  }
  return out.isEmpty ? null : out;
}

Map<String, int>? _mergeRoomLines(Map<String, int>? fromExtra, Map<String, int>? fromQuery) {
  if (fromExtra != null && fromExtra.isNotEmpty) return Map<String, int>.from(fromExtra);
  if (fromQuery != null && fromQuery.isNotEmpty) return Map<String, int>.from(fromQuery);
  return null;
}

class AppModule extends Module {
  @override
  void routes(RouteManager r) {
    r.redirect('/', to: '/login');
    r.redirect('/hotels', to: '/main');
    r.redirect('/food', to: '/main');
    r.redirect('/combo', to: '/main');

    r.child('/login', child: (_) => const LoginScreen());
    r.child('/register', child: (_) => const RegisterScreen());

    r.child('/main', child: (_) => const RootShellPage(), guards: [_authGuard]);

    r.child(
      '/account',
      child: (_) => const AccountScreen(),
      guards: [_authGuard],
    );

    r.child(
      '/services/accommodation/:serviceId',
      child: (_) => AccommodationDetailScreen(serviceId: Modular.args.params['serviceId']! as String),
      guards: [_authGuard],
    );
    r.child(
      '/services/detail/:serviceId',
      child: (_) {
        final item = Modular.args.data;
        if (item is! ServiceItem) return const ServicesScreen();
        return ServiceDetailScreen(item: item);
      },
      guards: [_authGuard],
    );

    r.child(
      '/book/accommodation/:serviceId',
      child: (_) {
        final id = Modular.args.params['serviceId']! as String;
        final uri = Modular.args.uri;
        final rawDate = uri.queryParameters['date'] ?? ymd(DateTime.now().add(const Duration(days: 1)));
        final parsed = parseYmd(rawDate);
        final dateYmd = parsed != null ? ymd(parsed) : ymd(DateTime.now().add(const Duration(days: 1)));
        final extra = Modular.args.data as AccommodationBookingArgs?;
        final fromQuery = _parseRoomLinesQuery(uri);
        return AccommodationBookingScreen(
          serviceId: id,
          dateYmd: dateYmd,
          initialRoomLines: _mergeRoomLines(extra?.roomLines, fromQuery),
        );
      },
      guards: [_authGuard],
    );

    r.child(
      '/book/vehicle',
      child: (_) => const BookServiceScreen(title: 'Đặt xe xích', type: 'VEHICLE'),
      guards: [_authGuard],
    );
    r.child(
      '/book/photo',
      child: (_) => const BookServiceScreen(title: 'Đặt chụp ảnh + flycam', type: 'TOUR'),
      guards: [_authGuard],
    );
    r.child(
      '/book/hotel',
      child: (_) => const BookServiceScreen(title: 'Đặt nghỉ', type: 'ACCOMMODATION'),
      guards: [_authGuard],
    );
    r.child(
      '/book/food',
      child: (_) => const BookServiceScreen(title: 'Đặt ăn', type: 'FOOD'),
      guards: [_authGuard],
    );
    r.child(
      '/book/mine',
      child: (_) => const MyBookingsScreen(),
      guards: [_authGuard],
    );
    r.child(
      '/book/mine/:bookingId',
      child: (_) {
        final extra = Modular.args.data;
        final item = extra is Map ? extra.cast<String, dynamic>() : <String, dynamic>{};
        final fromPath = Modular.args.params['bookingId'] as String?;
        return BookingDetailScreen(item: item, routeBookingId: fromPath);
      },
      guards: [_authGuard],
    );
    r.child(
      '/book/combo/:comboId',
      child: (_) => BookComboScreen(comboId: Modular.args.params['comboId']! as String),
      guards: [_authGuard],
    );
    r.child(
      '/book/service/:serviceId',
      child: (_) {
        final id = Modular.args.params['serviceId']! as String;
        final q = Modular.args.queryParams;
        return BookServiceScreen(
          title: q['title'] ?? 'Đặt chỗ',
          type: q['type'] ?? 'ACCOMMODATION',
          serviceId: id,
          serviceName: q['name'],
        );
      },
      guards: [_authGuard],
    );
  }
}
