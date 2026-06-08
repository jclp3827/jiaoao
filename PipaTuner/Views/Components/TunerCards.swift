import SwiftUI

struct StringPickerCard: View {
    @Binding var selectedString: PipaString
    let isEnabled: Bool

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "选择弦", subtitle: isEnabled ? "手动选择当前拨动的琴弦" : "自动模式下由系统判定当前弦")

                VStack(spacing: 10) {
                    ForEach(PipaString.tuningOrder) { string in
                        StringOptionButton(
                            string: string,
                            isSelected: selectedString == string,
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
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(string.shortName)
                        .font(.headline)
                        .foregroundStyle(isSelected ? TunerTheme.text : TunerTheme.muted)
                    Text(string.jianpuLabel)
                        .font(.caption)
                        .foregroundStyle(isSelected ? TunerTheme.gold : TunerTheme.muted.opacity(0.78))
                }

                Spacer(minLength: 4)

                ZStack {
                    Circle()
                        .stroke(isSelected ? TunerTheme.gold : TunerTheme.border, lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(TunerTheme.gold)
                            .frame(width: 9, height: 9)
                    }
                }
            }
            .padding(14)
            .tunerOptionChrome(isSelected: isSelected, cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.7)
    }
}

struct ReadoutCard: View {
    @ObservedObject var viewModel: TunerViewModel

    var body: some View {
        TunerCard {
            VStack(alignment: .center, spacing: 14) {
                SectionTitle(title: "实时结果", subtitle: viewModel.directionText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.tuningMode == .auto {
                    AutoDetectionPill(title: "自动判弦", value: viewModel.autoStatusText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ZStack {
                    Circle()
                        .stroke(TunerTheme.copper.opacity(0.14), lineWidth: 1)
                        .frame(width: 130, height: 130)
                    Circle()
                        .stroke(TunerTheme.copper.opacity(0.10), lineWidth: 1)
                        .frame(width: 96, height: 96)

                    VStack(spacing: 4) {
                        Text(viewModel.activeString.displayPitchName)
                            .tunerMetricText(size: 58, weight: .black, design: .serif, tone: .gold)
                        Text(viewModel.detectedFrequencyText)
                            .tunerMetricText(size: 24, weight: .bold)
                        Text(viewModel.activeString.jianpuLabel)
                            .font(.footnote)
                            .tunerTextTone(.muted)
                    }
                }
            }
        }
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

    var body: some View {
        TunerCard {
            VStack(alignment: .center, spacing: 12) {
                SectionTitle(title: "偏差", subtitle: "本次识别置信度")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(confidenceText)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.35, green: 0.88, blue: 0.47))

                HStack(spacing: 6) {
                    ForEach(0..<6, id: \.self) { _ in
                        Capsule()
                            .fill(Color(red: 0.35, green: 0.88, blue: 0.47))
                            .frame(height: 7)
                    }
                }
            }
        }
    }
}

struct DeviationMeterCard: View {
    let centsOffset: Double?
    let centsText: String
    let statusColor: Color

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "偏差刻度", subtitle: "越靠近正中，音准越接近目标")

                GeometryReader { proxy in
                    let height = proxy.size.height
                    let centerX = proxy.size.width * 0.38
                    let normalized = meterPosition(from: centsOffset)
                    let clamped = max(0.0, min(1.0, normalized))
                    let indicatorY = height * (1.0 - clamped)

                    ZStack {
                        Capsule()
                            .fill(Color.black.opacity(0.28))
                            .frame(width: 12, height: height * 0.86)
                            .position(x: centerX, y: height / 2)

                        ForEach(0..<11, id: \.self) { index in
                            let y = height * CGFloat(index) / 10.0
                            Rectangle()
                                .fill(index == 5 ? TunerTheme.gold.opacity(0.9) : TunerTheme.muted.opacity(0.34))
                                .frame(width: index == 5 ? 64 : 38, height: index == 5 ? 2.5 : 1)
                                .position(x: centerX, y: y)
                        }

                        Capsule()
                            .fill(statusColor)
                            .frame(width: 18, height: 24)
                            .shadow(color: statusColor.opacity(0.75), radius: 10, x: 0, y: 0)
                            .position(x: centerX, y: indicatorY)
                            .animation(.easeOut(duration: 0.45), value: centsOffset ?? 0)

                        VStack(alignment: .leading, spacing: 20) {
                            MeterLabel(text: "偏高")
                            Spacer()
                            HStack(spacing: 10) {
                                Rectangle()
                                    .fill(TunerTheme.gold)
                                    .frame(width: 34, height: 2)
                                Text("正中")
                                    .foregroundStyle(TunerTheme.gold)
                            }
                            Spacer()
                            MeterLabel(text: "偏低")
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, proxy.size.width * 0.58)
                        .padding(.vertical, 18)

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
                .frame(height: 260)
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

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(TunerTheme.muted.opacity(0.5))
                .frame(width: 28, height: 1)
            Text(text)
                .foregroundStyle(TunerTheme.muted)
        }
    }
}

struct AudioStatusCard: View {
    let level: Double
    let statusText: String
    let tint: Color

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "当前状态", subtitle: statusText)

                AudioActivityWaveform(level: level, tint: tint)
                    .frame(height: 56)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .tunerSurface(.inset, cornerRadius: 18)
            }
        }
    }
}
