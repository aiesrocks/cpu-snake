import AppKit
import ScreenSaver

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: swift preview.swift <bundle.saver>\n".utf8))
    exit(2)
}
let path = CommandLine.arguments[1]

guard let bundle = Bundle(path: path), bundle.load(),
      let svType = bundle.principalClass as? ScreenSaverView.Type else {
    FileHandle.standardError.write(Data("failed to load bundle\n".utf8))
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let frame = NSRect(x: 0, y: 0, width: 900, height: 600)
let window = NSWindow(
    contentRect: frame,
    styleMask: [.titled, .closable, .resizable, .miniaturizable],
    backing: .buffered,
    defer: false
)
window.title = "CPUSnake Preview"
window.center()

guard let view = svType.init(frame: frame, isPreview: false) else {
    FileHandle.standardError.write(Data("init returned nil\n".utf8))
    exit(1)
}
view.autoresizingMask = [.width, .height]
window.contentView = view
window.makeKeyAndOrderFront(nil)
view.startAnimation()

app.activate(ignoringOtherApps: true)
app.run()
