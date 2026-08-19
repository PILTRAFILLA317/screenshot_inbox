# Interpretation root cause (post Phase 2.5)

## Meaning of the old diagnostic

The tuple below was produced before any native-provider work happened:

```text
parser: generic.v1
provider: null
availability: null
reason: policy
```

`IntelligenceEnricher.enrich` called `_shouldInterpret` before
`IntelligenceProvider.availability`. `_shouldInterpret` only accepted six
deterministic object types. `generic.v1` normally represented classifications
that had already fallen back to `reference` or `other`, so it failed that type
allow-list and returned immediately. As a consequence no provider was selected,
availability was never queried, and inference could not be invoked.

The debug default was already named `alwaysForSupportedTypes`, but its behavior
was effectively the same as `actionableTypes`; the implementation did not have
a broader provider-supported set. Changing only the configured policy could not
recover a screenshot that the deterministic classifier had already degraded to
`reference`.

## Second independent break in the flow

Even on the path that reached native inference, `IntelligenceRequest` contained
OCR blocks, entities, candidates, time, locale, and timezone only.
`ProcessingContext.imageBytes` was never copied to the request. Both native
bridges therefore performed text-only inference while the product behavior
needed visual/UI context.

## Corrected contract

- `alwaysForSupportedTypes` includes safe discovery inputs (`reference`,
  `other`, and `generic`) so local intelligence can correct deterministic
  misclassification during development.
- `actionableTypes` and `lowConfidenceOnly` remain narrower production choices.
- Provider availability is checked only after a documented policy decision, and
  every exit reports a distinct result: `policySkipped`, `providerUnavailable`,
  `providerError`, `invalidResult`, `timeout`, or `success`.
- The Android provider receives a resized screenshot plus structured OCR blocks,
  UI/duplicate weights, deterministic entities/candidates, type hint, capture
  time, locale, and timezone.
- Diagnostics report actual provider modality returned by the native bridge;
  they do not infer `imageInput` merely because bytes were requested.
