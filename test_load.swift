import AppKit
import ScreenSaver

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: swift test_load.swift <bundle.saver>\n".utf8))
    exit(2)
}
let path = CommandLine.arguments[1]

guard let bundle = Bundle(path: path) else {
    print("FAIL: cannot open bundle at \(path)"); exit(1)
}
print("OK : opened bundle")

guard bundle.load() else {
    print("FAIL: bundle.load() returned false"); exit(1)
}
print("OK : bundle loaded")

guard let cls = bundle.principalClass else {
    print("FAIL: no principalClass"); exit(1)
}
print("OK : principalClass = \(cls)")

guard let svType = cls as? ScreenSaverView.Type else {
    print("FAIL: principalClass is not a ScreenSaverView subclass"); exit(1)
}

guard let view = svType.init(frame: NSRect(x: 0, y: 0, width: 1024, height: 768), isPreview: false) else {
    print("FAIL: init?(frame:isPreview:) returned nil"); exit(1)
}
print("OK : view instantiated: \(type(of: view))")

print("OK : hasConfigureSheet = \(view.hasConfigureSheet)")
_ = view.configureSheet
print("OK : configureSheet accessor returned without crash")

view.startAnimation()
print("OK : startAnimation called; running 3s of frames…")
RunLoop.current.run(until: Date(timeIntervalSinceNow: 3))
view.stopAnimation()
print("OK : stopAnimation completed cleanly")
print("ALL TESTS PASSED")
