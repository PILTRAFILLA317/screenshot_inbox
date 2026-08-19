import 'package:flutter/material.dart';
import 'package:screenshot_inbox/app/router.dart';
import 'package:screenshot_inbox/app/theme/app_theme.dart';

final class ScreenshotInboxApp extends StatelessWidget {
  const ScreenshotInboxApp({super.key, this.initialRoute = AppRoutes.startup});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot Inbox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
