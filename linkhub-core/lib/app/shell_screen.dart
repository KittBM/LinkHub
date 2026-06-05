import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final activeCall = ref.watch(activeCallProvider);
    final unreadCount = ref.watch(
      notificationsProvider.select(
        (list) => list.where((n) => !n.isRead).length,
      ),
    );

    final destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.devices),
        label: Text('Devices'),
      ),
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: const Icon(Icons.notifications),
        ),
        label: const Text('Notifications'),
      ),
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: activeCall != null,
          child: const Icon(Icons.call),
        ),
        label: const Text('Calls'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.sms),
        label: Text('SMS'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.monitor_heart),
        label: Text('Monitor'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.content_paste),
        label: Text('Clipboard'),
      ),
    ];

    final routes = [
      '/devices',
      '/notifications',
      '/calls',
      '/sms',
      '/monitoring',
      '/clipboard',
    ];

    final selectedIndex = routes.indexWhere((r) => location.startsWith(r));

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            onDestinationSelected: (i) => context.go(routes[i]),
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.hub, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Phone Hub',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Device',
                    onPressed: () => context.push('/pairing'),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
