# Screenshot Inbox

Local-first Flutter foundation for turning screenshots into structured objects,
useful actions, and deterministic lifecycle transitions.

```text
SCREENSHOT → UNDERSTAND → EXTRACT OBJECTS → ACTIONABILITY
           → ACTION → LIFECYCLE → KEEP / EXPIRED / CLEANUP
```

The image asset remains in Photos. The database stores its `assetId`, derived
text/data, actions, and lifecycle history; it never stores a permanent image
copy and no cloud service is used.

## Architecture

Dependencies point inward:

```text
features / Riverpod
        ↓
processing + domain
        ↓
ports (repositories and gateways)
        ↑
infrastructure adapters (Drift, photo_manager, ML Kit, device APIs)
```

Important boundaries:

- `domain/` is pure Dart and contains extensible value types and repository
  contracts.
- `processing/` coordinates small stages. The central pipeline contains no
  category switch.
- `infrastructure/` is the only layer aware of `AssetEntity`, ML Kit, Drift,
  native calendar, map, notification, and URL plugins.
- `features/` contains Riverpod controllers and deliberately thin widgets.
- `core/debug/debug_fixture_seeder.dart` is guarded by `kDebugMode` and is
  exposed through the flask button on Home only in debug builds.

The Drift schema is at version 2 and contains `screenshots`, `entities`,
`extracted_objects`, `suggested_actions`, and `lifecycle_events`, with foreign
keys, cascading deletion, indexes, and JSON text columns for variable payloads.

## Adding a parser

1. Implement `ScreenshotParser` in `processing/parsers/`.
2. Give it a stable `id`, supported `ScreenshotType` values, and a priority.
3. Keep recognition in `canParse` cheap and deterministic.
4. Return one or more domain `ExtractedObject` instances from `parse`.
5. Register the instance in `parserRegistryProvider`.

The registry selects the highest-priority compatible parser. The pipeline does
not change when a parser is added.

## Adding an action policy

1. Implement `ActionPolicy` in `processing/actions/`.
2. Implement `supports` for the relevant object shape or subtype.
3. Return `ActionProposal` values from `propose`.
4. Register it in `actionPolicyRegistryProvider`.

All matching policies are composed in priority order; `ActionEngine` remains
unchanged.

## Adding a lifecycle policy

1. Implement `LifecyclePolicy` in `processing/lifecycle/`.
2. Match reliable structured data in `supports`.
3. Calculate `LifecycleEvaluation` solely from the object and supplied `now`.
4. Register it before `DefaultLifecyclePolicy`.

This keeps time-based transitions deterministic and directly unit-testable.

## Platform setup

The project already includes the required source configuration:

- iOS deployment target 15.5 (required by current Google ML Kit pods).
- Photos and Calendar usage descriptions in `ios/Runner/Info.plist`.
- Google Maps query scheme in `Info.plist`; add schemes only for other map apps
  the product explicitly supports.
- Android image, calendar, notification, and reboot permissions.
- Android scheduled-notification receivers and `minSdk = 24` (required by
  `device_calendar_plus`). Notifications use inexact scheduling, so no exact
  alarm permission is requested. A dedicated status-bar drawable is included.

Before device distribution, set the real iOS bundle identifier/team and Android
`applicationId`/release signing. Photos, ML Kit, Calendar, Maps, and notification
flows must be verified on physical devices because unit tests use ports/fakes.

## Validation

```bash
dart format .
flutter analyze
flutter test
```

## Deliberate TODOs for later phases

- Persist onboarding completion and permission education state.
- Add the application use case that discovers new Photos assets and queues the
  pipeline; background processing is intentionally absent.
- Add real subtype-specific parsers and richer classifiers beyond the small
  deterministic baseline.
- Wire suggested-action execution UI to the calendar/map/notification/URL
  gateways and persist completion/failure events.
- Add cleanup confirmation UI and reconciliation for assets deleted outside the
  app.
- Harden Android screenshot discovery for OEM-specific/localized folders with
  device fixtures.
- Decide whether reminders need exact Android alarms; the current adapter uses
  inexact scheduling to avoid restricted exact-alarm permissions.
