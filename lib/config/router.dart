import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/storage/secure_storage_service.dart';
import '../features/ask/screens/ask_screen.dart';
import '../features/documents/screens/documents_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/upload/screens/upload_screen.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final hasServerConfigProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  return storage.hasConfig();
});

// RouterNotifier bridges Riverpod state → GoRouter's refreshListenable.
// When hasServerConfigProvider resolves (or changes), it calls notifyListeners()
// so GoRouter re-runs its redirect logic.
final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<bool>>(
      hasServerConfigProvider,
      (prev, next) => notifyListeners(),
    );
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    // GoRouter re-evaluates redirect whenever notifier fires.
    refreshListenable: notifier,
    redirect: (context, state) {
      final configAsync = ref.read(hasServerConfigProvider);

      // Still loading — stay on splash.
      if (configAsync is AsyncLoading) return '/';

      final hasConfig = configAsync.valueOrNull ?? false;
      final loc = state.matchedLocation;

      // No config → force Settings (unless already there).
      if (!hasConfig && loc != '/settings') return '/settings';

      // Config exists but on splash → go to Ask tab.
      if (hasConfig && loc == '/') return '/ask';

      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _SplashScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ask',
                builder: (context, state) => const AskScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) => const DocumentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/upload',
        builder: (context, state) => const UploadScreen(),
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Navigation shell
// ---------------------------------------------------------------------------

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Ask',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Splash screen (shown briefly while secure storage is read)
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
