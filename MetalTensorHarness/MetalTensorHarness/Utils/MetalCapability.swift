import Metal
import Foundation

class MetalCapability {
    static let shared = MetalCapability()

    private let device: MTLDevice?

    private init() {
        self.device = MTLCreateSystemDefaultDevice()
    }

    // MARK: - Metal 4 Tensor API Detection

    func isMetal4TensorAvailable() -> Bool {
        guard let device = device else { return false }

        // Check for Metal 4 family support
        // Note: MTLGPUFamily.metal4 would be the actual enum case when available
        // For now, we check for apple9 (A17 Pro and later) as a proxy
        if #available(iOS 26.0, *) {
            // Check for the highest available GPU family
            // A17 Pro (M5-class) and later support Metal 4 tensor operations
            return device.supportsFamily(.apple9) || device.supportsFamily(.apple10)
        }

        return false
    }

    func getMetalVersion() -> String {
        if isMetal4TensorAvailable() {
            return "4"
        } else if device?.supportsFamily(.apple8) ?? false {
            return "3"
        } else if device?.supportsFamily(.apple7) ?? false {
            return "3"
        }
        return "2"
    }

    func getMetalFamily() -> String {
        guard let device = device else { return "unknown" }

        if #available(iOS 26.0, *) {
            if device.supportsFamily(.apple10) {
                return "apple10"
            } else if device.supportsFamily(.apple9) {
                return "apple9"
            }
        }

        if device.supportsFamily(.apple8) {
            return "apple8"
        } else if device.supportsFamily(.apple7) {
            return "apple7"
        } else if device.supportsFamily(.apple6) {
            return "apple6"
        }

        return "apple5"
    }

    func getCapabilityInfo() -> String {
        guard let device = device else {
            return "Metal not available"
        }

        let metal4Available = isMetal4TensorAvailable()
        let version = getMetalVersion()
        let family = getMetalFamily()

        var info = "Metal \(version) (\(family))\n"
        info += "Tensor API: \(metal4Available ? "✓ Available" : "✗ Not Available")\n"
        info += "Device: \(device.name)"

        return info
    }

    // MARK: - Backend Availability

    func isBackendAvailable(_ backend: Backend) -> Bool {
        switch backend {
        case .metalTensor:
            return isMetal4TensorAvailable()
        case .metalLegacy:
            return device != nil
        case .cpu:
            return true
        }
    }

    func getRecommendedBackend() -> Backend {
        if isMetal4TensorAvailable() {
            return .metalTensor
        } else if device != nil {
            return .metalLegacy
        } else {
            return .cpu
        }
    }
}
