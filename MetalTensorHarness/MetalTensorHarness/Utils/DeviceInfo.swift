import UIKit
import Foundation

class DeviceInfo {
    static let shared = DeviceInfo()

    private init() {}

    // MARK: - Device Information

    func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        // Map identifiers to friendly names
        switch identifier {
        case "iPhone17,1": return "iPhone 17 Pro Max"
        case "iPhone17,2": return "iPhone 17 Pro"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        default: return identifier
        }
    }

    func getIOSVersion() -> String {
        return UIDevice.current.systemVersion
    }

    func getDeviceID() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    // MARK: - Current Thermal State

    func getCurrentThermalState() -> ThermalState {
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:
            return .nominal
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        @unknown default:
            return .nominal
        }
    }

    // MARK: - Memory Information

    func getAvailableMemoryMB() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Int(info.resident_size) / 1024 / 1024
        }
        return 0
    }

    func getTotalMemoryMB() -> Int {
        return Int(ProcessInfo.processInfo.physicalMemory / 1024 / 1024)
    }

    // MARK: - Battery & Performance

    func isPluggedIn() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let state = UIDevice.current.batteryState
        return state == .charging || state == .full
    }

    func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    // MARK: - Summary

    func getSystemSummary() -> String {
        """
        Device: \(getDeviceModel())
        iOS: \(getIOSVersion())
        Memory: \(getTotalMemoryMB()) MB total
        Thermal: \(getCurrentThermalState().rawValue)
        Battery: \(Int(getBatteryLevel() * 100))%\(isPluggedIn() ? " (charging)" : "")
        """
    }
}
