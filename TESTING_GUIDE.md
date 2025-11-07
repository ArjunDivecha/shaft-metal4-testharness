# Testing Guide: Metal-4 Tensor API Test Harness

**Target Device:** iPhone 17 Pro Max
**Target OS:** iOS 26.0.1
**Last Updated:** 2025-11-07

---

## Prerequisites

### Hardware
- ✅ iPhone 17 Pro Max running iOS 26.0.1
- Mac with Xcode 17+ (for building)
- USB-C cable (for initial deployment) or WiFi network

### Software
- Xcode 17+ with iOS 26 SDK
- Apple Developer account (free tier works for local testing)
- GGUF model files (see Model Preparation section)

### Optional
- TestFlight access (for easier repeated testing)
- iCloud Drive (for easy model transfer)

---

## Part 1: Building the App

### Step 1: Clone and Open Project

```bash
cd shaft-metal4-testharness
open MetalTensorHarness.xcodeproj  # Or .xcworkspace if using dependencies
```

### Step 2: Configure Signing

1. In Xcode, select the project in the navigator
2. Select the "MetalTensorHarness" target
3. Go to "Signing & Capabilities"
4. Select your Team (Apple ID)
5. Xcode will auto-generate a bundle ID like `com.yourname.MetalTensorHarness`

### Step 3: Set Deployment Target

1. In "General" tab, set "Minimum Deployments" to **iOS 26.0**
2. Confirm "Supported Destinations" includes iPhone

### Step 4: Build llama.cpp XCFramework

If pre-built XCFramework is not available:

```bash
# Clone llama.cpp with Metal-4 branch
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
git fetch origin pull/16634/head:metal4-tensor
git checkout metal4-tensor

# Build XCFramework for iOS
cmake -B build-ios \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DGGML_METAL=ON \
  -DGGML_METAL_USE_TENSOR_API=ON \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-ios --config Release

# Create XCFramework
# (follow llama.cpp's iOS build instructions for XCFramework creation)
```

Drag the resulting `llama.xcframework` into your Xcode project.

---

## Part 2: Deploying to iPhone 17 Pro Max

### Method A: Direct Xcode Install (Recommended for Development)

1. **Connect iPhone:**
   - USB-C cable: Plug in and trust computer
   - WiFi: Window → Devices and Simulators → Connect via Network

2. **Select Device:**
   - In Xcode toolbar, click device selector
   - Choose your iPhone 17 Pro Max

3. **Run:**
   - Press ⌘R or click the Play button
   - Xcode builds, installs, and launches the app
   - First time: Trust developer certificate on iPhone (Settings → General → VPN & Device Management)

4. **Debugging:**
   - View console logs in Xcode while app runs
   - Use breakpoints for troubleshooting

**Pros:** Instant deployment, live debugging
**Cons:** Requires Mac/cable nearby

### Method B: TestFlight Install (Recommended for Field Testing)

1. **Archive the App:**
   - Product → Archive
   - Wait for build to complete
   - Organizer window opens

2. **Upload to App Store Connect:**
   - Click "Distribute App"
   - Choose "TestFlight & App Store"
   - Select your team
   - Upload

3. **Configure TestFlight:**
   - Go to App Store Connect
   - Select your app
   - Go to TestFlight tab
   - Add yourself as an internal tester
   - App auto-distributes (usually within minutes)

4. **Install on iPhone:**
   - Open TestFlight app on iPhone
   - Accept invite
   - Tap "Install"
   - Launch from home screen

**Pros:** No cable needed, easy updates, realistic testing
**Cons:** Initial setup required, slight upload delay

### Method C: Ad-Hoc Build (For Offline Testing)

1. **Export Ad-Hoc IPA:**
   - Product → Archive
   - In Organizer, click "Distribute App"
   - Choose "Ad Hoc"
   - Export IPA file

2. **Install via Xcode:**
   - Window → Devices and Simulators
   - Select your iPhone
   - Drag IPA onto device list
   - Or click "+" and select IPA

**Pros:** No internet required, portable
**Cons:** Manual installation process

---

## Part 3: Preparing Models

### Model Requirements

**Recommended for iPhone 17 Pro Max:**
- Model size: ≤7B parameters
- Quantization: Q4_K_M or Q4_0 (balance of quality/memory)
- Context length: 4096 tokens
- Format: GGUF

**Example Models (if license permits):**
- Llama-3.2-3B-Instruct (Q4_K_M) - ~2GB
- Phi-3.5-mini-instruct (Q4_K_M) - ~2.4GB
- Qwen2.5-3B-Instruct (Q4_K_M) - ~2GB

### Getting Models onto iPhone

**Option 1: iCloud Drive (Easiest)**

1. On Mac/PC:
   - Place `.gguf` file in iCloud Drive folder
   - Wait for sync

2. On iPhone:
   - Open Files app
   - Navigate to iCloud Drive
   - Models are accessible to the test harness via document picker

**Option 2: AirDrop**

1. On Mac:
   - Right-click `.gguf` file
   - Share → AirDrop → Your iPhone

2. On iPhone:
   - Accept file
   - Save to Files app → On My iPhone

**Option 3: Direct USB Transfer**

1. On Mac:
   - Connect iPhone via USB
   - Open Finder → Your iPhone
   - Go to Files tab
   - Drag `.gguf` file to MetalTensorHarness (if app supports File Sharing)

**Storage Note:** A 4B Q4_K_M model needs ~2.5GB. Ensure iPhone has 5GB+ free space.

---

## Part 4: Running Tests

### Initial Launch

1. **Launch app** from home screen
2. **Check banner:** "Metal-4 Tensor API Available ✓" (or fallback notice)
3. **Grant permissions** if prompted (Files access)

### Basic Test Run

1. **Import Model:**
   - Tap "Import Model" or "📁" button
   - Files picker opens
   - Navigate to your `.gguf` file
   - Tap to select
   - App displays model metadata:
     - Size: 2.1 GB
     - Quantization: Q4_K_M
     - Context: 4096
     - Estimated RAM: ~3.2 GB

2. **Select Backend:**
   - Toggle: **Metal-4 Tensor** (default) / Legacy Metal / CPU
   - Start with Metal-4 Tensor

3. **Choose Run Type:**
   - **Sanity Run:** 30-60 seconds, light load, quick validation
   - **Full Run:** 6-10 minutes, comprehensive benchmarks, warms device

4. **Tap "Run":**
   - Progress view appears
   - Live metrics:
     - Current token/sec (TP/s)
     - Thermal state badge (🟢 nominal / 🟡 fair / 🔴 serious)
     - Tokens generated: 45/512
   - Progress bar

5. **View Results:**
   - TTFT: 245ms
   - Average TP/s: 28.3
   - Peak memory: 3,421 MB
   - Thermal notes: Nominal throughout
   - Correctness: N/A (baseline needed)

### A/B Comparison Run

To compare Metal-4 Tensor vs. Legacy Metal:

1. Complete run with **Metal-4 Tensor** (as above)
2. Results screen shows "Compare with Legacy" button
3. Tap button → app auto-runs same prompt with **Legacy Metal** backend
4. Results screen updates with side-by-side comparison:
   ```
   Metal-4 Tensor:  TTFT 245ms, TP/s 28.3
   Legacy Metal:    TTFT 289ms, TP/s 24.1
   Speedup:         +17.4% TP/s
   Token Match:     99.8% (511/512 identical)
   ```

### Full Benchmark Suite

For comprehensive testing (select "Full Run"):

- Runs all 8 curated prompts (5 short, 2 medium, 1 long)
- Context window sweep: 1k, 4k, 8k (if model supports)
- Captures thermal state transitions
- Generates complete `run.json` with all scenarios
- Duration: ~8 minutes on iPhone 17 Pro Max

---

## Part 5: Exporting Results

### Export Flow

1. **Results Screen:**
   - After run completes, tap "Export" or Share icon

2. **Share Sheet Opens:**
   - Three files attached:
     - `report.md` - Human-readable summary
     - `run.json` - Machine-readable full log
     - `github-template.md` - Pre-filled Issue/PR comment

3. **Sharing Options:**
   - **AirDrop** to Mac (for immediate analysis)
   - **Save to Files** (for archival)
   - **Mail** (attach to email for sharing)
   - **Messages** (send to collaborators)
   - **Copy** (for pasting into GitHub directly)

### What's in the Export

**report.md Example:**

```markdown
# Metal-4 Tensor API Test Results

**Date:** 2025-11-07 14:32:19
**Device:** iPhone 17 Pro Max (iOS 26.0.1)
**Metal:** Version 4, Family metal4
**Backend:** Metal-4 Tensor API
**Model:** phi-3.5-mini-instruct-Q4_K_M.gguf (2.4 GB)

## Performance Metrics

- Time to First Token (TTFT): 245ms
- Tokens per Second (TP/s): 28.3
- Total Tokens: 512
- Peak Memory: 3,421 MB
- Run Duration: 18.1s

## Thermal Profile

- Initial: Nominal
- Peak: Fair (reached at T+12s)
- Final: Fair
- Throttling Events: 0

## Correctness vs. Legacy Metal

- Token Match Rate: 99.8% (511/512)
- Edit Distance: 1
- Notes: Single token divergence at position 347 (Metal-4: "the", Legacy: "a")
```

**run.json:** Structured data matching schema in PRD Section 12

**github-template.md:** Ready to paste into PR #16634

---

## Part 6: Interpreting Results

### Performance

**Good Results (Metal-4 Tensor on iPhone 17 Pro Max):**
- TTFT: <300ms for 3B models
- TP/s: 25-35 tokens/sec for Q4_K_M 3B models
- Speedup vs. Legacy Metal: +10% to +20%
- Memory: ~2-4 GB for 3B models

**Red Flags:**
- TTFT >1000ms: Model too large or init issues
- TP/s <10: Thermal throttling or fallback to CPU
- Memory >6GB: Risk of crash on lower-memory devices

### Correctness

**Expected:**
- Token match rate ≥99% vs. Legacy Metal
- Occasional minor divergence due to floating-point differences
- Should be deterministic across repeated runs with same seed

**Concerning:**
- Match rate <95%: Potential Metal-4 kernel bug
- Gibberish output: Model incompatibility or corruption
- Crash during generation: Memory issue or API misuse

### Thermal

**Normal:**
- Nominal → Fair over 5-10 minutes
- Return to Nominal after 2-3 minutes idle

**Throttling Indicators:**
- Fair → Serious within first minute
- TP/s drops by >30% mid-run
- System thermal throttling logged

If throttling occurs:
1. Let device cool (airplane mode, screen off, 5 min)
2. Reduce workload (smaller model, shorter run)
3. Note in GitHub report: "Throttled on [device] due to ambient temp [X]°C"

---

## Part 7: Posting Results Upstream

### To PR #16634

1. **Export results** as described above
2. **Navigate to** https://github.com/ggml-org/llama.cpp/pull/16634
3. **Add comment:**
   - Paste `github-template.md` content
   - Or use "Attach files" to upload `run.json` + `report.md`
4. **Include context:**
   - Ambient temperature if relevant
   - Any issues/crashes encountered
   - Suggestions for maintainers

### Example Post

```markdown
### iPhone 17 Pro Max Testing Results ✅

**Device:** iPhone 17 Pro Max (iOS 26.0.1, Metal 4)
**Commit:** [hash from PR]
**Model:** Phi-3.5-mini-instruct Q4_K_M (2.4 GB)
**Backend:** Metal-4 Tensor API

**Performance:**
- TTFT: 245ms
- TP/s: 28.3 (avg over 512 tokens)
- **+17.4% faster** than legacy Metal path on same device

**Correctness:**
- 99.8% token match vs. legacy Metal
- Single minor divergence at token 347 (acceptable)

**Stability:**
- No crashes over 15 test runs
- Thermal state: Nominal → Fair (expected)
- Peak memory: 3.4 GB

**Logs:** [attach run.json + report.md]

**Verdict:** Metal-4 Tensor path working excellently on iPhone 17 Pro Max + iOS 26.0.1. Recommend merge pending other device validations.
```

---

## Part 8: Troubleshooting

### App Won't Install

**"Untrusted Developer"**
- Go to Settings → General → VPN & Device Management
- Tap your Apple ID → Trust

**"Unable to Install"**
- Check iPhone storage (need 500MB+ free)
- Reboot iPhone and retry
- In Xcode: Clean Build Folder (⌘⇧K), rebuild

### Model Import Fails

**"Unsupported Format"**
- Ensure file is `.gguf` (not `.bin` or `.safetensors`)
- Check file isn't corrupted (compare hash with source)

**"File Too Large"**
- Model exceeds device memory
- Try smaller model (3B instead of 7B)
- Or use more aggressive quantization (Q4_0 instead of Q4_K_M)

### Run Crashes/Hangs

**Crash on "Run"**
- Check Xcode console for error messages
- Common issues:
  - Out of memory: Use smaller model
  - Metal init failure: Check device supports Metal 4
  - Model corruption: Re-download

**Hang (no progress)**
- Wait 30 seconds (large models have slow init)
- If still hung, force-quit app
- Check model compatibility with llama.cpp version
- Try CPU backend to isolate Metal issue

### Metal-4 Not Detected

**"Metal-4 Tensor API Unavailable"**
- Verify iOS version: Settings → General → About → Software Version
  - Must be **26.0+**
- Verify device: iPhone 17 Pro/Max required
- If both correct, check Xcode logs for Metal feature set detection

### Performance Issues

**Very Slow (TP/s <5)**
- App may have fallen back to CPU
- Check backend toggle shows "Metal-4 Tensor"
- Check Xcode console for Metal warnings
- Thermal throttling: Let device cool, retry

**Slower than Expected**
- Define baseline: Compare to legacy Metal on same device
- Thermal state: "Serious" = throttling active
- Background apps: Close all other apps
- Battery: Plug in for max performance

---

## Part 9: Tips for Best Results

### Environment

- **Temperature:** Test in 20-25°C room (avoid direct sunlight/heat)
- **Charge:** Plug in iPhone (better sustained performance)
- **Clean slate:** Restart iPhone before long test runs
- **Background:** Close all apps, disable Background App Refresh

### Testing Strategy

1. **Warmup run:** One short run to warm device and load model into memory
2. **Wait 30s:** Let thermals stabilize
3. **Main run:** Now run your timed benchmark
4. **Repeat:** Do 3 runs, report median TP/s (reduces variance)

### Model Selection

- **Start small:** Test with 3B model before trying 7B
- **Quantization:** Q4_K_M offers best quality/performance balance
- **Context:** Use 4k context for most tests (8k for stress testing)

### Documentation

For each test, note:
- Ambient temperature (if extreme)
- iPhone battery level and charging state
- Time since last reboot
- Any background activity (downloads, etc.)

Include these details in GitHub reports for reproducibility.

---

## Part 10: Quick Reference

### Deployment Commands

```bash
# Build via CLI (instead of Xcode GUI)
xcodebuild -project MetalTensorHarness.xcodeproj \
  -scheme MetalTensorHarness \
  -configuration Release \
  -destination 'platform=iOS,name=Your iPhone' \
  build

# Install via CLI
ios-deploy --bundle path/to/MetalTensorHarness.app
```

### Model Download (Example)

```bash
# Using Hugging Face CLI (if you have access to models)
huggingface-cli download \
  microsoft/Phi-3.5-mini-instruct-gguf \
  Phi-3.5-mini-instruct-q4.gguf \
  --local-dir ./models

# Then transfer to iPhone via methods above
```

### Expected File Sizes

| Model | Params | Quant | Size | iPhone RAM |
|-------|--------|-------|------|------------|
| Llama-3.2-3B | 3B | Q4_K_M | ~2.0 GB | ~3.0 GB |
| Phi-3.5-mini | 3.8B | Q4_K_M | ~2.4 GB | ~3.4 GB |
| Qwen2.5-3B | 3B | Q4_K_M | ~2.0 GB | ~3.1 GB |
| Llama-3.2-7B | 7B | Q4_K_M | ~4.0 GB | ~5.8 GB |

*RAM includes model + KV cache + app overhead*

---

## Support & Feedback

**For App Issues:**
- Check this guide's Troubleshooting section
- Review Xcode console logs
- File issue in this repo: [link to issues page]

**For llama.cpp/Metal-4 Issues:**
- Post in PR #16634 discussion
- Include device specs, iOS version, logs
- Use the exported `github-template.md` for structured reports

**For Metal 4 / iOS 26 Issues:**
- Check Apple Developer Forums: https://developer.apple.com/forums/tags/metal
- File Feedback Assistant report if suspected iOS bug

---

**Happy Testing! 🚀**

For questions or improvements to this guide, open an issue or PR in the repository.
