import Foundation
import Combine

class MetricsCollector: ObservableObject {
    @Published var currentTokensPerSecond: Double = 0
    @Published var currentThermalState: ThermalState = .nominal
    @Published var currentMemoryMB: Int = 0
    @Published var tokensGenerated: Int = 0

    private var startTime: Date?
    private var firstTokenTime: Date?
    private var thermalStateHistory: [ThermalState] = []
    private var peakMemoryMB: Int = 0
    private var throttlingEventCount: Int = 0
    private var lastThermalState: ThermalState = .nominal

    private var samplingTimer: Timer?

    // MARK: - Start/Stop Collection

    func startCollection() {
        startTime = Date()
        firstTokenTime = nil
        thermalStateHistory = []
        peakMemoryMB = 0
        throttlingEventCount = 0
        tokensGenerated = 0
        currentTokensPerSecond = 0

        // Sample system metrics every second
        samplingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.sampleSystemMetrics()
        }
    }

    func stopCollection() {
        samplingTimer?.invalidate()
        samplingTimer = nil
    }

    // MARK: - Token Tracking

    func recordFirstToken() {
        if firstTokenTime == nil {
            firstTokenTime = Date()
        }
    }

    func recordToken() {
        tokensGenerated += 1

        // Update tokens per second
        if let start = firstTokenTime {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed > 0 {
                currentTokensPerSecond = Double(tokensGenerated) / elapsed
            }
        }
    }

    // MARK: - System Metrics Sampling

    private func sampleSystemMetrics() {
        // Thermal state
        let thermal = DeviceInfo.shared.getCurrentThermalState()
        currentThermalState = thermal
        thermalStateHistory.append(thermal)

        // Detect throttling (transition to worse thermal state)
        if thermal.rawValue > lastThermalState.rawValue {
            throttlingEventCount += 1
        }
        lastThermalState = thermal

        // Memory
        let memory = DeviceInfo.shared.getAvailableMemoryMB()
        currentMemoryMB = memory
        peakMemoryMB = max(peakMemoryMB, memory)
    }

    // MARK: - Calculate Final Metrics

    func calculateTTFT() -> Double {
        guard let start = startTime, let firstToken = firstTokenTime else {
            return 0
        }
        return firstToken.timeIntervalSince(start) * 1000 // Convert to ms
    }

    func calculateAverageTokensPerSecond() -> Double {
        guard let start = firstTokenTime else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        return elapsed > 0 ? Double(tokensGenerated) / elapsed : 0
    }

    func getTotalDurationMs() -> Double {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start) * 1000
    }

    func getPeakMemoryMB() -> Int {
        return peakMemoryMB
    }

    func getThermalStateHistory() -> [ThermalState] {
        return thermalStateHistory
    }

    func getThrottlingEventCount() -> Int {
        return throttlingEventCount
    }

    // MARK: - Summary

    func getSummary() -> String {
        let ttft = calculateTTFT()
        let tps = calculateAverageTokensPerSecond()
        let duration = getTotalDurationMs()

        return """
        TTFT: \(String(format: "%.0f", ttft)) ms
        Tokens/sec: \(String(format: "%.1f", tps))
        Total tokens: \(tokensGenerated)
        Duration: \(String(format: "%.1f", duration / 1000)) s
        Peak memory: \(peakMemoryMB) MB
        Thermal events: \(throttlingEventCount)
        """
    }
}
