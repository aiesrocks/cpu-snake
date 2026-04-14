import Foundation

struct GridPoint: Equatable {
    var x: Int
    var y: Int
}

struct GridSize {
    var width: Int
    var height: Int
}

enum Direction: CaseIterable {
    case up, down, left, right
    var dx: Int { switch self { case .left: -1; case .right: 1; default: 0 } }
    var dy: Int { switch self { case .up: -1; case .down: 1; default: 0 } }
}

enum SnakeKind {
    case cpu(coreIndex: Int)
    case gpu
}

final class Snake {
    var cells: [GridPoint]
    var direction: Direction
    let kind: SnakeKind
    var targetLength: Int = 1

    init(head: GridPoint, kind: SnakeKind) {
        self.cells = [head]
        self.kind = kind
        self.direction = Direction.allCases.randomElement()!
    }

    func step(in grid: GridSize) {
        let r = Double.random(in: 0..<1)
        if r < 0.5 {
            // keep going
        } else if r < 0.75 {
            direction = leftOf(direction)
        } else {
            direction = rightOf(direction)
        }
        let head = cells[0]
        let nx = ((head.x + direction.dx) % grid.width + grid.width) % grid.width
        let ny = ((head.y + direction.dy) % grid.height + grid.height) % grid.height
        cells.insert(GridPoint(x: nx, y: ny), at: 0)
        while cells.count > max(1, targetLength) {
            cells.removeLast()
        }
    }

    private func leftOf(_ d: Direction) -> Direction {
        switch d { case .up: .left; case .left: .down; case .down: .right; case .right: .up }
    }
    private func rightOf(_ d: Direction) -> Direction {
        switch d { case .up: .right; case .right: .down; case .down: .left; case .left: .up }
    }
}
