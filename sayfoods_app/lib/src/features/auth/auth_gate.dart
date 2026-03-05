import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'presentation/welcome_screen.dart';

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
              return const Scaffold(
                body: Center(child: Text('Admin Dashboard')),
              );
            } else if (role == 'rider') {
              return const Scaffold(body: Center(child: Text('Rider Hub')));
            } else {
              return const Scaffold(
                body: Center(child: Text('Client Catalog')),
              );
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
