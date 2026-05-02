import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'presentation/welcome_screen.dart';

// Import your new Home Screen
import 'package:sayfoods_app/src/features/home/presentation/home_screen.dart';
import 'package:sayfoods_app/src/features/admin/presentation/admin_main_screen.dart';
import 'package:sayfoods_app/src/features/rider/presentation/rider_main_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state stream
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        final session = authState.session;

        // 1. If not logged in, show Login Screen (Welcome Screen)
        if (session == null) {
          return const WelcomeScreen();
        }

        // 2. If logged in, fetch the role to determine the route
        final roleAsync = ref.watch(userRoleProvider);

        return roleAsync.when(
          data: (role) {
            if (role == 'admin') {
              return const AdminMainScreen();
            } else if (role == 'rider') {
              return const RiderMainScreen();
            } else {
              // 3. The Client Route!
              // This is the default fallback for standard users.
              return const ClientHomeScreen();
            }
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) =>
              Scaffold(body: Center(child: Text('Error loading role: $err'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Auth Error: $err'))),
    );
  }
}
