import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/agent_storage.dart';
import 'core/websocket/ws_server.dart';
import 'core/native/native_bridge.dart';
import 'app/providers.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AgentStorage.init();
  runApp(const ProviderScope(child: PhoneHubAgentApp()));
}

class PhoneHubAgentApp extends ConsumerStatefulWidget {
  const PhoneHubAgentApp({super.key});

  @override
  ConsumerState<PhoneHubAgentApp> createState() => _PhoneHubAgentAppState();
}

class _PhoneHubAgentAppState extends ConsumerState<PhoneHubAgentApp> {
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _initAgent();
  }

  Future<void> _initAgent() async {
    // Start WS server immediately
    await ref.read(wsServerProvider.notifier).start();

    // Init native bridge
    final pairing = ref.read(pairingStateProvider);
    final bridge = ref.read(nativeBridgeProvider);
    bridge.init(pairing.deviceId);

    // Set pairing token on server
    ref.read(wsServerProvider.notifier).setPairingToken(pairing.pairingToken);

    // Ensure command handler is initialised
    ref.read(commandHandlerProvider);

    // Broadcast device status every 30 s
    _statusTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => bridge.broadcastDeviceStatus(),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkHub Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
