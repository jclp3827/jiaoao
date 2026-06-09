import SwiftUI

struct PipaBackdrop: View {
    let activeString: PipaString

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            Image("pipaHero")
                .resizable()
                .scaledToFit()
                .frame(width: 382)
                .overlay {
                    PipaHighlightOverlay(string: activeString)
                }
                .scaleEffect(1.26)
                .shadow(color: .black.opacity(0.58), radius: 20, x: 0, y: 14)
                .accessibilityLabel("琵琶")
                .allowsHitTesting(false)

            Spacer()
                .frame(height: 214)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

private struct PipaHighlightOverlay: View {
    let string: PipaString

    var body: some View {
        Canvas { context, size in
            let geometry = PipaHighlightGeometry(string: string)
            let stringPath = path(from: geometry.stringPath, in: size)
            let pegEdgePath = smoothPath(from: geometry.pegEdgePath, in: size)
            let bridgePoint = point(geometry.bridgePoint, in: size)

            drawStringHighlight(stringPath, bridgePoint: bridgePoint, in: &context)
            drawPegEdgeHighlight(pegEdgePath, in: &context)
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.20), value: string)
    }

    private func path(from points: [UnitPoint], in size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else {
            return path
        }

        path.move(to: point(first, in: size))
        for point in points.dropFirst() {
            path.addLine(to: self.point(point, in: size))
        }
        return path
    }

    private func smoothPath(from points: [UnitPoint], in size: CGSize) -> Path {
        var path = Path()
        let cgPoints = points.map { point($0, in: size) }
        guard let first = cgPoints.first else {
            return path
        }

        path.move(to: first)
        guard cgPoints.count > 2 else {
            for point in cgPoints.dropFirst() {
                path.addLine(to: point)
            }
            return path
        }

        for index in 1..<(cgPoints.count - 1) {
            let control = cgPoints[index]
            let next = cgPoints[index + 1]
            let midpoint = CGPoint(
                x: (control.x + next.x) / 2,
                y: (control.y + next.y) / 2
            )
            path.addQuadCurve(to: midpoint, control: control)
        }

        if let last = cgPoints.last {
            path.addLine(to: last)
        }
        return path
    }

    private func point(_ unitPoint: UnitPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: unitPoint.x * size.width, y: unitPoint.y * size.height)
    }

    private func drawStringHighlight(
        _ path: Path,
        bridgePoint: CGPoint,
        in context: inout GraphicsContext
    ) {
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: TunerTheme.copper.opacity(0.56), radius: 6))
            layer.stroke(
                path,
                with: .color(TunerTheme.gold.opacity(0.46)),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
            )
        }

        context.drawLayer { layer in
            layer.addFilter(.shadow(color: TunerTheme.gold.opacity(0.76), radius: 3))
            layer.stroke(
                path,
                with: .color(TunerTheme.gold.opacity(0.96)),
                style: StrokeStyle(lineWidth: 0.9, lineCap: .round, lineJoin: .round)
            )
        }

        let bridgeGlow = CGRect(
            x: bridgePoint.x - 2.5,
            y: bridgePoint.y - 2.5,
            width: 5,
            height: 5
        )
        context.fill(Path(ellipseIn: bridgeGlow), with: .color(TunerTheme.gold.opacity(0.95)))
    }

    private func drawPegEdgeHighlight(_ path: Path, in context: inout GraphicsContext) {
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: TunerTheme.copper.opacity(0.52), radius: 5))
            layer.stroke(
                path,
                with: .color(TunerTheme.gold.opacity(0.34)),
                style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
            )
        }

        context.drawLayer { layer in
            layer.addFilter(.shadow(color: TunerTheme.gold.opacity(0.72), radius: 3))
            layer.stroke(
                path,
                with: .color(TunerTheme.gold.opacity(0.90)),
                style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

private struct PipaHighlightGeometry {
    let stringPath: [UnitPoint]
    let bridgePoint: UnitPoint
    let pegEdgePath: [UnitPoint]

    init(string: PipaString) {
        switch string {
        case .first:
            stringPath = [
                Self.point(x: 651, y: 1293),
                Self.point(x: 606, y: 315)
            ]
            bridgePoint = Self.point(x: 651, y: 1293)
            pegEdgePath = [
                Self.point(x: 611, y: 318),
                Self.point(x: 626, y: 318),
                Self.point(x: 658, y: 319),
                Self.point(x: 706, y: 318),
                Self.point(x: 740, y: 322),
                Self.point(x: 750, y: 332),
                Self.point(x: 749, y: 341),
                Self.point(x: 739, y: 351),
                Self.point(x: 706, y: 352),
                Self.point(x: 674, y: 349),
                Self.point(x: 642, y: 344),
                Self.point(x: 611, y: 343)
            ]
        case .second:
            stringPath = [
                Self.point(x: 627, y: 1294),
                Self.point(x: 598, y: 315)
            ]
            bridgePoint = Self.point(x: 627, y: 1294)
            pegEdgePath = [
                Self.point(x: 572, y: 309),
                Self.point(x: 554, y: 310),
                Self.point(x: 522, y: 310),
                Self.point(x: 490, y: 310),
                Self.point(x: 457, y: 310),
                Self.point(x: 444, y: 323),
                Self.point(x: 441, y: 332),
                Self.point(x: 450, y: 342),
                Self.point(x: 474, y: 346),
                Self.point(x: 506, y: 341),
                Self.point(x: 538, y: 337),
                Self.point(x: 572, y: 335)
            ]
        case .third:
            stringPath = [
                Self.point(x: 599, y: 1295),
                Self.point(x: 590, y: 315)
            ]
            bridgePoint = Self.point(x: 599, y: 1295)
            pegEdgePath = [
                Self.point(x: 620, y: 284),
                Self.point(x: 636, y: 283),
                Self.point(x: 656, y: 275),
                Self.point(x: 680, y: 270),
                Self.point(x: 704, y: 265),
                Self.point(x: 729, y: 262),
                Self.point(x: 746, y: 272),
                Self.point(x: 750, y: 282),
                Self.point(x: 742, y: 292),
                Self.point(x: 704, y: 298),
                Self.point(x: 672, y: 298),
                Self.point(x: 640, y: 302),
                Self.point(x: 620, y: 301)
            ]
        case .fourth:
            stringPath = [
                Self.point(x: 573, y: 1295),
                Self.point(x: 583, y: 315)
            ]
            bridgePoint = Self.point(x: 573, y: 1295)
            pegEdgePath = [
                Self.point(x: 572, y: 260),
                Self.point(x: 543, y: 256),
                Self.point(x: 511, y: 250),
                Self.point(x: 479, y: 245),
                Self.point(x: 459, y: 244),
                Self.point(x: 445, y: 253),
                Self.point(x: 444, y: 262),
                Self.point(x: 450, y: 272),
                Self.point(x: 479, y: 279),
                Self.point(x: 511, y: 280),
                Self.point(x: 543, y: 281),
                Self.point(x: 574, y: 286)
            ]
        }
    }

    private static func point(x: CGFloat, y: CGFloat) -> UnitPoint {
        UnitPoint(x: x / 1183.0, y: y / 1536.0)
    }
}
