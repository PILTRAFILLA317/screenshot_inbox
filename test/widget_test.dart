import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:screenshot_inbox/app/app.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/app/router.dart';
import 'package:screenshot_inbox/core/database/app_database.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';

void main() {
  testWidgets('onboarding explains local processing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScreenshotInboxApp(initialRoute: AppRoutes.onboarding),
      ),
    );

    expect(find.text('Turn screenshots\ninto next steps.'), findsOneWidget);
    expect(find.text('Allow photo access'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('home shows the three lifecycle counters', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          photoRepositoryProvider.overrideWithValue(_EmptyPhotoRepository()),
        ],
        child: const ScreenshotInboxApp(initialRoute: AppRoutes.home),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Screenshot Inbox'), findsOneWidget);
    expect(find.text('Need Action'), findsOneWidget);
    expect(find.text('Expiring'), findsOneWidget);
    expect(find.text('Clean Up'), findsOneWidget);
    expect(find.text('0'), findsAtLeastNWidgets(3));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

final class _EmptyPhotoRepository implements PhotoRepository {
  @override
  Future<PhotoPermissionState> currentPermission() async =>
      PhotoPermissionState.authorized;

  @override
  Future<Set<String>> deleteAssets(List<String> assetIds) async => const {};

  @override
  Stream<List<PhotoAsset>> getScreenshotBatches({int batchSize = 50}) =>
      const Stream.empty();

  @override
  Future<void> openSettings() async {}

  @override
  Future<Uint8List?> getProcessingImage(String assetId) async => null;

  @override
  Future<List<PhotoAsset>> getScreenshots({
    DateTime? after,
    int? limit,
  }) async => const [];

  @override
  Future<Uint8List?> getThumbnail(String assetId) async => null;

  @override
  Future<PhotoPermissionState> requestPermission() async =>
      PhotoPermissionState.authorized;
}
