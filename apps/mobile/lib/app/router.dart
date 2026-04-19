import 'package:bvc_auth/bvc_auth.dart';
import 'package:bvc_booking/bvc_booking.dart';
import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_home/bvc_home.dart';
import 'package:bvc_services/bvc_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'root_shell.dart';

/// `rl=SINGLE:2,DOUBLE:1` — dự phòng khi [AccommodationBookingArgs] không truyền được qua [GoRouterState.extra].
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

Map<String, int>? _mergeInitialRoomLines(Map<String, int>? fromExtra, Map<String, int>? fromQuery) {
  if (fromExtra != null && fromExtra.isNotEmpty) return Map<String, int>.from(fromExtra);
  if (fromQuery != null && fromQuery.isNotEmpty) return Map<String, int>.from(fromQuery);
  return null;
}

/// Một instance [GoRouter] cố định + [refreshListenable] khi auth đổi.
/// Tránh `ref.watch(auth)` trong provider body — mỗi lần auth đổi tạo GoRouter mới
/// khiến shell/home remount liên tục và [homeDataProvider] kẹt loading.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<AuthSession?>>(authSessionProvider, (_, __) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = ref.read(authSessionProvider);
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final ready = !auth.isLoading;
      final isAuthed = auth.hasValue && auth.value != null;

      if (!ready) return null; // chờ load session từ storage
      if (!isAuthed && !loggingIn) return '/login';
      if (isAuthed && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/home'),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      // Keep standalone route for deep-links; primary navigation uses shell tab.
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      GoRoute(
        path: '/services/accommodation/:serviceId',
        builder: (_, state) => AccommodationDetailScreen(serviceId: state.pathParameters['serviceId']!),
      ),
      GoRoute(
        path: '/services/detail/:serviceId',
        builder: (_, state) {
          final extra = state.extra;
          final item = extra is ServiceItem ? extra : null;
          // Fallback: if no item provided, navigate back to list.
          if (item == null) return const ServicesScreen();
          return ServiceDetailScreen(item: item);
        },
      ),
      GoRoute(
        path: '/book/accommodation/:serviceId',
        builder: (_, state) {
          final id = state.pathParameters['serviceId']!;
          final rawDate = state.uri.queryParameters['date'] ?? ymd(DateTime.now().add(const Duration(days: 1)));
          final parsed = parseYmd(rawDate);
          final dateYmd = parsed != null ? ymd(parsed) : ymd(DateTime.now().add(const Duration(days: 1)));
          final extra = state.extra as AccommodationBookingArgs?;
          final fromQuery = _parseRoomLinesQuery(state.uri);
          return AccommodationBookingScreen(
            serviceId: id,
            dateYmd: dateYmd,
            initialRoomLines: _mergeInitialRoomLines(extra?.roomLines, fromQuery),
          );
        },
      ),
      GoRoute(path: '/hotels', redirect: (_, __) => '/services'),
      GoRoute(path: '/food', redirect: (_, __) => '/services'),
      GoRoute(path: '/combo', redirect: (_, __) => '/services'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RootShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/services',
                builder: (_, __) => const ServicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/book',
                builder: (_, __) => const BookingScreen(),
                routes: [
                  GoRoute(
                    path: 'vehicle',
                    builder: (_, __) => const BookServiceScreen(title: 'Đặt xe xích', type: 'VEHICLE'),
                  ),
                  GoRoute(
                    path: 'photo',
                    builder: (_, __) => const BookServiceScreen(title: 'Đặt chụp ảnh + flycam', type: 'TOUR'),
                  ),
                  GoRoute(
                    path: 'hotel',
                    builder: (_, __) => const BookServiceScreen(title: 'Đặt nghỉ', type: 'ACCOMMODATION'),
                  ),
                  GoRoute(
                    path: 'food',
                    builder: (_, __) => const BookServiceScreen(title: 'Đặt ăn', type: 'FOOD'),
                  ),
                  GoRoute(
                    path: 'mine',
                    builder: (_, __) => const MyBookingsScreen(),
                  ),
                  GoRoute(
                    path: 'mine/:bookingId',
                    builder: (_, state) {
                      final extra = state.extra;
                      final item = extra is Map ? extra.cast<String, dynamic>() : <String, dynamic>{};
                      final fromPath = state.pathParameters['bookingId'];
                      return BookingDetailScreen(
                        item: item,
                        routeBookingId: fromPath,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'combo/:comboId',
                    builder: (_, state) => BookComboScreen(comboId: state.pathParameters['comboId']!),
                  ),
                  GoRoute(
                    path: 'service/:serviceId',
                    builder: (_, state) {
                      final id = state.pathParameters['serviceId']!;
                      final q = state.uri.queryParameters;
                      return BookServiceScreen(
                        title: q['title'] ?? 'Đặt chỗ',
                        type: q['type'] ?? 'ACCOMMODATION',
                        serviceId: id,
                        serviceName: q['name'],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account-tab',
                builder: (_, __) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
