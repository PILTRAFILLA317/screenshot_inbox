import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/app/router.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';

final class StartupPage extends ConsumerWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentPhotoPermissionProvider, (previous, next) {
      next.when(
        data: (permission) {
          final route = permission.canRead
              ? AppRoutes.home
              : AppRoutes.onboarding;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed(route);
            }
          });
        },
        error: (_, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
            }
          });
        },
        loading: () {},
      );
    });
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Opening Screenshot Inbox',
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}
