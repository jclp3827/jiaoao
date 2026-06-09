import SwiftUI

struct StringPickerCard: View {
    @Binding var selectedString: PipaString
    let displayString: PipaString
    let isEnabled: Bool

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(
                    title: "选择弦",
                    subtitle: isEnabled ? "手动选择当前拨动的琴弦" : "自动模式下由系统判定当前弦",
                    alignment: .center
                )
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    ForEach(PipaString.tuningOrder) { string in
                        StringOptionButton(
                            string: string,
                            isSelected: displayString == string,
                            isEnabled: isEnabled
                        ) {
                            selectedString = string
                        }
                    }
                }
            }
        }
    }
}

struct StringOptionButton: View {
    let string: PipaString
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(string.shortName)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(isSelected ? TunerTheme.text : TunerTheme.muted)
                    Text(string.jianpuLabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(isSelected ? TunerTheme.gold : TunerTheme.muted.opacity(0.78))
                }

                Spacer(minLength: 4)

                ZStack {
                    Circle()
                        .stroke(isSelected ? TunerTheme.gold : TunerTheme.border, lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(TunerTheme.gold)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .tunerOptionChrome(isSelected: isSelected, cornerRadius: 14)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.7)
    }
}

struct ReadoutCard: View {
    @ObservedObject var viewModel: TunerViewModel
    let statusColor: Color

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Text("实时结果")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(TunerTheme.text)

                    Spacer(minLength: 0)

                    if viewModel.tuningMode == .auto {
                        AutoDetectionPill(title: "", value: viewModel.autoStatusText)
                    }
                }

                VStack(spacing: 10) {
                    Text(viewModel.detectedFrequencyText)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(primaryReadoutColor)
                        .tunerSingleLine()
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("目标")
                                .font(.caption2.weight(.bold))
                                .tunerTextTone(.muted)
                                .frame(minWidth: 32, alignment: .leading)
                            Text(viewModel.activeString.frequencyLabel)
                                .tunerMetricText(size: 17, weight: .bold)
                                .monospacedDigit()
                                .tunerSingleLine()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(readoutPitchName)
                                .tunerMetricText(size: 32, weight: .black, design: .serif, tone: .gold)
                                .frame(minWidth: 32, alignment: .leading)
                            Text(viewModel.activeString.jianpuLabel)
                                .font(.caption2)
                                .tunerTextTone(.muted)
                                .tunerSingleLine()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 74)
                    .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(referenceBorderColor, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var hasDetectedFrequency: Bool {
        viewModel.detectedFrequencyText != "--"
    }

    private var primaryReadoutColor: Color {
        hasDetectedFrequency ? statusColor : TunerTheme.muted
    }

    private var referenceBorderColor: Color {
        hasDetectedFrequency ? statusColor.opacity(0.30) : TunerTheme.border.opacity(0.80)
    }

    private var readoutPitchName: String {
        viewModel.activeString == .fourth ? "A" : viewModel.activeString.displayPitchName
    }
}

struct TargetPitchCard: View {
    let string: PipaString

    var body: some View {
        TunerCard {
            VStack(alignment: .center, spacing: 8) {
                SectionTitle(title: "目标音高", subtitle: "当前所选弦的标准音")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(string.displayPitchName)
                    .tunerMetricText(size: 42, weight: .black, design: .serif, tone: .gold)
                Text(string.frequencyLabel)
                    .tunerMetricText(size: 23, weight: .bold)
                Text(string.jianpuLabel)
                    .font(.callout)
                    .tunerTextTone(.muted)
            }
        }
    }
}

struct ConfidenceCard: View {
    let confidenceText: String
    let statusColor: Color
    let isActive: Bool

    var body: some View {
        TunerCard {
            VStack(alignment: .center, spacing: 10) {
                SectionTitle(title: "稳定度", subtitle: "本次识别质量")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(confidenceText)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tint)

                HStack(spacing: 6) {
                    ForEach(0..<6, id: \.self) { index in
                        Capsule()
                            .fill(index < activeSegments ? tint : TunerTheme.muted.opacity(0.22))
                            .frame(height: 7)
                    }
                }
            }
        }
    }

    private var activeSegments: Int {
        let digits = confidenceText.filter(\.isNumber)
        let value = Int(digits) ?? 0
        return max(0, min(6, Int((Double(value) / 100.0 * 6.0).rounded(.up))))
    }

    private var tint: Color {
        isActive ? statusColor : TunerTheme.muted
    }
}

struct DeviationMeterCard: View {
    let centsOffset: Double?
    let centsText: String
    let statusColor: Color

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "偏差", subtitle: "越靠近中，音准越接近目标", alignment: .center)
                    .frame(maxWidth: .infinity)

                GeometryReader { proxy in
                    let height = proxy.size.height
                    let centerX = proxy.size.width * 0.42
                    let trackHeight = height * 0.88
                    let trackTop = (height - trackHeight) / 2
                    let trackBottom = trackTop + trackHeight
                    let normalized = meterPosition(from: centsOffset)
                    let clamped = max(0.0, min(1.0, normalized))
                    let indicatorY = trackBottom - (trackHeight * clamped)

                    ZStack {
                        Capsule()
                            .fill(Color.black.opacity(0.30))
                            .frame(width: 10, height: trackHeight)
                            .position(x: centerX, y: height / 2)

                        ForEach(0...10, id: \.self) { index in
                            let y = trackTop + trackHeight * CGFloat(index) / 10.0
                            Rectangle()
                                .fill(index == 5 ? TunerTheme.gold.opacity(0.9) : TunerTheme.muted.opacity(0.34))
                                .frame(width: index == 5 ? 58 : 34, height: index == 5 ? 2.2 : 1)
                                .position(x: centerX, y: y)
                        }

                        ForEach(0..<10, id: \.self) { index in
                            let y = trackTop + trackHeight * (CGFloat(index) + 0.5) / 10.0
                            Rectangle()
                                .fill(TunerTheme.muted.opacity(0.24))
                                .frame(width: 17, height: 1)
                                .position(x: centerX, y: y)
                        }

                        Capsule()
                            .fill(statusColor)
                            .frame(width: 17, height: 22)
                            .shadow(color: statusColor.opacity(0.68), radius: 8, x: 0, y: 0)
                            .position(x: centerX, y: indicatorY)
                            .animation(.easeOut(duration: 0.45), value: centsOffset ?? 0)

                        Group {
                            MeterLabel(text: "高")
                                .position(x: proxy.size.width * 0.72, y: trackTop)
                            MeterLabel(text: "中", tint: TunerTheme.gold)
                                .position(x: proxy.size.width * 0.72, y: trackTop + trackHeight * 0.50)
                            MeterLabel(text: "低")
                                .position(x: proxy.size.width * 0.72, y: trackBottom)
                        }
                        .font(.system(size: 13, weight: .semibold))

                        VStack(spacing: 4) {
                            Text(centsOffset == nil ? "--" : centsText)
                                .tunerMetricText(size: 22, weight: .bold)
                            Text("cents")
                                .font(.caption)
                                .tunerTextTone(.muted)
                        }
                        .position(x: centerX, y: 22)
                    }
                }
                .frame(height: 386)
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

struct MeterLabel: View {
    let text: String
    var tint: Color = TunerTheme.muted

    var body: some View {
        Text(text)
            .foregroundStyle(tint)
    }
}

struct AudioStatusCard: View {
    let level: Double
    let statusText: String
    let tint: Color

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "当前状态", subtitle: statusText)

                AudioActivityWaveform(level: level, tint: tint)
                    .frame(height: 52)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .tunerSurface(.inset, cornerRadius: 18)
            }
        }
    }
}
