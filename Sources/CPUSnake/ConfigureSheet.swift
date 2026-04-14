import Cocoa

final class ConfigureSheet: NSObject {
    let window: NSWindow
    private let preferences: Preferences
    private let onApply: () -> Void

    private let cellSizeSlider = NSSlider()
    private let cellSizeLabel = NSTextField(labelWithString: "")
    private let maxLengthSlider = NSSlider()
    private let maxLengthLabel = NSTextField(labelWithString: "")
    private let intervalSlider = NSSlider()
    private let intervalLabel = NSTextField(labelWithString: "")
    private let showGPUCheckbox = NSButton(checkboxWithTitle: "Show GPU snake", target: nil, action: nil)
    private let cpuColorWell = NSColorWell()
    private let gpuColorWell = NSColorWell()
    private let bgColorWell = NSColorWell()

    init(preferences: Preferences, onApply: @escaping () -> Void) {
        self.preferences = preferences
        self.onApply = onApply
        self.window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = "CPU Snake"
        configureControls()
        layout()
    }

    private func configureControls() {
        cellSizeSlider.minValue = 6
        cellSizeSlider.maxValue = 24
        cellSizeSlider.doubleValue = Double(preferences.cellSize)
        cellSizeSlider.target = self
        cellSizeSlider.action = #selector(updateLabels)

        maxLengthSlider.minValue = 5
        maxLengthSlider.maxValue = 80
        maxLengthSlider.doubleValue = Double(preferences.maxLength)
        maxLengthSlider.target = self
        maxLengthSlider.action = #selector(updateLabels)

        intervalSlider.minValue = 0.25
        intervalSlider.maxValue = 3.0
        intervalSlider.doubleValue = preferences.stepInterval
        intervalSlider.target = self
        intervalSlider.action = #selector(updateLabels)

        showGPUCheckbox.state = preferences.showGPU ? .on : .off

        cpuColorWell.color = preferences.cpuColor
        gpuColorWell.color = preferences.gpuColor
        bgColorWell.color = preferences.backgroundColor

        for well in [cpuColorWell, gpuColorWell, bgColorWell] {
            well.translatesAutoresizingMaskIntoConstraints = false
            well.widthAnchor.constraint(equalToConstant: 60).isActive = true
            well.heightAnchor.constraint(equalToConstant: 24).isActive = true
        }

        updateLabels()
    }

    @objc private func updateLabels() {
        cellSizeLabel.stringValue = String(format: "Cell size: %.0f pt", cellSizeSlider.doubleValue)
        maxLengthLabel.stringValue = String(format: "Max length: %.0f cells", maxLengthSlider.doubleValue)
        intervalLabel.stringValue = String(format: "Step interval: %.2f s", intervalSlider.doubleValue)
    }

    private func layout() {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false

        func row(_ label: String, _ control: NSView) -> NSStackView {
            let l = NSTextField(labelWithString: label)
            l.translatesAutoresizingMaskIntoConstraints = false
            l.widthAnchor.constraint(equalToConstant: 110).isActive = true
            let s = NSStackView(views: [l, control])
            s.orientation = .horizontal
            s.spacing = 10
            s.alignment = .centerY
            return s
        }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(cellSizeLabel)
        stack.addArrangedSubview(cellSizeSlider)
        stack.addArrangedSubview(maxLengthLabel)
        stack.addArrangedSubview(maxLengthSlider)
        stack.addArrangedSubview(intervalLabel)
        stack.addArrangedSubview(intervalSlider)
        stack.addArrangedSubview(showGPUCheckbox)
        stack.addArrangedSubview(row("CPU color:", cpuColorWell))
        stack.addArrangedSubview(row("GPU color:", gpuColorWell))
        stack.addArrangedSubview(row("Background:", bgColorWell))

        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelBtn.bezelStyle = .rounded
        let okBtn = NSButton(title: "OK", target: self, action: #selector(ok))
        okBtn.bezelStyle = .rounded
        okBtn.keyEquivalent = "\r"
        let buttons = NSStackView(views: [cancelBtn, okBtn])
        buttons.orientation = .horizontal
        buttons.spacing = 10

        let main = NSStackView(views: [stack, buttons])
        main.orientation = .vertical
        main.alignment = .trailing
        main.spacing = 18
        main.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        main.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(main)
        NSLayoutConstraint.activate([
            main.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            main.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            main.topAnchor.constraint(equalTo: content.topAnchor),
            main.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            cellSizeSlider.widthAnchor.constraint(equalToConstant: 380),
            maxLengthSlider.widthAnchor.constraint(equalToConstant: 380),
            intervalSlider.widthAnchor.constraint(equalToConstant: 380),
        ])
        window.contentView = content
    }

    @objc private func ok() {
        preferences.cellSize = CGFloat(cellSizeSlider.doubleValue)
        preferences.maxLength = Int(maxLengthSlider.doubleValue)
        preferences.stepInterval = intervalSlider.doubleValue
        preferences.showGPU = (showGPUCheckbox.state == .on)
        preferences.cpuColor = cpuColorWell.color
        preferences.gpuColor = gpuColorWell.color
        preferences.backgroundColor = bgColorWell.color
        onApply()
        dismiss()
    }

    @objc private func cancel() {
        dismiss()
    }

    private func dismiss() {
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            window.orderOut(nil)
        }
    }
}
