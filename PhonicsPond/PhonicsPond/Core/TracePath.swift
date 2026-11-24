import CoreGraphics
import Foundation

/// Lowercase letter shapes for tracing, in a unit square (x right, y down).
/// x-height runs from about 0.40 to 0.84; t rises to 0.18 and p descends to 1.0.
/// Strokes follow common handwriting order. Each stroke is a dense polyline.
struct LetterPath {
    let letter: String
    let strokes: [[CGPoint]]

    static func path(for letter: String) -> LetterPath? {
        switch letter {
        case "s":
            return LetterPath(letter: "s", strokes: [
                arc(cx: 0.5, cy: 0.51, r: 0.115, from: -25, to: -270) +
                arc(cx: 0.5, cy: 0.74, r: 0.115, from: -90, to: 150)
            ])
        case "a":
            // Single-storey a: round counter-clockwise, then the stem down the right side.
            return LetterPath(letter: "a", strokes: [
                arc(cx: 0.47, cy: 0.62, r: 0.2, from: -35, to: -395),
                line(CGPoint(x: 0.67, y: 0.41), CGPoint(x: 0.67, y: 0.84))
            ])
        case "t":
            return LetterPath(letter: "t", strokes: [
                line(CGPoint(x: 0.46, y: 0.18), CGPoint(x: 0.46, y: 0.74)) +
                arc(cx: 0.56, cy: 0.74, r: 0.1, from: 180, to: 60),
                line(CGPoint(x: 0.31, y: 0.40), CGPoint(x: 0.63, y: 0.40))
            ])
        case "p":
            return LetterPath(letter: "p", strokes: [
                line(CGPoint(x: 0.34, y: 0.40), CGPoint(x: 0.34, y: 1.0)),
                arc(cx: 0.5, cy: 0.61, r: 0.17, from: -160, to: 160)
            ])
        default:
            return nil
        }
    }

    /// Points along an arc. Angles in degrees; 0 = right, 90 = down (y grows downward).
    /// Going from a larger to a smaller angle draws counter-clockwise on screen.
    static func arc(cx: CGFloat, cy: CGFloat, r: CGFloat, from start: CGFloat, to end: CGFloat) -> [CGPoint] {
        let steps = max(8, Int(abs(end - start) / 6))
        return (0...steps).map { i in
            let angle = (start + (end - start) * CGFloat(i) / CGFloat(steps)) * .pi / 180
            return CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
        }
    }

    static func line(_ a: CGPoint, _ b: CGPoint) -> [CGPoint] {
        let steps = max(4, Int(hypot(b.x - a.x, b.y - a.y) / 0.02))
        return (0...steps).map { i in
            let t = CGFloat(i) / CGFloat(steps)
            return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
    }

    /// Evenly spaced guide dots for one stroke.
    static func dots(along points: [CGPoint], spacing: CGFloat = 0.055) -> [CGPoint] {
        guard var last = points.first else { return [] }
        var result = [last]
        var carried: CGFloat = 0
        for point in points.dropFirst() {
            carried += hypot(point.x - last.x, point.y - last.y)
            if carried >= spacing {
                result.append(point)
                carried = 0
            }
            last = point
        }
        if let end = points.last, result.last != end { result.append(end) }
        return result
    }
}

/// Follows a finger along the guide dots, stroke by stroke.
/// Generous tolerance; going off the path simply doesn't advance.
struct TraceTracker: Equatable {
    let dots: [[CGPoint]]
    let tolerance: CGFloat
    private(set) var stroke = 0
    private(set) var reached = 0      // dots reached in the current stroke
    private(set) var tracing = false

    init(path: LetterPath, tolerance: CGFloat = 0.075) {
        dots = path.strokes.map { LetterPath.dots(along: $0) }
        self.tolerance = tolerance
    }

    var isComplete: Bool { stroke >= dots.count }
    var currentStartDot: CGPoint? { isComplete ? nil : dots[stroke].first }

    /// Dots already reached, across all strokes (for drawing).
    func isReached(stroke s: Int, dot d: Int) -> Bool {
        s < stroke || (s == stroke && d < reached)
    }

    /// Finger down. Tracing starts only near the start of the current stroke.
    mutating func begin(at point: CGPoint) -> Bool {
        guard let start = currentStartDot else { return false }
        tracing = distance(point, start) <= tolerance * 1.4
        if tracing { reached = max(reached, 1) }
        return tracing
    }

    /// Finger moved. Advances when the finger is near one of the next few dots.
    mutating func move(to point: CGPoint) {
        guard tracing, !isComplete else { return }
        let stroke = dots[self.stroke]
        let window = reached..<min(reached + 3, stroke.count)
        if let hit = window.last(where: { distance(point, stroke[$0]) <= tolerance }) {
            reached = hit + 1
        }
        if reached >= stroke.count {
            self.stroke += 1
            reached = 0
            tracing = false
        }
    }

    /// Finger up. Partial progress on a stroke is kept so the child can continue.
    mutating func end() { tracing = false }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
}
