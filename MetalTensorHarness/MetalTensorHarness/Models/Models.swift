import Foundation

// MARK: - Backend Type

enum Backend: String, CaseIterable, Identifiable, Codable {
    case metalTensor = "metal-tensor"
    case metalLegacy = "metal-legacy"
    case cpu = "cpu"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .metalTensor: return "Metal-4 Tensor"
        case .metalLegacy: return "Legacy Metal"
        case .cpu: return "CPU"
        }
    }
}

// MARK: - Run Type

enum RunType: String, CaseIterable, Identifiable {
    case sanity
    case full

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sanity: return "Sanity Run (30-60s)"
        case .full: return "Full Run (6-10 min)"
        }
    }

    var targetTokens: Int {
        switch self {
        case .sanity: return 128
        case .full: return 512
        }
    }
}

// MARK: - Model State

enum ModelState: Equatable {
    case idle
    case loading
    case warmup
    case running(progress: Double)
    case completed
    case failed(error: String)
}

// MARK: - Thermal State

enum ThermalState: String, Codable {
    case nominal
    case fair
    case serious
    case critical

    var emoji: String {
        switch self {
        case .nominal: return "🟢"
        case .fair: return "🟡"
        case .serious: return "🟠"
        case .critical: return "🔴"
        }
    }
}

// MARK: - Model Info

struct ModelInfo: Identifiable, Codable {
    let id: UUID
    let filename: String
    let path: String
    let sizeBytes: Int64
    let quantization: String?
    let contextLength: Int?
    let estimatedRAMMB: Int?

    init(filename: String, path: String, sizeBytes: Int64, quantization: String? = nil, contextLength: Int? = nil) {
        self.id = UUID()
        self.filename = filename
        self.path = path
        self.sizeBytes = sizeBytes
        self.quantization = quantization
        self.contextLength = contextLength
        self.estimatedRAMMB = Self.estimateRAM(fileSize: sizeBytes)
    }

    var sizeGB: Double {
        Double(sizeBytes) / 1_000_000_000
    }

    private static func estimateRAM(fileSize: Int64) -> Int {
        // Rough estimate: model size + 30% for KV cache and overhead
        Int(Double(fileSize) * 1.3 / 1_000_000)
    }
}

// MARK: - Benchmark Result

struct BenchmarkResult: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let backend: Backend
    let modelInfo: ModelInfo
    let runType: RunType

    // Performance metrics
    let ttftMs: Double
    let tokensPerSecond: Double
    let totalTokens: Int
    let durationMs: Double

    // System metrics
    let peakMemoryMB: Int
    let thermalStates: [ThermalState]
    let throttlingEvents: Int

    // Correctness (for A/B comparison)
    var comparisonResult: ComparisonResult?

    init(backend: Backend, modelInfo: ModelInfo, runType: RunType, ttftMs: Double, tokensPerSecond: Double, totalTokens: Int, durationMs: Double, peakMemoryMB: Int, thermalStates: [ThermalState], throttlingEvents: Int) {
        self.id = UUID()
        self.timestamp = Date()
        self.backend = backend
        self.modelInfo = modelInfo
        self.runType = runType
        self.ttftMs = ttftMs
        self.tokensPerSecond = tokensPerSecond
        self.totalTokens = totalTokens
        self.durationMs = durationMs
        self.peakMemoryMB = peakMemoryMB
        self.thermalStates = thermalStates
        self.throttlingEvents = throttlingEvents
    }
}

// MARK: - Comparison Result

struct ComparisonResult: Codable {
    let baselineBackend: Backend
    let tokenMatchRatio: Double
    let editDistance: Int
    let notes: String?

    var matchPercentage: Double {
        tokenMatchRatio * 100
    }
}

// MARK: - Run Metadata

struct RunMetadata: Codable {
    let device: String
    let iosVersion: String
    let metalVersion: String
    let metalFamily: String
    let appVersion: String
    let llamaCppCommit: String
    let backend: Backend

    init(device: String, iosVersion: String, metalVersion: String, metalFamily: String, backend: Backend) {
        self.device = device
        self.iosVersion = iosVersion
        self.metalVersion = metalVersion
        self.metalFamily = metalFamily
        self.appVersion = "0.1.0"
        self.llamaCppCommit = "TBD" // Will be populated when llama.cpp is integrated
        self.backend = backend
    }
}

// MARK: - Full Run JSON Schema

struct RunJSON: Codable {
    let meta: RunMetadata
    let model: ModelJSONInfo
    let run: RunConfig
    let metrics: MetricsJSON
    let parity: ComparisonResult?
    let notes: String?

    struct ModelJSONInfo: Codable {
        let path: String
        let sizeBytes: Int64
        let quant: String
        let ctxLen: Int
    }

    struct RunConfig: Codable {
        let promptId: String
        let seed: Int
        let tokensTarget: Int
    }

    struct MetricsJSON: Codable {
        let ttftMs: Double
        let tpS: Double
        let totalTokens: Int
        let timeMs: Double
        let peakMemMb: Int
        let thermalStates: [String]
        let throttledEvents: Int
    }
}
