import Foundation
import IOKit

final class GPUSampler {
    let isAvailable: Bool

    init() {
        self.isAvailable = (Self.readUtilization() != nil)
    }

    /// Returns 0...1 GPU utilization, or nil if unavailable.
    func sample() -> Double? {
        Self.readUtilization()
    }

    private static func readUtilization() -> Double? {
        var iterator: io_iterator_t = 0
        guard let matching = IOServiceMatching("IOAccelerator") else { return nil }
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            var props: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = props?.takeRetainedValue() as? [String: Any],
                  let perf = dict["PerformanceStatistics"] as? [String: Any] else {
                continue
            }
            if let v = perf["Device Utilization %"] as? Int {
                return min(1.0, max(0.0, Double(v) / 100.0))
            }
            if let v = perf["Device Utilization %"] as? Double {
                return min(1.0, max(0.0, v / 100.0))
            }
            if let v = perf["GPU Activity(%)"] as? Int {
                return min(1.0, max(0.0, Double(v) / 100.0))
            }
        }
        return nil
    }
}
