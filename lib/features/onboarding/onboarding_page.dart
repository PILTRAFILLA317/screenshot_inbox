import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/router.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/features/onboarding/onboarding_controller.dart';

final class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(onboardingControllerProvider);
    final canContinue = permission.valueOrNull?.canRead ?? false;
    final blocked =
        permission.valueOrNull == PhotoPermissionState.denied ||
        permission.valueOrNull == PhotoPermissionState.restricted;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(
                Icons.screenshot_monitor_rounded,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 28),
              Text(
                'Turn screenshots\ninto next steps.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 18),
              Text(
                'Screenshot Inbox reads selected screenshots on this device, '
                'extracts useful details, and helps you act or clean up. Images '
                'never leave your phone.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              if (permission.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Photo access could not be requested. You can try again.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (blocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Photo access is off. Open system settings, allow access, then check again.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (permission.valueOrNull == PhotoPermissionState.limited)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Limited access is active. Only the screenshots you selected will be processed.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              FilledButton(
                onPressed: permission.isLoading
                    ? null
                    : blocked
                    ? () => ref
                          .read(onboardingControllerProvider.notifier)
                          .openSettings()
                    : () => ref
                          .read(onboardingControllerProvider.notifier)
                          .requestPermission(),
                child: Text(
                  permission.isLoading
                      ? 'Requesting access…'
                      : blocked
                      ? 'Open system settings'
                      : canContinue
                      ? 'Photo access granted'
                      : 'Allow photo access',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: blocked
                    ? () => ref
                          .read(onboardingControllerProvider.notifier)
                          .checkPermission()
                    : canContinue
                    ? () =>
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.home)
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(blocked ? 'Check access' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
