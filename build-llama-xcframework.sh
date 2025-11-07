#!/usr/bin/env bash

set -e  # Exit on error

echo "🚀 Building llama.cpp XCFramework for iOS"
echo "=========================================="

# Check if llama.cpp directory exists
if [ ! -d "llama.cpp" ]; then
    echo "❌ Error: llama.cpp directory not found"
    echo "Run this script from the shaft-metal4-testharness directory"
    exit 1
fi

# Navigate to llama.cpp
cd llama.cpp

echo ""
echo "📋 Building XCFramework..."
echo "This will take 5-10 minutes on the first build"
echo ""

# Run the build script
./build-xcframework.sh

echo ""
echo "✅ XCFramework built successfully!"
echo ""
echo "📦 Location: llama.cpp/build-apple/llama.xcframework"
echo ""
echo "📋 Next steps:"
echo "  1. Open MetalTensorHarness/MetalTensorHarness.xcodeproj in Xcode"
echo "  2. Drag llama.cpp/build-apple/llama.xcframework into the project navigator"
echo "  3. Select: Copy items if needed, Create groups, Add to target: MetalTensorHarness"
echo "  4. Build Settings → Search 'Bridging' → Set Objective-C Bridging Header to:"
echo "     MetalTensorHarness/MetalTensorHarness-Bridging-Header.h"
echo "  5. Clean build folder (⌘⇧K) and rebuild (⌘B)"
echo ""
echo "🎉 Ready to test with real llama.cpp!"
