// import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// pages
import 'package:progear_smart_bag/features/onboarding/ui/get_started_page.dart';
import 'package:progear_smart_bag/features/auth/presentation/pages/login_page.dart';
import 'package:progear_smart_bag/features/auth/presentation/pages/register_page.dart';
import 'package:progear_smart_bag/features/home/presentation/pages/home_dashboard_page.dart';
import 'package:progear_smart_bag/features/auth/presentation/pages/auth_gate.dart';
import 'package:progear_smart_bag/features/auth/presentation/pages/reset_with_code_page.dart'; // ← أضِيفي الصفحة

final appRouter = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/auth-gate',
  routes: [
    // Auth gate decides where to go: Home or Login
    GoRoute(
      path: '/auth-gate',
      builder: (context, state) => const AuthGate(),
    ),

    // Onboarding
    GoRoute(
      path: '/',
      builder: (context, state) => const GetStartedPage(),
    ),

    // Auth
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // Reset with OTP code (يستقبل email اختياريًا للملء التلقائي)
    GoRoute(
      path: '/reset-with-code',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'];
        return ResetWithCodePage(prefilledEmail: email);
      },
    ),

    // Home
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeDashboardPage(),
    ),
  ],
);
