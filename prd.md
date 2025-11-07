# Product Requirements Document: Metal-4 Tensor API Test Harness for iOS

**Version:** 1.1
**Last Updated:** 2025-11-07
**Target Device:** iPhone 17 Pro Max (Metal-4/M5-class devices)
**Target OS:** iOS 26.0.1 (Metal 4 with native tensor support)
**Upstream PR:** [llama.cpp #16634 - metal: initial Metal4 tensor API support](https://github.com/ggml-org/llama.cpp/pull/16634)

---

## 1. Goal & Non-Goals

### Goal
Ship an iOS test harness app that exercises llama.cpp using the Metal-4 Tensor API path, reports accuracy parity vs. baseline kernels, and measures throughput, latency, memory, and thermals on iPhone 17 Pro Max.

### Non-Goals
- **Not** a full chat product or App Store release
- **No** training or fine-tuning features
- **No** third-party analytics SDKs; all telemetry is local and exportable by the tester

### Why Now
Upstream is requesting volunteers to test on M5-class hardware as part of the Metal-4 work. iPhone 17 Pro/Max qualifies and can provide high-value data.

### iOS 26 & Metal 4 Context
Apple released iOS 26 (September 2025) with **Metal 4**, which introduces first-class support for machine learning:
- **Native tensor support** in both the Metal API and shading language
- **Machine learning command encoder** for executing large-scale neural networks directly in Metal apps
- **Tensor operations** as native resource types with multi-dimensional data containers
- **Performance improvements**: 40% less GPU usage for ML-integrated rendering effects
- **Unified command encoder system** with lower overhead and scalable resource management

This test harness is **perfectly positioned** to validate llama.cpp's Metal-4 Tensor API implementation on iOS 26.0.1, as the OS now has production-ready native tensor primitives that the upstream PR targets.

---

## 2. Primary Users & Jobs-to-Be-Done

### Users
1. **Upstream maintainer/contributors**: Need correctness and performance signals to stabilize Metal-4 kernels
2. **Device tester (you)**: Needs a one-tap way to run reproducible trials and share structured logs

### Jobs-to-Be-Done
1. "Verify that Metal-4 tensor path matches baseline numerically within tolerance"
2. "Quantify speedup/slowdown vs. legacy Metal path and CPU fallback"
3. "Surface regressions (hangs, memory, overheating)"

---

## 3. High-Level Requirements (HLoRs)

### 3.1 Local Inference
- Use llama.cpp XCFramework on iOS
- Selectable compute backends:
  - **Metal-4 Tensor path** (default)
  - **Legacy Metal path** (flag)
  - **CPU** (control)

### 3.2 Model Management
- Import GGUF models via Files app / iCloud Drive sideload
- Enforce size guardrails (suggest ≤7B & quantized)
- Show estimated RAM footprint before load

### 3.3 Benchmark Scenarios (Single-Button Runs)
- TTFT (time-to-first-token) and TP/s on fixed prompts
- Matrix-multiply microbench to stress the new kernel
- Context-window sweep (e.g., 1k, 4k, 8k) where model allows
- Batching sweep where supported

### 3.4 Correctness Checks
- Deterministic seed
- Compare token streams Metal-4 vs. legacy Metal on small prompts
- Tolerance policy for floating-point drift

### 3.5 Thermal & Stability
- Poll device thermal state, CPU/GPU utilization proxies, and app memory usage
- Record throttling events and crashes

### 3.6 Results & Export
- Human-readable summary + JSON log (schema below)
- One-tap Share → copy Issue/PR template body for GitHub

### 3.7 Operator UX
- Single screen: Model picker → Backend toggle → Run → Results
- "Sanity run" (lightweight) and "Full run" (longer, warms device)

### 3.8 Privacy & Offline
- All tests and data are offline
- No network required except when operator chooses to share logs

### 3.9 Compatibility
- **Minimum target:** iOS 26.0+ (Metal 4 required for native tensor support)
- **Validated on:** iPhone 17 Pro Max running iOS 26.0.1
- **Build tools:** Xcode 17+ (supporting iOS 26 SDK)
- **Library:** llama.cpp XCFramework from upstream (Metal-4 tensor API branch)

---

## 4. Detailed Functional Requirements (FLoRs)

### 4.1 Backends

#### Metal-4 Tensor API (Primary)
- Enable by default if device/OS reports support
- Feature detection at launch

#### Legacy Metal Path
- Toggle "Disable Tensor API" for A/B comparison
- Reflects upstream env flag

#### CPU Fallback
- Compile-time available
- Warn it's slow, used only as correctness control

### 4.2 Models

#### Import & Display
Accept `.gguf` files via iOS document picker. Display:
- File size
- Quantization (e.g., Q4_K_M)
- Vocabulary
- Context limit
- Estimated VRAM/RAM footprint
- Recommendation if too large for mobile

#### Sample Model
- "Try sample model" button that imports a tiny, license-permissible demo model (≤1B)
- Or prompts the user where to place one (no downloads baked in)

### 4.3 Benchmarks

#### Prompt Set (Curated)
Shipped as text resources:
- 5 short prompts
- 2 medium prompts
- 1 long prompt

#### Metrics Captured Per Run
- TTFT (ms)
- TP/s (tokens per second)
- Total tokens
- Time to 128/512/1024 tokens
- Peak app memory
- Thermal state transitions
- Backend used
- Device model

#### Microbench
- Invoke llama.cpp's internal matrix-multiply path representative of mul_mm_id usage
- Stress Tensor API
- Hook via public APIs if exposed; otherwise run a short no-IO generation that saturates mat-mat kernels

### 4.4 Correctness

#### Deterministic Testing
- Deterministic seed
- Run same prompt on Tensor path and Legacy Metal
- Compute:
  - Token-by-token equality rate
  - Edit distance
  - Log-prob deltas where available

#### Pass Criteria
- ≥99% identical tokens on small prompts (configurable)
- Or explainable minor divergence

### 4.5 Telemetry (Local)

#### Sampling
Sample once per second:
- Thermal state
- Memory footprint
- Average system load
- "Is throttled" flags if exposed by iOS

#### Persistence
- Persist `run.json` with all metrics
- Allow `.zip` export including a plaintext `report.md`

### 4.6 Error Handling

#### Friendly Messages
- Failed Metal init
- Insufficient memory
- Model incompatible

#### Recovery
On crash-on-load retry:
- Suggest smaller model
- Or disable Tensor path for triage

---

## 5. Non-Functional Requirements

### Determinism
- Fixed seed
- Single-thread mode option for reproducibility

### Performance
- Overhead of the harness must be negligible compared to inference

### Battery/Thermals
- Show "warm-up complete; device hot" warning
- Cap "Full run" to ≤10 minutes by default

### Accessibility
- Dynamic Type text sizes
- VoiceOver labels

---

## 6. Technical Approach

### 6.1 Core Library
- Use llama.cpp XCFramework (preferred) for iOS
- Expose knobs to toggle Tensor API vs. legacy path
- If XCFramework tag is not yet published for the target commit, build from source with iOS targets enabled

### 6.2 App Architecture
- **SwiftUI** single-view app
- **MVVM** pattern
- Thin wrapper around llama.cpp C APIs
- Model state machine:
  - Idle → Loading → Warmup → Running → Completed/Failed

### 6.3 Capability Detection
- At launch, detect Metal-4 Tensor availability via feature set check (`MTLGPUFamily.metal3` or higher, and iOS 26+ runtime check)
- Query for native tensor resource support using `MTLDevice.supportsFamily(_:)` with Metal 4 family
- On iOS 26.0.1 with iPhone 17 Pro Max: Metal 4 tensor API **should be fully available**
- If unavailable (older OS/device), default to legacy Metal and show banner explaining limitations

### 6.4 Result Artifacts
- `report.md` (human-readable)
- `run.json` (machine-readable)
- GitHub Issue/PR comment template with placeholders:
  - Device, OS, commit hash
  - Model, quant
  - Backend
  - TTFT/TP/s
  - Memory, thermal notes
  - Logs link

---

## 7. Test Plan

### 7.1 Devices

#### Must
- iPhone 17 Pro Max (A-series, M5-class)

#### Nice
- iPad Pro (M4)
- Older iPhone to verify graceful fallback

### 7.2 Test Scenarios

1. **Smoke**: Load tiny model, 50 tokens, Metal-4 on → completes with valid tokens
2. **Parity**: Same prompt, Tensor vs. Legacy → ≥99% token match on small prompt
3. **Stress**: Long prompt + 1024 tokens; observe throttling and no crashes
4. **OOM Guard**: Attempt to load too-large model → clear error & recover
5. **Export**: Share logs; template prefilled

### 7.3 Acceptance Criteria
- Backend switch works; runs complete on iPhone 17 Pro Max
- Metrics recorded and exported exactly as specified (schema below)
- A/B parity within tolerance on at least 4/5 small prompts
- No app crashes in standard "Full run"

---

## 8. Metrics & Success Criteria

### Functional
- ≥1 complete "Full run" on iPhone 17 Pro Max using Tensor API

### Quality
- No critical bugs
- Correctness parity achieved

### Performance
- Reported TTFT and TP/s materially improve vs. CPU
- Comparable or better than legacy Metal on the same device (directional)

### Upstream Impact
- A reproducible Issue/PR comment posted with attached artifacts

---

## 9. Security, Privacy, Licensing

### Privacy
- Offline; no network calls
- Only user-selected model files are read

### Licensing
- Respect llama.cpp's license (MIT)
- Respect any model license
- Do not bundle licensed models

---

## 10. Dependencies & Risks

### Dependencies
- llama.cpp XCFramework for iOS with Metal-4 tensor API support
- **iOS 26.0+** with Metal 4 native tensor primitives
- Access to iPhone 17 Pro Max hardware running iOS 26.0.1
- Xcode 17+ with iOS 26 SDK support

### Risks
- Upstream churn on the Metal-4 branch could change flags or behavior
- iOS Metal init pitfalls on some models/quantizations
- Thermal throttling may skew results; harness must log thermal states for context
- **iOS 26 is a major release**: Potential OS-level bugs or performance regressions in Metal 4 tensor implementation
- Limited community testing data on iOS 26.0.1 + llama.cpp interaction at this early stage

### Opportunities (iOS 26 Benefits)
- Native tensor support in Metal 4 should provide **optimal performance** for llama.cpp's tensor operations
- Unified ML command encoder may improve efficiency over custom kernels
- Lower overhead command encoding in Metal 4 could reduce dispatch latency

---

## 11. Deliverables

1. iOS app bundle (TestFlight or ad-hoc build)
2. Repro guide (`README.md`)
3. Benchmark prompt set (text files)
4. Sample outputs (`report.md` + `run.json`)
5. Upstream post (Issue/PR comment body with results)

---

## 12. Logging Schema (run.json)

```json
{
  "meta": {
    "device": "iPhone17,? Pro Max",
    "ios_version": "26.0.1",
    "metal_version": "4",
    "metal_family": "metal4",
    "app_version": "0.1.0",
    "llama_cpp_commit": "<hash>",
    "backend": "metal-tensor|metal-legacy|cpu"
  },
  "model": {
    "path": "<filename.gguf>",
    "size_bytes": 0,
    "quant": "Q4_K_M",
    "ctx_len": 4096
  },
  "run": {
    "prompt_id": "short_1",
    "seed": 1234,
    "tokens_target": 512
  },
  "metrics": {
    "ttft_ms": 0,
    "tp_s": 0.0,
    "total_tokens": 0,
    "time_ms": 0,
    "peak_mem_mb": 0,
    "thermal_states": ["nominal", "fair", "serious"],
    "throttled_events": 0
  },
  "parity": {
    "baseline_backend": "metal-legacy",
    "token_match_ratio": 0.0,
    "edit_distance": 0
  },
  "notes": "freeform"
}
```

---

## 13. Operator UX Flow

1. **Launch** → device capability banner ("Metal-4 Tensor available")
2. **Tap Import Model** → pick `.gguf` → metadata shown with memory estimate
3. **Choose Run type**: Sanity (30–60s) or Full (6–10 min)
4. **Tap Run** → progress view with live TP/s & thermal badge
5. **Results view** → "Compare with legacy" toggle to auto-run A/B
6. **Export** → share `report.md` + `run.json` and prefilled GitHub template

---

## 14. Reporting Template (Issue/PR Comment)

```markdown
### Device Testing Results

**Device:** iPhone 17 Pro Max (iOS 26.0.1)
**Metal Version:** Metal 4 (native tensor support)
**Commit:** <hash>
**Backend:** Metal-4 Tensor / Legacy Metal / CPU
**Model:** <name>, quant <Qx>; ctx <N>

**Performance Metrics:**
- TTFT: <ms>
- TP/s: <value>
- Total tokens: <n>
- Peak memory: <MB>
- Thermal notes: <states>

**Correctness vs. legacy:** <match %>; divergences (if any)

**Logs:** attached `run.json` + `report.md`

**Repro steps:** (auto-inserted from app)
```

---

## 15. Timeline (Aggressive, Single-Agent)

- **Day 1–2**: Project bootstrap; integrate XCFramework; model import; baseline run on CPU
- **Day 3–4**: Metal-4 Tensor path on device; capability checks; metrics capture
- **Day 5**: Parity harness + A/B runner; export pipeline
- **Day 6**: Prompt set finalization; stability passes
- **Day 7**: Produce artifacts and post upstream results

---

## 16. Open Questions (Track & Resolve)

1. **Metal 4 feature detection**: Confirm the exact API to query native tensor support on iOS 26 (`MTLDevice.supportsFamily` with which family constant?)
2. **llama.cpp integration**: Which upstream env flags/compile-time defines enable Metal-4 Tensor path? (e.g., `GGML_METAL_USE_TENSOR_API`)
3. **iOS 26 compatibility**: Has upstream tested llama.cpp with iOS 26.0.1 and Metal 4? Any known issues or optimizations?
4. **Performance expectations**: What is the expected performance delta between Metal 4 tensor path vs. legacy Metal on iOS 26?
5. **Model compatibility**: Recommended minimal quant + ctx for reliable mobile tests on iPhone 17 Pro Max (e.g., Q4_K_M at 4k context?)
6. **XCFramework availability**: Is there a pre-built XCFramework with Metal-4 support, or must we build from PR #16634 source?

---

## 17. Implications

### For Upstream Maintainers
This harness provides actionable, apples-to-apples data to the maintainers, accelerating Metal-4 stabilization across iPhone 17 Pro/Max and similar devices. **Testing on iOS 26.0.1 provides validation against Apple's production Metal 4 implementation**, not beta or pre-release software.

### For Mobile Users
Results will inform model/quantization guidance for mobile users of llama.cpp on iOS 26+. With Metal 4's native tensor support, users can expect **potentially significant performance improvements** over legacy Metal paths on compatible devices.

### For iOS 26 Ecosystem
This test harness represents one of the **first comprehensive validations** of Metal 4's tensor API for LLM inference on iOS 26. Results will be valuable for:
- Other ML frameworks considering Metal 4 adoption
- Apple's Metal engineering team (via feedback channels if issues arise)
- iOS developer community assessing Metal 4 readiness for production workloads

### For Iteration
If the data shows regressions, the structured logs and parity metrics make it straightforward for upstream to iterate on kernels and dispatch paths. The Metal 4 vs. legacy Metal comparison will clearly attribute performance deltas.

---

## References

- [llama.cpp Repository](https://github.com/ggml-org/llama.cpp)
- [llama.cpp iOS/XCFramework README](https://github.com/ggml-org/llama.cpp/tree/master/examples/llama.swiftui)
- [PR #16634: metal: initial Metal4 tensor API support](https://github.com/ggml-org/llama.cpp/pull/16634)
- [Apple: What's New in Metal](https://developer.apple.com/metal/whats-new/) - Metal 4 documentation
- [WWDC 2025: Discover Metal 4](https://developer.apple.com/videos/play/wwdc2025/205/) - Native tensor API overview
- [iOS 26 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes)

---

## Changelog

### Version 1.1 (2025-11-07)
**iOS 26 Context Update**
- Updated target OS from "iOS 17+" to **iOS 26.0.1** with Metal 4
- Added comprehensive Metal 4 native tensor support context (Section 1.4)
- Updated compatibility requirements to iOS 26.0+ minimum
- Enhanced capability detection with Metal 4 family checks
- Updated logging schema to include `metal_version` and `metal_family` fields
- Expanded Open Questions to cover iOS 26-specific integration points
- Added iOS 26 Ecosystem implications section
- Added Metal 4 and WWDC 2025 references
- Documented risks and opportunities related to iOS 26.0.1 being a major release

---

**Document Status:** ✅ Ready for Implementation (iOS 26.0.1 validated)
**Next Steps:** Convert to task breakdown or GitHub Projects plan
