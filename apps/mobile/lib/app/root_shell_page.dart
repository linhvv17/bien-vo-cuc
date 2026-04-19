import 'package:bvc_auth/bvc_auth.dart';
import 'package:bvc_booking/bvc_booking.dart';
import 'package:bvc_home/bvc_home.dart';
import 'package:bvc_services/bvc_services.dart';
import 'package:bvc_ui/bvc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shell bottom bar + [IndexedStack] — một [Navigator] gốc (Modular), tránh xung đột Page key của go_router shell.
class RootShellPage extends ConsumerWidget {
  const RootShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabIndexProvider);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          ServicesScreen(),
          BookingScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.55))),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 68,
              indicatorColor: Colors.transparent,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.primary : AppColors.mutedForeground,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 24,
                  color: selected ? cs.primary : AppColors.mutedForeground,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => ref.read(shellTabIndexProvider.notifier).setTab(i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
                NavigationDestination(icon: Icon(Icons.restaurant_rounded), label: 'Ăn & Ở'),
                NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'Đặt dịch vụ'),
                NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Tài khoản'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
