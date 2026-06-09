import SwiftUI

struct HTMLDeviationPanel: View {
    let centsOffset: Double?
    let statusColor: Color

    var body: some View {
        HTMLGlassPanel {
            VStack(spacing: 8) {
                HTMLPanelTitle("偏差刻度")
                    .frame(maxWidth: .infinity, alignment: .leading)

                GeometryReader { proxy in
                    let height = proxy.size.height
                    let centerX = proxy.size.width * 0.38
                    let trackHeight = height * 0.84
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

                        ForEach(1..<10, id: \.self) { index in
                            let y = trackTop + trackHeight * CGFloat(index) / 10.0
                            Rectangle()
                                .fill(index == 5 ? TunerTheme.gold : TunerTheme.muted.opacity(0.42))
                                .frame(width: index == 5 ? 34 : 18, height: 1)
                                .position(x: centerX - 12, y: y)
                        }

                        Circle()
                            .fill(statusColor)
                            .frame(width: 13, height: 13)
                            .shadow(color: statusColor.opacity(0.8), radius: 8, x: 0, y: 0)
                            .position(x: centerX, y: indicatorY)
                            .animation(.easeOut(duration: 0.45), value: centsOffset ?? 0)

                        VStack {
                            Text("0")
                            Spacer()
                            Text("正中")
                            Spacer()
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TunerTheme.gold)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        VStack {
                            Text("偏高")
                            Spacer()
                            Text("偏低")
                        }
                        .font(.caption2)
                        .foregroundStyle(TunerTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 28)
                        .padding(.bottom, 8)
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
