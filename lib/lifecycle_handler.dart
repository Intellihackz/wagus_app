import 'package:flutter/widgets.dart';
import 'package:wagus/services/user_service.dart';

class LifecycleHandler with WidgetsBindingObserver {
  final String walletAddress;

  LifecycleHandler(this.walletAddress);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userService = UserService();
    if (state == AppLifecycleState.resumed) {
      userService.setUserOnline(walletAddress);
      print('🟢 App resumed — $walletAddress is now online');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      userService.setUserOffline(walletAddress);
      print('🔴 App paused/detached — $walletAddress is now offline');
    }
  }
}
