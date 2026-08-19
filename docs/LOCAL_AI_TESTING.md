# Local intelligence device testing

Screenshot Inbox keeps OCR, prompts, model output, and screenshot pixels on the
device. Unit tests use `FakeIntelligenceProvider`; Foundation Models and Gemini
Nano must be verified on physical devices.

## Shared checklist

1. Run a debug build and open a processed screenshot.
2. Tap the bug icon to open the local debug inspector.
3. Verify normalized OCR block coordinates are between `0` and `1`, entities
   reference real block IDs, and the deterministic parser still has a usable
   candidate.
4. Inspect `LOCAL INTELLIGENCE` for provider, availability, duration, structured
   output, accepted/rejected fields, and warnings.
5. Verify a model failure or timeout leaves the deterministic object usable and
   never presents a blocking product error.
6. Use the realistic fixtures in `test/fixtures/benchmark/corpus.json`. Do not
   treat unit-test fakes as model-quality measurements.

The debug policy defaults to `alwaysForSupportedTypes`. Override it without a
code change with a Dart define:

```sh
flutter run --dart-define=INTELLIGENCE_USAGE_POLICY=disabled
flutter run --dart-define=INTELLIGENCE_USAGE_POLICY=lowConfidenceOnly
flutter run --dart-define=INTELLIGENCE_USAGE_POLICY=actionableTypes
flutter run --dart-define=INTELLIGENCE_USAGE_POLICY=alwaysForSupportedTypes
```

## iPhone / Apple Foundation Models

Requirements:

- a physical Apple Intelligence-capable device;
- iOS 26 or newer;
- Apple Intelligence enabled in Settings;
- the system model fully downloaded.

Test all availability states that can be reproduced:

- available;
- ineligible device;
- Apple Intelligence disabled;
- model not ready after enabling or updating;
- airplane mode after the model is ready.

The Swift bridge uses the official `FoundationModels` framework and guided
generation. It is conditionally compiled, so iOS 15.5–25 devices remain on the
deterministic fallback instead of crashing.

Official references:

- <https://developer.apple.com/documentation/foundationmodels>
- <https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models>
- <https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation>

## Android / ML Kit Prompt API

Requirements:

- Android API 26 or newer. The native Prompt SDK declares API 26 as its minimum,
  so the Android app also uses `minSdk 26`;
- a device listed as supported for ML Kit Prompt API;
- locked bootloader;
- current AICore and model configuration;
- the app in the foreground during inference.

Check `AVAILABLE`, `DOWNLOADABLE`, `DOWNLOADING`, and `UNAVAILABLE` states. The
app does not force a model download while processing a screenshot. A model that
is not ready simply lowers interpretation accuracy for that run.

The Kotlin bridge prefers ML Kit Structured Output when the device reports the
feature available. Its JSON fallback is still validated in Dart and never
persists raw model output directly.

Official references:

- <https://developers.google.com/ml-kit/genai/prompt/android/get-started>
- <https://developers.google.com/ml-kit/genai/prompt/android/structured-output>
- <https://developers.google.com/ml-kit/genai>

## Verify no interpretation request leaves the device

1. Warm/download the platform model first, then enable airplane mode.
2. Process fixtures successfully while offline.
3. Capture traffic with Xcode Instruments, Android Studio Network Inspector, or
   a local proxy such as Proxyman/Charles.
4. Filter by the app process/package and process several screenshots.
5. Confirm there are no HTTP requests carrying OCR, block IDs, entities,
   candidates, prompts, or model output.

Model provisioning may use OS-managed network traffic before the model is ready;
that is distinct from app inference content. The application code contains no
cloud AI client, endpoint, or API key.

## Calendar regression checklist

For both platforms, test denied and granted permission, no writable calendar,
timed and all-day events, a non-default device timezone, and service failure.
Every Calendar action must show the review sheet first. Confirm title, date,
time, and location are editable, and that an inferred end time is not presented
as screenshot evidence.
