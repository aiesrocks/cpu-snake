import Darwin
import Foundation

// MARK: - ANSI

enum ANSI {
    static let hideCursor      = "\u{1b}[?25l"
    static let showCursor      = "\u{1b}[?25h"
    static let enterAltScreen  = "\u{1b}[?1049h"
    static let exitAltScreen   = "\u{1b}[?1049l"
    static let clearScreen     = "\u{1b}[2J"
    static let home            = "\u{1b}[H"
    static let reset           = "\u{1b}[0m"
    static func moveTo(_ row: Int, _ col: Int) -> String { "\u{1b}[\(row);\(col)H" }
    static func fg(_ r: Int, _ g: Int, _ b: Int) -> String { "\u{1b}[38;2;\(r);\(g);\(b)m" }
    static func bg(_ r: Int, _ g: Int, _ b: Int) -> String { "\u{1b}[48;2;\(r);\(g);\(b)m" }
}

// MARK: - Color

struct RGB: Equatable {
    var r: Int, g: Int, b: Int
    static let black = RGB(r: 0, g: 0, b: 0)
    static let cpuHead = RGB(r: 255, g: 69, b: 58)   // systemRed-ish
    static let gpuHead = RGB(r: 10,  g: 132, b: 255) // systemBlue-ish

    func scaled(_ a: Double) -> RGB {
        let clamp = { (v: Int) -> Int in max(0, min(255, v)) }
        return RGB(
            r: clamp(Int((Double(r) * a).rounded())),
            g: clamp(Int((Double(g) * a).rounded())),
            b: clamp(Int((Double(b) * a).rounded()))
        )
    }
}

// MARK: - Terminal size

func terminalSize() -> (cols: Int, rows: Int) {
    var w = winsize()
    if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0, w.ws_col > 0, w.ws_row > 0 {
        return (Int(w.ws_col), Int(w.ws_row))
    }
    return (80, 24)
}

// MARK: - Signal flags

nonisolated(unsafe) var shouldQuit: sig_atomic_t = 0
nonisolated(unsafe) var didResize: sig_atomic_t = 1 // force initial layout

// MARK: - Main

let stepInterval: TimeInterval = {
    if let v = ProcessInfo.processInfo.environment["CPU_SNAKE_INTERVAL"], let d = Double(v), d >= 0.05 {
        return d
    }
    return 1.0
}()

let maxLength = 40

let cpuSampler = CPUSampler()
let gpuSampler = GPUSampler()
let useGPU = gpuSampler.isAvailable

signal(SIGINT)   { _ in shouldQuit = 1 }
signal(SIGTERM)  { _ in shouldQuit = 1 }
signal(SIGWINCH) { _ in didResize = 1 }

fputs(ANSI.enterAltScreen + ANSI.hideCursor + ANSI.clearScreen, stdout)
fflush(stdout)

atexit {
    fputs(ANSI.reset + ANSI.showCursor + ANSI.exitAltScreen, stdout)
    fflush(stdout)
}

var cols = 80
var rows = 24
var gridW = cols
var gridH = rows * 2
var snakes: [Snake] = []

func rebuildSnakes() {
    var built: [Snake] = []
    for i in 0..<cpuSampler.physicalCoreCount {
        let p = GridPoint(
            x: Int.random(in: 0..<max(gridW, 1)),
            y: Int.random(in: 0..<max(gridH, 1))
        )
        built.append(Snake(head: p, kind: .cpu(coreIndex: i)))
    }
    if useGPU {
        let p = GridPoint(
            x: Int.random(in: 0..<max(gridW, 1)),
            y: Int.random(in: 0..<max(gridH, 1))
        )
        built.append(Snake(head: p, kind: .gpu))
    }
    snakes = built
}

func headColor(for kind: SnakeKind) -> RGB {
    switch kind {
    case .cpu: return .cpuHead
    case .gpu: return .gpuHead
    }
}

while shouldQuit == 0 {
    if didResize == 1 {
        (cols, rows) = terminalSize()
        gridW = max(1, cols)
        gridH = max(1, rows * 2)
        if snakes.isEmpty {
            rebuildSnakes()
        } else {
            for snake in snakes {
                for i in snake.cells.indices {
                    snake.cells[i].x = ((snake.cells[i].x % gridW) + gridW) % gridW
                    snake.cells[i].y = ((snake.cells[i].y % gridH) + gridH) % gridH
                }
            }
        }
        didResize = 0
        fputs(ANSI.clearScreen, stdout)
    }

    let cpuUtil = cpuSampler.sample()
    let gpuUtil = gpuSampler.sample()
    let grid = GridSize(width: gridW, height: gridH)
    for snake in snakes {
        switch snake.kind {
        case .cpu(let idx):
            let u = idx < cpuUtil.count ? cpuUtil[idx] : 0
            snake.targetLength = max(1, Int((u * Double(maxLength)).rounded()))
        case .gpu:
            let u = gpuUtil ?? 0
            snake.targetLength = max(1, Int((u * Double(maxLength)).rounded()))
        }
        snake.step(in: grid)
    }

    // Build flat color buffer
    var cellColor = [RGB?](repeating: nil, count: gridW * gridH)
    for snake in snakes {
        let base = headColor(for: snake.kind)
        let n = max(snake.cells.count, 1)
        for (i, p) in snake.cells.enumerated() {
            let alpha = i == 0 ? 1.0 : max(0.18, 1.0 - (Double(i) / Double(n)) * 0.85)
            let idx = p.y * gridW + p.x
            if idx >= 0 && idx < cellColor.count {
                cellColor[idx] = base.scaled(alpha)
            }
        }
    }

    // Render: each terminal cell carries two stacked grid cells via "▀"
    var out = ANSI.home
    var prevFg: RGB? = nil
    var prevBg: RGB? = nil
    for r in 0..<rows {
        out += ANSI.moveTo(r + 1, 1)
        prevFg = nil
        prevBg = nil
        for c in 0..<cols {
            let topIdx = (2 * r) * gridW + c
            let botIdx = (2 * r + 1) * gridW + c
            let top = (topIdx < cellColor.count) ? cellColor[topIdx] : nil
            let bot = (botIdx < cellColor.count) ? cellColor[botIdx] : nil
            let fgC = top ?? .black
            let bgC = bot ?? .black
            if prevFg != fgC {
                out += ANSI.fg(fgC.r, fgC.g, fgC.b)
                prevFg = fgC
            }
            if prevBg != bgC {
                out += ANSI.bg(bgC.r, bgC.g, bgC.b)
                prevBg = bgC
            }
            out += "▀"
        }
    }
    out += ANSI.reset
    fputs(out, stdout)
    fflush(stdout)

    Thread.sleep(forTimeInterval: stepInterval)
}
