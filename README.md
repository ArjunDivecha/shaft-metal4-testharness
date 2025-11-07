# Metal-4 Tensor API Test Harness for iOS

**Version:** 0.1.0
**Target Device:** iPhone 17 Pro Max
**Target OS:** iOS 26.0.1
**Purpose:** Test and validate llama.cpp's Metal-4 Tensor API implementation

[![iOS](https://img.shields.io/badge/iOS-26.0+-blue.svg)](https://developer.apple.com/ios/)
[![Metal](https://img.shields.io/badge/Metal-4-orange.svg)](https://developer.apple.com/metal/)
[![Swift](https://img.shields.io/badge/Swift-5.0-red.svg)](https://swift.org/)

---

## Overview

This iOS test harness app exercises [llama.cpp](https://github.com/ggml-org/llama.cpp) using the **Metal-4 Tensor API** path, validating accuracy parity vs. baseline kernels and measuring throughput, latency, memory, and thermals on iPhone 17 Pro Max.

The app provides actionable performance data for the upstream Metal-4 work in [llama.cpp PR #16634](https://github.com/ggml-org/llama.cpp/pull/16634).

### iOS 26 & Metal 4 Context

Apple released iOS 26 (September 2025) with **Metal 4**, introducing first-class machine learning support:

- **Native tensor support** in both the Metal API and shading language
- **ML command encoder** for executing large-scale neural networks directly in Metal apps
- **40% GPU efficiency gains** for ML-integrated rendering effects
- **Unified command encoder** with lower overhead and scalable resource management

This test harness is perfectly positioned to validate llama.cpp's Metal-4 Tensor API implementation on production Metal 4 primitives.

---

## Features

### ✅ Implemented

- **Metal 4 Capability Detection** - Auto-detects Metal-4 Tensor API availability
- **Multi-Backend Support** - Metal-4 Tensor / Legacy Metal / CPU
- **Comprehensive Metrics** - TTFT, tokens/sec, memory, thermals
- **A/B Comparison** - Compare Metal-4 vs Legacy Metal with token-level parity checks
- **Export System** - Generates `report.md`, `run.json`, and GitHub template
- **Benchmark Prompts** - Curated set (5 short, 2 medium, 1 long)
- **SwiftUI Interface** - Clean, single-screen workflow
- **Document Picker** - Import GGUF models via Files app
- **Live Monitoring** - Real-time TP/s, thermal state, memory tracking
- **Thermal Safety** - Tracks throttling events and thermal state transitions

### ⚠️ Integration Required

- **llama.cpp XCFramework** - Currently uses stub implementation (see Integration Guide)
- Real model loading and inference requires llama.cpp integration

---

## Quick Start

### 1. Open in Xcode

```bash
cd MetalTensorHarness
open MetalTensorHarness.xcodeproj
```

**Requirements:**
- Xcode 17+ (supports iOS 26 SDK)
- iPhone 17 Pro Max with iOS 26.0.1
- macOS for building

### 2. Configure Signing

1. Select project → Target → Signing & Capabilities
2. Choose your Apple ID as Team (free account works)
3. Xcode auto-generates bundle ID

### 3. Connect iPhone & Run

1. Connect iPhone 17 Pro Max via USB-C
2. Select device in Xcode toolbar
3. Press **⌘R** to build and run
4. Trust developer cert on iPhone if prompted
5. App launches on device

**Deployment time: ~5 minutes from git clone to running app**

See [MetalTensorHarness/README.md](MetalTensorHarness/README.md) for detailed deployment guide.

---

## Usage

### Basic Workflow

1. **Launch app** → Check Metal-4 capability banner
2. **Import model** → Tap "Import Model", select `.gguf` file
3. **Select backend** → Metal-4 Tensor (default) / Legacy / CPU
4. **Choose run type** → Sanity (60s) or Full (10min)
5. **Tap "Run"** → Watch live metrics
6. **View results** → TTFT, TP/s, memory, thermals
7. **Export** → Share results via AirDrop/Mail

### A/B Comparison

After completing a run:
1. Tap "Compare with Legacy Metal" in results screen
2. App re-runs same test with different backend
3. Shows token match percentage and performance delta

### Export Format

Three files generated:
- `report.md` - Human-readable summary
- `run.json` - Machine-readable metrics (PRD schema-compliant)
- `github-template.md` - Pre-filled for PR #16634

---

## Documentation

| Document | Description |
|----------|-------------|
| [prd.md](prd.md) | Product Requirements Document (comprehensive spec) |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | End-to-end testing guide (10 sections) |
| [MetalTensorHarness/README.md](MetalTensorHarness/README.md) | Deployment & troubleshooting |
| [SampleOutputs/](SampleOutputs/) | Example report.md, run.json, github-template.md |

---

## Project Structure

```
shaft-metal4-testharness/
├── README.md                              # This file
├── prd.md                                 # Product requirements
├── TESTING_GUIDE.md                       # Usage guide
├── MetalTensorHarness/                    # Xcode project
│   ├── MetalTensorHarness.xcodeproj/      # Xcode project file
│   ├── MetalTensorHarness/                # Source code
│   │   ├── MetalTensorHarnessApp.swift    # App entry point
│   │   ├── Views/                         # SwiftUI views
│   │   │   ├── ContentView.swift          # Main screen
│   │   │   ├── ResultsView.swift          # Results display
│   │   │   └── ModelPickerView.swift      # Model selection
│   │   ├── ViewModels/                    # Business logic
│   │   │   └── HarnessViewModel.swift     # Main ViewModel
│   │   ├── Models/                        # Data models
│   │   │   └── Models.swift               # Structs/enums
│   │   ├── Services/                      # Core services
│   │   │   ├── LlamaWrapper.swift         # llama.cpp interface
│   │   │   ├── MetricsCollector.swift     # Performance tracking
│   │   │   └── ExportService.swift        # File export
│   │   ├── Utils/                         # Utilities
│   │   │   ├── MetalCapability.swift      # Metal 4 detection
│   │   │   ├── DeviceInfo.swift           # Device info
│   │   │   └── BenchmarkPrompts.swift     # Test prompts
│   │   └── Resources/                     # Assets
│   │       └── Assets.xcassets/
│   └── README.md                          # Deployment guide
└── SampleOutputs/                         # Example exports
    ├── sample-report.md
    ├── sample-run.json
    └── sample-github-template.md
```

---

## llama.cpp Integration

### Current State

The app currently uses a **stub implementation** that simulates llama.cpp for development:

- ✅ Full UI workflow functional
- ✅ Metrics collection with realistic timings
- ✅ Export pipeline generates correct files
- ⚠️ Model loading/inference simulated (requires real llama.cpp)

### Integration Steps

When llama.cpp XCFramework is available:

1. Add `llama.xcframework` to project
2. Create bridging header: `#import <llama/llama.h>`
3. Update build settings (link framework, enable C++ interop)
4. Replace stub methods in `LlamaWrapper.swift`

**Detailed guide:** See `MetalTensorHarness/Services/LlamaWrapper.swift` (400+ lines of integration docs)

**Expected llama.cpp compile flags:**
- `GGML_METAL=ON` - Enable Metal backend
- `GGML_METAL_USE_TENSOR_API=ON` - Enable Metal-4 Tensor path

---

## Performance Expectations

### iPhone 17 Pro Max (iOS 26.0.1)

**3B Model, Q4_K_M quantization, 128 tokens:**

| Backend | TTFT | Tokens/Sec | Speedup |
|---------|------|------------|---------|
| Metal-4 Tensor | 150-300 ms | 25-35 t/s | Baseline |
| Legacy Metal | 200-350 ms | 20-28 t/s | -15% to -20% |
| CPU | 800-1200 ms | 3-8 t/s | -85% (reference only) |

**Thermal Profile:**
- Nominal → Fair over 5-10 minutes (normal)
- Should not throttle for 3B models
- Return to Nominal after 2-3 min idle

**Memory:**
- 3B Q4_K_M: ~3.0-3.5 GB peak
- 7B Q4_K_M: ~5.5-6.5 GB peak (may OOM on 8GB devices)

---

## Sample Outputs

See [SampleOutputs/](SampleOutputs/) directory for examples:

### report.md
```markdown
# Metal-4 Tensor API Test Results

**Device:** iPhone 17 Pro Max (iOS 26.0.1)
**Metal:** Version 4, Family apple9
**Backend:** Metal-4 Tensor API

Performance Metrics:
- TTFT: 245 ms
- TP/s: 28.3
- Correctness vs. Legacy Metal: 99.8% match
```

### run.json
```json
{
  "meta": {
    "device": "iPhone 17 Pro Max",
    "iosVersion": "26.0.1",
    "metalVersion": "4",
    "backend": "metal-tensor"
  },
  "metrics": {
    "ttftMs": 245.0,
    "tpS": 28.3,
    ...
  }
}
```

### github-template.md
Ready-to-paste comment for upstream PR #16634.

---

## Recommended Models

| Model | Size | Quant | Est. RAM | Download |
|-------|------|-------|----------|----------|
| Llama-3.2-3B | 2.0 GB | Q4_K_M | ~3.0 GB | HuggingFace GGUF |
| Phi-3.5-mini | 2.4 GB | Q4_K_M | ~3.4 GB | HuggingFace GGUF |
| Qwen2.5-3B | 2.0 GB | Q4_K_M | ~3.1 GB | HuggingFace GGUF |
| TinyLlama-1.1B | 0.6 GB | Q4_K_M | ~1.2 GB | Testing only |

**Transfer to iPhone:** iCloud Drive, AirDrop, or USB

---

## Contributing

### For Upstream (llama.cpp maintainers)

This harness provides structured, reproducible data for Metal-4 validation:

1. Clone this repo
2. Open in Xcode, deploy to iPhone 17 Pro Max
3. Import your test model
4. Run benchmarks (Sanity + Full)
5. Export results
6. Post to PR #16634 using generated template

### For iOS Developers

Contributions welcome for:
- Additional benchmark prompts
- Enhanced UI/UX
- Model management features
- Batch testing automation
- iPad support

---

## Troubleshooting

### App won't install
- Trust developer cert: Settings → General → VPN & Device Management
- Check iPhone storage (need 500MB+ free)
- Clean build: Xcode → Product → Clean Build Folder

### Metal-4 not detected
- Verify device: iPhone 17 Pro or Pro Max required
- Verify iOS: 26.0+ required (Settings → General → About)

### Model import fails
- Ensure file is `.gguf` format
- Check file isn't corrupted (compare hash with source)
- Try smaller model if memory constrained

**Full troubleshooting guide:** [MetalTensorHarness/README.md](MetalTensorHarness/README.md)

---

## Roadmap

### v0.1.0 (Current)
- ✅ Full app skeleton
- ✅ Stub llama.cpp implementation
- ✅ Export pipeline
- ⚠️ Awaiting llama.cpp XCFramework

### v0.2.0 (Next)
- 🔲 Real llama.cpp integration
- 🔲 First upstream results posted
- 🔲 Model validation on 3B/7B models

### v0.3.0 (Future)
- 🔲 Batch testing mode
- 🔲 Context window sweeps
- 🔲 Historical result comparison
- 🔲 iPad Pro (M4) support

---

## References

- [llama.cpp Repository](https://github.com/ggml-org/llama.cpp)
- [PR #16634: metal: initial Metal4 tensor API support](https://github.com/ggml-org/llama.cpp/pull/16634)
- [Apple: What's New in Metal](https://developer.apple.com/metal/whats-new/)
- [WWDC 2025: Discover Metal 4](https://developer.apple.com/videos/play/wwdc2025/205/)
- [iOS 26 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes)

---

## License

MIT License (respecting llama.cpp's MIT license)

**Model licenses:** Users are responsible for respecting model licenses when importing GGUF files.

---

## Support

**For app issues:**
- Check [MetalTensorHarness/README.md](MetalTensorHarness/README.md) troubleshooting
- Review Xcode console logs
- File issue in this repository

**For llama.cpp issues:**
- Post in [PR #16634](https://github.com/ggml-org/llama.cpp/pull/16634)
- Include device specs, iOS version, and full logs

**For Metal 4 / iOS 26 issues:**
- [Apple Developer Forums (Metal)](https://developer.apple.com/forums/tags/metal)
- Feedback Assistant for suspected iOS bugs

---

## Acknowledgments

Built for the llama.cpp community and Metal-4 validation effort.

Special thanks to:
- llama.cpp maintainers for the Metal-4 work
- Apple for Metal 4's native tensor support
- iPhone 17 Pro Max testers providing early validation

---

**Status:** ✅ Ready for deployment and testing
**Next Step:** Deploy to your iPhone 17 Pro Max and run first benchmark

**Questions?** See the docs listed above or open an issue.

**Happy testing! 🚀**
