import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('migrates schema v1 through processing records', () async {
    final directory = await Directory.systemTemp.createTemp(
      'screenshot_inbox_migration_',
    );
    final file = File('${directory.path}/legacy.sqlite');
    final legacy = sqlite.sqlite3.open(file.path);
    legacy.execute('''
      CREATE TABLE screenshots (
        id TEXT NOT NULL PRIMARY KEY,
        asset_id TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        indexed_at INTEGER NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        size_bytes INTEGER,
        processing_status TEXT NOT NULL,
        ocr_text TEXT,
        primary_type TEXT,
        primary_subtype TEXT,
        classification_confidence REAL,
        current_lifecycle_state TEXT NOT NULL,
        last_processed_at INTEGER
      )
    ''');
    legacy.execute('PRAGMA user_version = 1');
    legacy.close();

    final database = AppDatabase(NativeDatabase(file));
    try {
      final columns = await database
          .customSelect('PRAGMA table_info(screenshots)')
          .get();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();

      expect(
        columns.map((row) => row.read<String>('name')),
        contains('processing_version'),
      );
      final tables = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      expect(
        tables.map((row) => row.read<String>('name')),
        contains('processing_records'),
      );
      expect(version.read<int>('user_version'), 3);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
