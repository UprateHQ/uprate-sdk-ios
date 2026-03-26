import Testing
import Foundation
@testable import UprateSDK

@Suite("DeviceMetadata")
struct DeviceMetadataTests {

    @Test("collect returns non-empty model identifier")
    func collectModel() {
        let metadata = DeviceMetadata.collect()
        #expect(!metadata.model.isEmpty)
    }

    @Test("collect returns non-empty locale")
    func collectLocale() {
        let metadata = DeviceMetadata.collect()
        #expect(!metadata.locale.isEmpty)
    }

    @Test("collect returns non-empty timezone")
    func collectTimezone() {
        let metadata = DeviceMetadata.collect()
        #expect(!metadata.timezone.isEmpty)
    }

    @Test("collect returns positive totalRamMb")
    func collectRam() {
        let metadata = DeviceMetadata.collect()
        #expect(metadata.totalRamMb > 0)
    }

    @Test("collect returns non-empty osVersion")
    func collectOsVersion() {
        let metadata = DeviceMetadata.collect()
        #expect(!metadata.osVersion.isEmpty)
    }

    @Test("encodes to JSON without error")
    func encodesToJson() throws {
        let metadata = DeviceMetadata.collect()
        let data = try JSONEncoder().encode(metadata)
        #expect(data.count > 0)
    }
}
