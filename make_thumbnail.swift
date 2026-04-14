import AppKit

let width = 480
let height = 360
let cell: CGFloat = 10
let cols = width / Int(cell)
let rows = height / Int(cell)

func randomSnake(length: Int) -> [(Int, Int)] {
    var x = Int.random(in: 4..<cols-4)
    var y = Int.random(in: 4..<rows-4)
    var dx = [-1, 0, 1, 0].randomElement()!
    var dy = dx == 0 ? [-1, 1].randomElement()! : 0
    var path: [(Int, Int)] = [(x, y)]
    for _ in 1..<length {
        let r = Double.random(in: 0..<1)
        if r < 0.5 {
            // continue
        } else if r < 0.75 {
            // turn left
            let (ndx, ndy) = (-dy, dx)
            (dx, dy) = (ndx, ndy)
        } else {
            let (ndx, ndy) = (dy, -dx)
            (dx, dy) = (ndx, ndy)
        }
        x = ((x + dx) % cols + cols) % cols
        y = ((y + dy) % rows + rows) % rows
        path.append((x, y))
    }
    return path
}

func draw(snake: [(Int, Int)], color: NSColor) {
    let n = max(snake.count, 1)
    for (i, p) in snake.enumerated() {
        let alpha: CGFloat = i == 0 ? 1.0 : max(0.18, 1.0 - (CGFloat(i) / CGFloat(n)) * 0.85)
        color.withAlphaComponent(alpha).setFill()
        let rect = NSRect(
            x: CGFloat(p.0) * cell,
            y: CGFloat(p.1) * cell,
            width: cell - 1,
            height: cell - 1
        )
        rect.fill()
    }
}

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

NSColor.black.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

// CPU snakes — varying lengths
let cpuLengths = [22, 14, 8, 30, 18, 6, 12, 25]
for len in cpuLengths {
    draw(snake: randomSnake(length: len), color: .systemRed)
}

// One blue GPU snake
draw(snake: randomSnake(length: 16), color: .systemBlue)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to encode PNG\n".utf8))
    exit(1)
}

let outURL = URL(fileURLWithPath: "Sources/CPUSnake/Resources/thumbnail.png")
try FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outURL)
print("wrote \(outURL.path) (\(png.count) bytes)")
