import 'package:go_router/go_router.dart';
import '../features/pairing/pairing_screen.dart';
import '../features/pairing/qr_scan_screen.dart';
import '../features/pairing/pin_screen.dart';
import '../features/devices/devices_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/calls/calls_screen.dart';
import '../features/sms/sms_screen.dart';
import '../features/monitoring/monitoring_screen.dart';
import '../features/clipboard/clipboard_screen.dart';
import 'shell_screen.dart';

final router = GoRouter(
  initialLocation: '/devices',
  routes: [
    ShellRoute(
      builder: (ctx, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/devices', builder: (c, s) => const DevicesScreen()),
        GoRoute(
          path: '/notifications',
          builder: (c, s) => const NotificationsScreen(),
        ),
        GoRoute(path: '/calls', builder: (c, s) => const CallsScreen()),
        GoRoute(path: '/sms', builder: (c, s) => const SmsScreen()),
        GoRoute(
          path: '/monitoring',
          builder: (c, s) => const MonitoringScreen(),
        ),
        GoRoute(
          path: '/clipboard',
          builder: (c, s) => const ClipboardScreen(),
        ),
      ],
    ),
    GoRoute(path: '/pairing', builder: (c, s) => const PairingScreen()),
    GoRoute(path: '/pairing/qr', builder: (c, s) => const QrScanScreen()),
    GoRoute(
      path: '/pairing/pin',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PinScreen(deviceInfo: extra);
      },
    ),
  ],
);
