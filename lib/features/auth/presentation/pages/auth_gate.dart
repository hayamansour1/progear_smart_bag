import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/features/auth/presentation/pages/login_page.dart';
import 'package:progear_smart_bag/features/home/presentation/pages/home_dashboard_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<Session?>(
      stream: auth.onAuthStateChange.map((s) => s.session),
      initialData: auth.currentSession,
      builder: (context, snap) {
        final session = snap.data;

        if (session == null) {
          return const LoginPage();
        }

        return FutureBuilder(
          future: auth.getUser(),
          builder: (context, userSnap) {
            if (userSnap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnap.hasError || userSnap.data == null) {
              auth.signOut();
              return const LoginPage();
            }

            return const HomeDashboardPage();
          },
        );
      },
    );
  }
}
