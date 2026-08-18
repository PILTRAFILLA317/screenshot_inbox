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
              FilledButton(
                onPressed: permission.isLoading
                    ? null
                    : () => ref
                          .read(onboardingControllerProvider.notifier)
                          .requestPermission(),
                child: Text(
                  permission.isLoading
                      ? 'Requesting access…'
                      : canContinue
                      ? 'Photo access granted'
                      : 'Allow photo access',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: canContinue
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
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
