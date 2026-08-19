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

## Functional MVP

The app now executes the complete local loop on iOS and Android:

1. Onboarding requests Photos access and later launches skip onboarding while
   access remains available.
2. Screenshot albums are read in bounded metadata batches, newest first.
3. A two-worker, pausable queue loads one reduced processing image per job.
4. ML Kit produces domain-owned OCR blocks/lines/bounds and normalized barcode
   payloads. Missing confidence remains `null`.
5. English/Spanish extraction and type-specific parsers produce deterministic
   candidates. Supported actionable types can then use on-device intelligence;
   deterministic validation, action policies, lifecycle policies, and priority
   ranking persist the resolved result in Drift.
6. Home updates progressively and surfaces Need Action, Expiring, Cleanup, and
   Recent by relevance rather than only capture time.
7. Detail supports review, user-confirmed corrections, actions, Keep, and
   explicit native-confirmed deletion.
8. Saved places/products remain in Library even after their source screenshot is
   marked deleted.
9. Later launches reevaluate temporal lifecycle state without rerunning OCR and
   only queue new or interrupted screenshot assets.

Implemented parsers are `EventParser`, `CouponParser`,
`ConversationTaskParser`, `OrderParser`, `ProductParser`, and `PlaceParser`,
followed by the existing generic fallback. Low-signal content becomes
`reference` or `other`; the classifier does not force a useful type.

Search uses the `InboxRepository` abstraction over local Drift rows and covers
OCR, title/subtitle, entity values, and structured object data. It is
deliberately replaceable by FTS5 in a later migration; this MVP has no
embeddings.

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
- `core/debug/debug_fixture_seeder.dart` remains guarded by `kDebugMode` for
  local development fixtures.

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
- The ML Kit CocoaPods Apple Silicon helper is enabled so iOS 26+ simulators
  can use the arm64 slices; it automatically switches those slices back for
  physical-device builds.
- Photos and Calendar usage descriptions in `ios/Runner/Info.plist`.
- Google Maps query scheme in `Info.plist`; add schemes only for other map apps
  the product explicitly supports.
- Android image, calendar, notification, and reboot permissions.
- Apple Foundation Models and ML Kit Prompt API are reached through small native
  platform-channel adapters. Unsupported or not-ready devices use the existing
  deterministic pipeline without a product error.
- Android scheduled-notification receivers and `minSdk = 26`, required by the
  native ML Kit GenAI Prompt SDK. Notifications use inexact scheduling, so no
  exact alarm permission is requested. A dedicated status-bar drawable is
  included.

Before device distribution, set the real iOS bundle identifier/team and Android
`applicationId`/release signing. Photos, ML Kit, Calendar, Maps, and notification
flows must be verified on physical devices because unit tests use ports/fakes.
Current ML Kit Flutter plugins still use CocoaPods rather than Swift Package
Manager. Flutter's SPM adoption message is therefore expected and should be
tracked when upgrading those plugins; it is not a build failure today.

Before running on a physical device:

- iOS: choose a real development team and bundle identifier in Xcode, retain
  deployment target 15.5, install dependencies through Flutter/CocoaPods, and
  enable signing for the selected device. The Photos and Calendar usage
  descriptions are already present. Apple Maps needs no URL scheme; Google Maps
  uses the configured `comgooglemaps` scheme.
- Android: replace `com.example.screenshot_inbox`, configure release signing,
  and keep `minSdk = 26`. Photo, calendar, notification, and reboot permissions
  plus notification receivers are already declared.
- Calendar and notification prompts should appear only after their action is
  tapped. Photos permission is the onboarding prompt.

## Validation

```bash
dart format .
flutter analyze
flutter test
```

Physical-device setup and privacy verification for local models is documented
in [`docs/LOCAL_AI_TESTING.md`](docs/LOCAL_AI_TESTING.md).

## Known MVP limitations and next steps

- Parsing favors precision and supports common English/Spanish shapes.
  Ambiguous numeric dates use day/month order and many locales remain
  unsupported.
- Classification is local and heuristic. User correction does not train a
  model; it protects confirmed fields from later reprocessing.
- Reminder uses local notifications rather than EventKit/Android task providers.
- Search is a replaceable local scan, not FTS5 yet. Large result sets should move
  to indexed pagination in the next database phase.
- Processing runs while the app is alive; OS background execution is out of
  scope for this MVP.
- Android screenshot discovery still needs physical fixtures for OEM-specific
  and localized album names. An ambiguous empty inventory never mass-marks
  stored rows as deleted.
- Carrier status is never queried. A past delivery date requests review and does
  not imply delivery.
- Map launching uses installed applications supported by `map_launcher`; iOS
  scheme declarations should stay limited to intentionally supported apps.
- The current reminder adapter uses inexact Android scheduling to avoid the
  restricted exact-alarm permission.
- Evaluate FTS5, paginated inbox queries, background task constraints, broader
  locale/date parsing, and native reminder providers next. Cloud AI, sync,
  subscriptions, ads, embeddings, carrier APIs, widgets, App Intents, and Share
  Extensions remain intentionally out of scope.
