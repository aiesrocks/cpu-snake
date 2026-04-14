import Cocoa
import ScreenSaver

final class Preferences {
    static let moduleName = "com.noppadon.CPUSnake"

    private let defaults: UserDefaults

    init() {
        let d: UserDefaults = ScreenSaverDefaults(forModuleWithName: Self.moduleName)
            ?? UserDefaults(suiteName: Self.moduleName)
            ?? .standard
        self.defaults = d
        d.register(defaults: [
            "cellSize": 12.0,
            "maxLength": 40,
            "stepInterval": 1.0,
            "showGPU": true,
            "cpuColor": Self.archive(NSColor.systemRed),
            "gpuColor": Self.archive(NSColor.systemBlue),
            "backgroundColor": Self.archive(NSColor.black),
        ])
    }

    var cellSize: CGFloat {
        get { CGFloat(defaults.double(forKey: "cellSize")) }
        set { defaults.set(Double(newValue), forKey: "cellSize"); defaults.synchronize() }
    }
    var maxLength: Int {
        get { defaults.integer(forKey: "maxLength") }
        set { defaults.set(newValue, forKey: "maxLength"); defaults.synchronize() }
    }
    var stepInterval: TimeInterval {
        get { defaults.double(forKey: "stepInterval") }
        set { defaults.set(newValue, forKey: "stepInterval"); defaults.synchronize() }
    }
    var showGPU: Bool {
        get { defaults.bool(forKey: "showGPU") }
        set { defaults.set(newValue, forKey: "showGPU"); defaults.synchronize() }
    }
    var cpuColor: NSColor {
        get { Self.unarchive(defaults.data(forKey: "cpuColor")) ?? .systemRed }
        set { defaults.set(Self.archive(newValue), forKey: "cpuColor"); defaults.synchronize() }
    }
    var gpuColor: NSColor {
        get { Self.unarchive(defaults.data(forKey: "gpuColor")) ?? .systemBlue }
        set { defaults.set(Self.archive(newValue), forKey: "gpuColor"); defaults.synchronize() }
    }
    var backgroundColor: NSColor {
        get { Self.unarchive(defaults.data(forKey: "backgroundColor")) ?? .black }
        set { defaults.set(Self.archive(newValue), forKey: "backgroundColor"); defaults.synchronize() }
    }

    private static func archive(_ color: NSColor) -> Data {
        (try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)) ?? Data()
    }
    private static func unarchive(_ data: Data?) -> NSColor? {
        guard let data, !data.isEmpty else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
    }
}
