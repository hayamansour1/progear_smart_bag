import 'package:go_router/go_router.dart';
import 'package:progear_smart_bag/features/auth/presentation/pages/reset_With_Code_Page.dart';

// pages
import 'package:progear_smart_bag/features/onboarding/ui/get_started_page.dart';
import 'package:progear_smart_bag/features/auth/presentation/pages/login_page.dart';
import 'package:progear_smart_bag/features/auth/presentation/pages/register_page.dart';
import 'package:progear_smart_bag/features/home/presentation/pages/home_dashboard_page.dart';
import 'package:progear_smart_bag/features/auth/presentation/pages/auth_gate.dart';
import 'package:progear_smart_bag/features/activity/presentation/pages/activity_page.dart';
import 'package:progear_smart_bag/features/home/presentation/pages/settings_page.dart';

final appRouter = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/auth-gate',
  routes: [
    GoRoute(path: '/auth-gate', builder: (c, s) => const AuthGate()),
    GoRoute(path: '/', builder: (c, s) => const GetStartedPage()),
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
    GoRoute(
      path: '/reset-with-code',
      builder: (c, s) => ResetWithCodePage(
        prefilledEmail: s.uri.queryParameters['email'],
      ),
    ),
    GoRoute(path: '/home', builder: (c, s) => const HomeDashboardPage()),

    GoRoute(
      path: '/settings',
      builder: (c, s) => const SettingsPage(),
    ),

    GoRoute(
      path: '/activity',
      builder: (c, s) {
        final cid = s.uri.queryParameters['cid'];
        return (cid == null || cid.isEmpty)
            ? const HomeDashboardPage()
            : ActivityPage(controllerID: cid);
      },
    ),
  ],
);
