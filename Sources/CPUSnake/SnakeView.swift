import Cocoa
import ScreenSaver

@objc(SnakeView)
public final class SnakeView: ScreenSaverView {
    private let preferences = Preferences()
    private let cpuSampler = CPUSampler()
    private let gpuSampler = GPUSampler()
    private var snakes: [Snake] = []
    private var configureSheetController: ConfigureSheet?

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = preferences.stepInterval
        wantsLayer = true
        rebuildSnakes()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = preferences.stepInterval
        wantsLayer = true
        rebuildSnakes()
    }

    private func currentGrid() -> GridSize {
        let cell = max(1, preferences.cellSize)
        return GridSize(
            width: max(1, Int(bounds.width / cell)),
            height: max(1, Int(bounds.height / cell))
        )
    }

    private func rebuildSnakes() {
        let grid = currentGrid()
        let cpuColor = preferences.cpuColor
        let gpuColor = preferences.gpuColor
        var built: [Snake] = []
        for i in 0..<cpuSampler.physicalCoreCount {
            let p = GridPoint(
                x: Int.random(in: 0..<max(grid.width, 1)),
                y: Int.random(in: 0..<max(grid.height, 1))
            )
            built.append(Snake(head: p, color: cpuColor, kind: .cpu(coreIndex: i)))
        }
        if preferences.showGPU && gpuSampler.isAvailable {
            let p = GridPoint(
                x: Int.random(in: 0..<max(grid.width, 1)),
                y: Int.random(in: 0..<max(grid.height, 1))
            )
            built.append(Snake(head: p, color: gpuColor, kind: .gpu))
        }
        snakes = built
    }

    public override func animateOneFrame() {
        let grid = currentGrid()
        let cpuUtil = cpuSampler.sample()
        let gpuUtil = gpuSampler.sample()
        let maxLen = max(1, preferences.maxLength)
        for i in snakes.indices {
            switch snakes[i].kind {
            case .cpu(let idx):
                let u = idx < cpuUtil.count ? cpuUtil[idx] : 0
                snakes[i].targetLength = max(1, Int((u * Double(maxLen)).rounded()))
            case .gpu:
                let u = gpuUtil ?? 0
                snakes[i].targetLength = max(1, Int((u * Double(maxLen)).rounded()))
            }
            snakes[i].step(in: grid)
        }
        setNeedsDisplay(bounds)
    }

    public override func draw(_ rect: NSRect) {
        preferences.backgroundColor.setFill()
        bounds.fill()
        let cell = max(1, preferences.cellSize)
        for snake in snakes {
            snake.draw(cell: cell)
        }
    }

    public override var hasConfigureSheet: Bool { true }

    public override var configureSheet: NSWindow? {
        if configureSheetController == nil {
            configureSheetController = ConfigureSheet(preferences: preferences) { [weak self] in
                self?.applyPreferences()
            }
        }
        return configureSheetController?.window
    }

    private func applyPreferences() {
        animationTimeInterval = preferences.stepInterval
        rebuildSnakes()
        setNeedsDisplay(bounds)
    }
}
