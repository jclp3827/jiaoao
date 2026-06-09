import SwiftUI

struct CompactDeviationPanel: View {
    let centsOffset: Double?
    let statusColor: Color

    var body: some View {
        CompactGlassPanel {
            VStack(spacing: 6) {
                CompactPanelTitle("偏差")
                    .frame(maxWidth: .infinity, alignment: .center)

                GeometryReader { proxy in
                    let height = proxy.size.height
                    let centerX = proxy.size.width * 0.45
                    let labelX = proxy.size.width * 0.80
                    let trackHeight = height * 0.90
                    let trackTop = (height - trackHeight) / 2
                    let trackBottom = trackTop + trackHeight
                    let normalized = meterPosition(from: centsOffset)
                    let indicatorY = trackBottom - (trackHeight * normalized)

                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        TunerTheme.gold.opacity(0.38),
                                        TunerTheme.gold.opacity(0.72),
                                        TunerTheme.gold.opacity(0.38)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 4, height: trackHeight)
                            .position(x: centerX, y: height / 2)

                        ForEach(0...10, id: \.self) { index in
                            let y = trackTop + trackHeight * CGFloat(index) / 10.0
                            Rectangle()
                                .fill(index == 5 ? TunerTheme.gold : TunerTheme.muted.opacity(0.36))
                                .frame(width: index == 5 ? 28 : 14, height: 1)
                                .position(x: centerX - 10, y: y)
                        }

                        ForEach(0..<10, id: \.self) { index in
                            let y = trackTop + trackHeight * (CGFloat(index) + 0.5) / 10.0
                            Rectangle()
                                .fill(TunerTheme.muted.opacity(0.24))
                                .frame(width: 7, height: 1)
                                .position(x: centerX - 10, y: y)
                        }

                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                            .shadow(color: statusColor.opacity(0.72), radius: 7, x: 0, y: 0)
                            .position(x: centerX, y: indicatorY)
                            .animation(.easeOut(duration: 0.45), value: centsOffset ?? 0)

                        Group {
                            CompactMeterLabel(text: "高")
                                .position(x: labelX, y: trackTop)
                            CompactMeterLabel(text: "中", tint: TunerTheme.gold)
                                .position(x: labelX, y: trackTop + trackHeight * 0.50)
                            CompactMeterLabel(text: "低")
                                .position(x: labelX, y: trackBottom)
                        }
                        .font(.system(size: 9, weight: .semibold))
                    }
                }
            }
        }
    }

    private func meterPosition(from centsOffset: Double?) -> Double {
        guard let centsOffset else {
            return 0.5
        }

        let range = TunerConfiguration.Tuning.centsDisplayRange
        let clamped = max(-range, min(range, centsOffset))
        return (clamped + range) / (range * 2.0)
    }
}

private struct CompactMeterLabel: View {
    let text: String
    var tint: Color = TunerTheme.muted

    var body: some View {
        Text(text)
            .foregroundStyle(tint)
            .lineLimit(1)
    }
}
