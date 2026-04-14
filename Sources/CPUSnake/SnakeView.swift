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
        var built: [Snake] = []
        for i in 0..<cpuSampler.physicalCoreCount {
            let p = GridPoint(
                x: Int.random(in: 0..<max(grid.width, 1)),
                y: Int.random(in: 0..<max(grid.height, 1))
            )
            built.append(Snake(head: p, kind: .cpu(coreIndex: i)))
        }
        if preferences.showGPU && gpuSampler.isAvailable {
            let p = GridPoint(
                x: Int.random(in: 0..<max(grid.width, 1)),
                y: Int.random(in: 0..<max(grid.height, 1))
            )
            built.append(Snake(head: p, kind: .gpu))
        }
        snakes = built
    }

    public override func animateOneFrame() {
        let grid = currentGrid()
        let cpuUtil = cpuSampler.sample()
        let gpuUtil = gpuSampler.sample()
        let maxLen = max(1, preferences.maxLength)
        for snake in snakes {
            switch snake.kind {
            case .cpu(let idx):
                let u = idx < cpuUtil.count ? cpuUtil[idx] : 0
                snake.targetLength = max(1, Int((u * Double(maxLen)).rounded()))
            case .gpu:
                let u = gpuUtil ?? 0
                snake.targetLength = max(1, Int((u * Double(maxLen)).rounded()))
            }
            snake.step(in: grid)
        }
        setNeedsDisplay(bounds)
    }

    public override func draw(_ rect: NSRect) {
        preferences.backgroundColor.setFill()
        bounds.fill()
        let cell = max(1, preferences.cellSize)
        let cpuColor = preferences.cpuColor
        let gpuColor = preferences.gpuColor
        for snake in snakes {
            let base: NSColor = {
                switch snake.kind {
                case .cpu: return cpuColor
                case .gpu: return gpuColor
                }
            }()
            drawSnake(snake, baseColor: base, cell: cell)
        }
    }

    private func drawSnake(_ snake: Snake, baseColor: NSColor, cell: CGFloat) {
        let n = max(snake.cells.count, 1)
        for (i, p) in snake.cells.enumerated() {
            let alpha: CGFloat = i == 0 ? 1.0 : max(0.18, 1.0 - (CGFloat(i) / CGFloat(n)) * 0.85)
            baseColor.withAlphaComponent(alpha).setFill()
            let r = NSRect(
                x: CGFloat(p.x) * cell,
                y: CGFloat(p.y) * cell,
                width: max(1, cell - 1),
                height: max(1, cell - 1)
            )
            r.fill()
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
