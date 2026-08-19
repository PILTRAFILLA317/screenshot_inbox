# Performance processing architecture

## Root causes found before optimization

The previous engine had one FIFO queue with concurrency `2`. Every queued
screenshot loaded a JPEG up to 2400 pixels on its longest edge, then executed
OCR, barcode recognition, deterministic parsing, local intelligence, action
generation, lifecycle evaluation, and one aggregate database write. Debug runs
also selected local intelligence for every provider-supported deterministic
type. A 1,500-item library therefore became a long sequence of full scans, even
though metadata discovery itself was already paged and newest-first.

The UI was reactive, but the engine could not persist the boundary between
cheap and deep work. An interrupted deep interpretation could therefore only be
recovered by treating the screenshot like a complete processing job.

## Current strategy

```text
metadata discovery (newest first)
  -> stable priority heap (O(log n) enqueue/dequeue)
  -> Fast Scan queue (default concurrency 2)
     -> 1800 px OCR image
     -> OCR + barcode + deterministic entities/classification/parser
     -> persist spatial OCR and provisional deterministic result
     -> explainable AI eligibility
       -> no AI: safe action/lifecycle finalization
       -> AI: priority Deep Analysis queue (default concurrency 1)
          -> separate 1280 px AI image
          -> specialized local schema + validation
          -> final actions/lifecycle + persist
```

Encoded image bytes are scoped to one queue worker. `FastScanResult` explicitly
releases its image before it can enter the Deep Analysis queue. Thumbnails use a
separate 512 px policy. No resized image is persisted.

## Incremental cache and restart

Drift schema version 3 adds `processing_records`. Each record stores:

- asset and Fast/Deep fingerprints;
- independent Fast and Deep states;
- normalized spatial OCR/barcode/classification payload needed to resume Deep
  Analysis without OCR;
- AI eligibility reasons and centralized priority;
- bounded retry metadata (maximum 3 Deep attempts) and per-stage timings.

The Fast fingerprint contains asset identity plus OCR/classifier/parser
versions. The Deep fingerprint adds the intelligence/validator version. An AI
prompt/schema change therefore reuses OCR; lifecycle clocks and UI changes are
not part of either fingerprint.

## Scheduling and resources

Foreground work defaults to the recent 30-day window. Older history is
persisted as deferred until the user chooses **Run backlog** or constrained
background work receives execution time. Thermal/battery state is read before
jobs:

- serious thermal pressure reduces Fast Scan concurrency to `1` and defers AI;
- critical pressure defers both stages;
- low battery keeps recent Fast Scan available at concurrency `1` but defers AI;
- historical background Fast Scan requires charging, battery-not-low, and idle
  constraints.

Android uses WorkManager. iOS uses `BGProcessingTask` through the same Flutter
Workmanager adapter. Background execution is best-effort on both systems and is
limited to 40 metadata jobs per wake. Deep local AI remains foreground-only in
the scheduler because the app's custom model bridges are not assumed to be
available in a headless Flutter engine. The next foreground session resumes
those persisted Deep jobs.

Official platform behavior:

- Android WorkManager constraints: <https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work>
- Android thermal status: <https://developer.android.com/reference/android/os/PowerManager#getCurrentThermalStatus()>
- Apple thermal state: <https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.property>
- Apple background tasks: <https://developer.apple.com/documentation/backgroundtasks>

## Gemini Nano prompt optimization

The Android bridge now reuses one `GenerativeModel` client and separates static
instructions from per-screenshot JSON. Event, place, commerce, coupon, and
conversation-task hints select smaller guided output envelopes with lower token
limits.

ML Kit currently exposes prompt-prefix caching as experimental, and its
`GenerateContentRequest` documentation explicitly says `promptPrefix` is not
supported with image input. Screenshot Inbox uses multimodal requests, so it
does not enable that incompatible API. The relevant official references are:

- <https://developers.google.com/android/reference/com/google/mlkit/genai/prompt/GenerateContentRequest>
- <https://developers.google.com/android/reference/com/google/mlkit/genai/prompt/GenerativeModel>

## Local benchmark result

The committed bilingual/noisy corpus contains 36 cases: 31 deliberately
actionable cases and 5 negatives. The selective eligibility benchmark sends
31/36 to Deep Analysis and skips 5/36 (13.9%). This corpus is intentionally
action-heavy and is not a claim about a user's library. The fake queue benchmark
covers 100, 500, 1,500, and 5,000 metadata-only jobs plus a 500-job restart. On
the development Mac, all five heap-backed queue cases completed inside the
test reporter's same one-second interval after test loading. This measures queue
overhead only, not image decoding, OCR, database I/O, or local AI.

No physical-device duration, heat, or memory figures are recorded here. Those
must come from a real device and must not be inferred from fakes.

## Physical Android checklist

Record from the debug processing page/logs:

- screenshots discovered, Fast scanned, Deep analyzed, AI skipped, cached,
  deferred, and failed;
- configured/observed Fast and AI concurrency;
- average OCR time, average AI time, AI p50, and AI p95;
- navigation/scroll responsiveness, heat, and memory behavior.

Use a library near 1,500 screenshots, cold-start once, background/foreground the
app, and reopen it to prove that cached OCR/AI is not repeated.

## Remaining bottlenecks

- Metadata discovery still enumerates the complete screenshot album to detect
  deletions; it does not load image bytes, but OEM album behavior needs physical
  testing.
- Drift inbox queries still hydrate broad result sets and search is not FTS5.
- ML Kit OCR and platform channels are native plugin calls; they cannot be moved
  to a Dart isolate safely. Large pure-Dart work remains bounded per screenshot.
- Background timing is controlled by each OS. iOS does not promise a periodic
  cadence, and Deep local AI is intentionally deferred to foreground.
- Native Android/iOS source has not been platform-built under the repository's
  no-build rule; it requires the documented physical-device pass.
