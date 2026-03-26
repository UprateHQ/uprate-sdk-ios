import Foundation

struct DeviceMetadata: Encodable, Sendable {
    let model: String
    let osVersion: String
    let appVersion: String?
    let buildNumber: String?
    let locale: String
    let timezone: String
    let totalRamMb: Int
    let freeDiskSpaceMb: Int?

    private struct StableFields: Sendable {
        let model: String
        let osVersion: String
        let appVersion: String?
        let buildNumber: String?
        let totalRamMb: Int
    }

    private static let stable: StableFields = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        let bundle = Bundle.main.infoDictionary

        return StableFields(
            model: machine,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            appVersion: bundle?["CFBundleShortVersionString"] as? String,
            buildNumber: bundle?["CFBundleVersion"] as? String,
            totalRamMb: Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))
        )
    }()

    static func collect() -> DeviceMetadata {
        let freeDisk: Int? = {
            let homeURL = URL(fileURLWithPath: NSHomeDirectory())
            guard let values = try? homeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
                  let available = values.volumeAvailableCapacityForImportantUsage else {
                return nil
            }
            return Int(available / (1024 * 1024))
        }()

        return DeviceMetadata(
            model: stable.model,
            osVersion: stable.osVersion,
            appVersion: stable.appVersion,
            buildNumber: stable.buildNumber,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier,
            totalRamMb: stable.totalRamMb,
            freeDiskSpaceMb: freeDisk
        )
    }
}
