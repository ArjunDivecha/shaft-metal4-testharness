# Metal Tensor Harness - Deployment Guide

**Version:** 0.1.0
**Target:** iPhone 17 Pro Max, iOS 26.0.1
**Purpose:** Test llama.cpp Metal-4 Tensor API performance

---

## Quick Start (5 Minutes to Deploy)

### 1. Open in Xcode

```bash
cd MetalTensorHarness
open MetalTensorHarness.xcodeproj
```

**Requirements:**
- Xcode 17+ (supports iOS 26 SDK)
- iPhone 17 Pro Max with iOS 26.0.1
- macOS for building

### 2. Configure Code Signing

1. In Xcode project navigator, select **MetalTensorHarness** (blue icon)
2. Select **MetalTensorHarness** target
3. Go to **Signing & Capabilities** tab
4. Under **Team**, select your Apple ID (free account works!)
5. Xcode will auto-generate bundle identifier: `com.yourname.metaltensor.harness`

**Note:** If you don't have an Apple ID added:
- Xcode → Settings → Accounts → + → Sign in with Apple ID

### 3. Connect iPhone

**Option A: USB Cable** (Recommended for first time)
1. Connect iPhone 17 Pro Max via USB-C
2. On iPhone: Tap "Trust This Computer" when prompted
3. In Xcode toolbar, select your iPhone from device dropdown

**Option B: WiFi** (After initial USB setup)
1. Window → Devices and Simulators
2. Select your iPhone → Check "Connect via network"
3. Disconnect cable, device will remain in list

### 4. Build and Run

1. Press **⌘R** or click the **Play** button in toolbar
2. Wait for build to complete (~30 seconds first time)
3. If prompted on iPhone: Settings → General → VPN & Device Management → Trust developer cert
4. App will launch automatically on your iPhone

**That's it!** The app is now installed and running.

---

## Using the App

### First Run Walkthrough

1. **Check Metal-4 Banner**
   - Green banner: "Metal-4 Tensor API Available ✓"
   - Shows your device capabilities

2. **Import a Model**
   - Tap "Import Model" button
   - Files picker opens
   - Navigate to your `.gguf` model file (see Model Preparation below)
   - Tap to select
   - App displays model info: size, quantization, estimated RAM

3. **Select Backend**
   - Metal-4 Tensor (default, recommended)
   - Legacy Metal (for A/B comparison)
   - CPU (slow, reference only)

4. **Choose Run Type**
   - Sanity Run: 30-60 seconds, 128 tokens
   - Full Run: 6-10 minutes, 512 tokens

5. **Tap "Run Benchmark"**
   - Live metrics appear: tokens/sec, thermal state, memory
   - Progress bar shows completion
   - Wait for "Completed" state

6. **View Results**
   - Results screen auto-opens
   - Shows TTFT, TP/s, memory, thermals
   - Tap "Export Results" to share via AirDrop/Mail

7. **A/B Comparison** (Optional)
   - In results screen, tap "Compare with Legacy Metal"
   - App re-runs same test with different backend
   - Shows token match percentage and performance delta

### Export Files

When you tap "Export Results", three files are created:

- **report.md** - Human-readable summary
- **run.json** - Machine-readable full metrics (matches PRD schema)
- **github-template.md** - Pre-filled for posting to PR #16634

Share via:
- AirDrop to Mac (fastest)
- Mail
- Save to Files
- Copy to paste directly into GitHub

---

## Model Preparation

### Recommended Models for iPhone 17 Pro Max

| Model | Size | Quant | Est. RAM | Notes |
|-------|------|-------|----------|-------|
| **Llama-3.2-3B** | 2.0 GB | Q4_K_M | ~3.0 GB | Best balance |
| **Phi-3.5-mini** | 2.4 GB | Q4_K_M | ~3.4 GB | Excellent quality |
| **Qwen2.5-3B** | 2.0 GB | Q4_K_M | ~3.1 GB | Fast inference |
| TinyLlama-1.1B | 0.6 GB | Q4_K_M | ~1.2 GB | Testing only |

**Where to Get Models:**
- HuggingFace: Search for "[model name] GGUF"
- Download `.gguf` files directly
- Use Hugging Face CLI if you have access

**Transfer to iPhone:**

1. **iCloud Drive** (Easiest)
   - On Mac: Copy `.gguf` to iCloud Drive folder
   - On iPhone: Files app → iCloud Drive → select file in app

2. **AirDrop**
   - Mac: Right-click `.gguf` → Share → AirDrop → Your iPhone
   - iPhone: Accept file → Save to Files

3. **USB Transfer**
   - Connect iPhone to Mac
   - Finder → Your iPhone → Files tab
   - Drag `.gguf` to Metal Tensor Harness (if File Sharing enabled)

### Storage Requirements

- Model file: 2-4 GB typical
- App overhead: ~100 MB
- Temp exports: ~10 MB
- **Total:** ~4-5 GB free space recommended

---

## llama.cpp Integration

### Current Status

The app currently uses a **stub implementation** that simulates llama.cpp behavior for development and testing purposes.

**What works now:**
- ✅ Full UI flow (import model → select backend → run → export)
- ✅ Metrics collection (simulated realistic TP/s, TTFT, thermals)
- ✅ Export system (generates correct report.md, run.json, github-template.md)
- ✅ Metal 4 capability detection
- ✅ A/B comparison workflow

**What needs llama.cpp:**
- ⚠️ Actual model loading and inference
- ⚠️ Real token generation
- ⚠️ Genuine performance measurements

### Integration Steps

When llama.cpp XCFramework is available (from PR #16634 or upstream):

1. **Add XCFramework to Project**
   ```bash
   # Assuming you have llama.xcframework
   cp -r llama.xcframework MetalTensorHarness/
   ```

2. **Link in Xcode**
   - Drag `llama.xcframework` into project navigator
   - Target → General → Frameworks → Ensure llama.xcframework is listed

3. **Create Bridging Header**
   - File → New → Header File: `MetalTensorHarness-Bridging-Header.h`
   - Add:
     ```objc
     #import <llama/llama.h>
     #import <llama/ggml.h>
     ```

4. **Update Build Settings**
   - Target → Build Settings
   - Search "Bridging"
   - Set "Objective-C Bridging Header" to path: `MetalTensorHarness-Bridging-Header.h`

5. **Replace Stub Code**
   - Open `Services/LlamaWrapper.swift`
   - See integration guide comments at bottom of file
   - Replace stub methods with actual llama.cpp calls

**Detailed integration guide is in the source file:**
`MetalTensorHarness/Services/LlamaWrapper.swift`

---

## Build Configurations

### Debug (Default)

- Faster compilation
- Includes debug symbols
- Use for development and testing

```bash
# Command line build (optional)
xcodebuild -project MetalTensorHarness.xcodeproj \
  -scheme MetalTensorHarness \
  -configuration Debug \
  -destination 'platform=iOS,name=Your iPhone'
```

### Release (For TestFlight/Distribution)

- Optimized
- Smaller binary
- Use for final testing and distribution

To build Release in Xcode:
- Product → Scheme → Edit Scheme → Run → Build Configuration → Release

---

## Troubleshooting

### "Untrusted Developer"

**Problem:** App won't open, shows untrusted developer alert

**Solution:**
1. Settings → General → VPN & Device Management
2. Tap your Apple ID under "Developer App"
3. Tap "Trust [Your Apple ID]"
4. Relaunch app

### "Unable to Install"

**Problem:** App fails to install on iPhone

**Solutions:**
- Check iPhone storage: Need 500MB+ free
- Reboot iPhone
- In Xcode: Product → Clean Build Folder (⌘⇧K)
- Rebuild and retry

### Code Signing Errors

**Problem:** "Signing for MetalTensorHarness requires a development team"

**Solution:**
- Add Apple ID in Xcode → Settings → Accounts
- Select that account as Team in Signing & Capabilities
- Free accounts work fine for local development

### Metal-4 Not Detected

**Problem:** Banner shows "Metal-4 Tensor API Unavailable"

**Check:**
- iPhone model: Must be iPhone 17 Pro or Pro Max
- iOS version: Must be 26.0 or later (Settings → General → About → Software Version)
- If both correct: Check Xcode console for Metal capability logs

### Build Errors

**Common Issues:**

1. **"Cannot find 'MTLGPUFamily' in scope"**
   - Ensure deployment target is iOS 26.0+
   - Check Xcode version supports iOS 26 SDK

2. **"No such module 'SwiftUI'"**
   - Ensure target is set to iOS, not macOS
   - Clean and rebuild

3. **Missing files**
   - Ensure all Swift files are added to target
   - Project → Target → Build Phases → Compile Sources

---

## TestFlight Distribution (Optional)

For easier repeated testing without a cable:

### 1. Archive

- Product → Archive
- Wait for build
- Organizer opens automatically

### 2. Distribute

- Click "Distribute App"
- Choose "TestFlight & App Store"
- Follow prompts (App Store Connect account required)
- Upload

### 3. Configure TestFlight

- Go to [App Store Connect](https://appstoreconnect.apple.com)
- Select your app
- TestFlight tab
- Add yourself as internal tester
- App distributes automatically (~5 minutes)

### 4. Install on iPhone

- Open TestFlight app
- Accept invite
- Tap "Install"
- Launch from home screen

**Benefit:** No cable needed for future updates. Just archive, upload, and it auto-updates on your iPhone.

---

## File Structure

```
MetalTensorHarness/
├── MetalTensorHarness.xcodeproj/     # Xcode project
│   └── project.pbxproj               # Project configuration
├── MetalTensorHarness/               # Source code
│   ├── Info.plist                    # App configuration
│   ├── MetalTensorHarnessApp.swift   # App entry point
│   ├── Views/                        # SwiftUI views
│   │   ├── ContentView.swift         # Main screen
│   │   ├── ResultsView.swift         # Results display
│   │   └── ModelPickerView.swift     # Model selection
│   ├── ViewModels/                   # Business logic
│   │   └── HarnessViewModel.swift    # Main ViewModel
│   ├── Models/                       # Data models
│   │   └── Models.swift              # All structs/enums
│   ├── Services/                     # Core services
│   │   ├── LlamaWrapper.swift        # llama.cpp interface (STUB)
│   │   ├── MetricsCollector.swift    # Performance tracking
│   │   └── ExportService.swift       # File export
│   ├── Utils/                        # Utilities
│   │   ├── MetalCapability.swift     # Metal 4 detection
│   │   ├── DeviceInfo.swift          # Device info
│   │   └── BenchmarkPrompts.swift    # Test prompts
│   └── Resources/                    # Assets
│       └── Assets.xcassets/          # App icons, colors
└── README.md                         # This file
```

---

## Performance Expectations

### Typical Results on iPhone 17 Pro Max

**3B Model, Q4_K_M, 128 tokens:**

| Backend | TTFT | TP/s | Notes |
|---------|------|------|-------|
| **Metal-4 Tensor** | 150-300 ms | 25-35 | Expected performance |
| **Legacy Metal** | 200-350 ms | 20-28 | Baseline comparison |
| **CPU** | 800-1200 ms | 3-8 | Reference only (slow) |

**Thermal:**
- Nominal → Fair over 5 minutes (normal)
- Should not reach Serious for 3B models
- If Serious: Let device cool, reduce ambient temp

**Memory:**
- 3B Q4_K_M: ~3.0-3.5 GB peak RAM
- 7B Q4_K_M: ~5.5-6.5 GB peak RAM (may OOM on 8GB device if other apps running)

---

## Next Steps

After deploying and running your first test:

1. **Run Sanity Test**
   - Import a 3B Q4_K_M model
   - Select Metal-4 Tensor backend
   - Run Sanity test (~60 seconds)
   - Verify app completes successfully

2. **Run A/B Comparison**
   - After Sanity test completes, tap "Compare with Legacy Metal"
   - Verify token match percentage is >99%

3. **Run Full Test**
   - Switch to Full Run type
   - Run on Metal-4 Tensor
   - Monitor thermals over 10 minutes
   - Export results

4. **Post to Upstream**
   - Export results (gets 3 files)
   - Go to [PR #16634](https://github.com/ggml-org/llama.cpp/pull/16634)
   - Add comment using `github-template.md` content
   - Attach `run.json` and `report.md`

---

## Support

**For App Issues:**
- Check this README's Troubleshooting section
- Review Xcode console logs
- File issue in repository

**For llama.cpp Issues:**
- Post in PR #16634 comments
- Include device specs, iOS version, full logs

**For Metal 4 / iOS 26 Issues:**
- Apple Developer Forums: [developer.apple.com/forums](https://developer.apple.com/forums/tags/metal)
- Feedback Assistant if suspected iOS bug

---

## Version History

**0.1.0** (2025-11-07)
- Initial release
- Stub llama.cpp implementation
- Full UI and export pipeline
- Metal 4 capability detection
- A/B comparison workflow
- Ready for llama.cpp integration

---

**Questions?** See the main [TESTING_GUIDE.md](../TESTING_GUIDE.md) for comprehensive usage documentation.

**Good luck with your testing! 🚀**
