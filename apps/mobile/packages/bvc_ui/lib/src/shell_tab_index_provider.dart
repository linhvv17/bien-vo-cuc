import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab bottom bar shell: 0 Trang chủ, 1 Ăn & Ở, 2 Đặt dịch vụ, 3 Tài khoản.
final shellTabIndexProvider = NotifierProvider<ShellTabIndex, int>(ShellTabIndex.new);

class ShellTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}
