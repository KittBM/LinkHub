import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/providers.dart';
import 'core/storage/hive_storage.dart';
import 'core/websocket/ws_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  runApp(const ProviderScope(child: LinkHubCoreApp()));
}

class LinkHubCoreApp extends ConsumerStatefulWidget {
  const LinkHubCoreApp({super.key});

  @override
  ConsumerState<LinkHubCoreApp> createState() => _LinkHubCoreAppState();
}

class _LinkHubCoreAppState extends ConsumerState<LinkHubCoreApp> {
  @override
  void initState() {
    super.initState();
    _autoConnect();
  }

  void _autoConnect() {
    final devices = ref.read(pairedDevicesProvider);
    final ws = ref.read(wsClientProvider.notifier);
    for (final device in devices) {
      ws.connect(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LinkHub Core',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
    );
  }
}
