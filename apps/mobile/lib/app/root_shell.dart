import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_ui/bvc_ui.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
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
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: true),
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
