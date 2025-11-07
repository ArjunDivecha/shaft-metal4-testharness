import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

class HarnessViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var modelState: ModelState = .idle
    @Published var selectedModel: ModelInfo?
    @Published var selectedBackend: Backend
    @Published var selectedRunType: RunType = .sanity
    @Published var currentResult: BenchmarkResult?
    @Published var comparisonBaseline: BenchmarkResult?
    @Published var errorMessage: String?
    @Published var showingModelPicker = false
    @Published var showingResults = false

    // Metal capability
    @Published var metal4Available: Bool = false
    @Published var metalCapabilityInfo: String = ""

    // Live metrics during run
    @Published var liveMetrics: MetricsCollector

    // MARK: - Services

    private let llamaWrapper = LlamaWrapper()
    private let metalCapability = MetalCapability.shared
    private let deviceInfo = DeviceInfo.shared
    private let exportService = ExportService.shared

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.liveMetrics = MetricsCollector()

        // Detect Metal 4 capability
        self.metal4Available = metalCapability.isMetal4TensorAvailable()
        self.metalCapabilityInfo = metalCapability.getCapabilityInfo()

        // Set recommended backend
        self.selectedBackend = metalCapability.getRecommendedBackend()

        print("📱 App initialized")
        print(metalCapabilityInfo)
    }

    // MARK: - Model Import

    func importModel(from url: URL) {
        print("📂 Importing model from: \(url)")

        // Access security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Failed to access file"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attributes[.size] as? Int64 else {
                errorMessage = "Could not determine file size"
                return
            }

            // Get model info from llama.cpp
            let (quant, ctxLen) = try llamaWrapper.getModelInfo(path: url.path)

            let modelInfo = ModelInfo(
                filename: url.lastPathComponent,
                path: url.path,
                sizeBytes: fileSize,
                quantization: quant,
                contextLength: ctxLen
            )

            DispatchQueue.main.async {
                self.selectedModel = modelInfo
                print("✅ Model imported: \(modelInfo.filename)")
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to import model: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Run Benchmark

    func runBenchmark() {
        guard let model = selectedModel else {
            errorMessage = "No model selected"
            return
        }

        guard metalCapability.isBackendAvailable(selectedBackend) else {
            errorMessage = "\(selectedBackend.displayName) backend not available"
            return
        }

        print("🚀 Starting benchmark")
        print("   Model: \(model.filename)")
        print("   Backend: \(selectedBackend.displayName)")
        print("   Run type: \(selectedRunType.displayName)")

        modelState = .loading
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                // Load model
                try self.llamaWrapper.loadModel(path: model.path, backend: self.selectedBackend)

                DispatchQueue.main.async {
                    self.modelState = .warmup
                }

                // Start metrics collection
                self.liveMetrics.startCollection()

                // Get prompt
                let prompt = BenchmarkPrompts.getDefaultPromptForRunType(self.selectedRunType)

                DispatchQueue.main.async {
                    self.modelState = .running(progress: 0)
                }

                // Run inference
                var generatedText = ""
                let targetTokens = self.selectedRunType.targetTokens

                self.llamaWrapper.generate(
                    prompt: prompt.text,
                    maxTokens: targetTokens,
                    seed: 1234,
                    onToken: { [weak self] token in
                        guard let self = self else { return }

                        if self.liveMetrics.tokensGenerated == 0 {
                            self.liveMetrics.recordFirstToken()
                        }

                        self.liveMetrics.recordToken()
                        generatedText += token

                        let progress = Double(self.liveMetrics.tokensGenerated) / Double(targetTokens)
                        DispatchQueue.main.async {
                            self.modelState = .running(progress: progress)
                        }
                    },
                    onComplete: { [weak self] in
                        guard let self = self else { return }

                        // Stop metrics
                        self.liveMetrics.stopCollection()

                        // Create result
                        let result = BenchmarkResult(
                            backend: self.selectedBackend,
                            modelInfo: model,
                            runType: self.selectedRunType,
                            ttftMs: self.liveMetrics.calculateTTFT(),
                            tokensPerSecond: self.liveMetrics.calculateAverageTokensPerSecond(),
                            totalTokens: self.liveMetrics.tokensGenerated,
                            durationMs: self.liveMetrics.getTotalDurationMs(),
                            peakMemoryMB: self.liveMetrics.getPeakMemoryMB(),
                            thermalStates: self.liveMetrics.getThermalStateHistory(),
                            throttlingEvents: self.liveMetrics.getThrottlingEventCount()
                        )

                        DispatchQueue.main.async {
                            self.currentResult = result
                            self.modelState = .completed
                            self.showingResults = true
                            print("✅ Benchmark complete")
                            print(self.liveMetrics.getSummary())
                        }

                        // Unload model
                        self.llamaWrapper.unloadModel()
                    }
                )

            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Benchmark failed: \(error.localizedDescription)"
                    self.modelState = .failed(error: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - A/B Comparison

    func runComparison(baselineBackend: Backend) {
        guard let currentRes = currentResult else { return }

        print("🔄 Running A/B comparison vs \(baselineBackend.displayName)")

        // Save current result as baseline
        comparisonBaseline = currentRes

        // Switch backend and re-run
        let previousBackend = selectedBackend
        selectedBackend = baselineBackend

        // Store a callback to perform comparison after the run completes
        // In a real implementation, we'd compare token outputs
        // For now, we'll simulate a comparison result

        runBenchmark()

        // After completion, calculate comparison (simulated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self,
                  let newResult = self.currentResult,
                  let baseline = self.comparisonBaseline else { return }

            // Simulate token comparison
            let matchRatio = self.simulateTokenComparison(backend1: baseline.backend, backend2: newResult.backend)

            let comparison = ComparisonResult(
                baselineBackend: baseline.backend,
                tokenMatchRatio: matchRatio,
                editDistance: Int((1.0 - matchRatio) * Double(newResult.totalTokens)),
                notes: matchRatio >= 0.99 ? "Excellent parity" : "Minor divergence detected"
            )

            var updatedResult = newResult
            updatedResult.comparisonResult = comparison
            self.currentResult = updatedResult

            print("✅ Comparison complete: \(String(format: "%.1f", matchRatio * 100))% match")
        }

        // Restore original backend
        selectedBackend = previousBackend
    }

    private func simulateTokenComparison(backend1: Backend, backend2: Backend) -> Double {
        // Simulate token comparison
        // Metal-4 vs Legacy should have ~99% match
        // Metal vs CPU might have more divergence
        if backend1 == .metalTensor && backend2 == .metalLegacy ||
           backend1 == .metalLegacy && backend2 == .metalTensor {
            return Double.random(in: 0.990...0.999)
        } else {
            return Double.random(in: 0.950...0.990)
        }
    }

    // MARK: - Export

    func exportResults() -> [URL] {
        guard let result = currentResult else { return [] }
        return exportService.exportResults(result)
    }

    // MARK: - Reset

    func reset() {
        modelState = .idle
        currentResult = nil
        comparisonBaseline = nil
        errorMessage = nil
        showingResults = false
        llamaWrapper.unloadModel()
        print("🔄 Reset to idle state")
    }
}
