import 'package:flutter/material.dart';
import 'package:screenshot_inbox/features/home/home_page.dart';
import 'package:screenshot_inbox/features/onboarding/onboarding_page.dart';
import 'package:screenshot_inbox/features/startup/startup_page.dart';

abstract final class AppRoutes {
  static const startup = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
}

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.home => const HomePage(),
      AppRoutes.onboarding => const OnboardingPage(),
      _ => const StartupPage(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
