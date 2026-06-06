import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TunerViewModel()

    var body: some View {
        ZStack {
            TunerTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TunerHeader()
                    CurrentSelectionPill(string: viewModel.selectedString)
                    StringPickerCard(selectedString: $viewModel.selectedString)
                    ReadoutCard(viewModel: viewModel)
                    DeviationMeterCard(centsOffset: viewModel.centsOffset, centsText: viewModel.centsText, statusColor: statusColor)
                    AudioStatusCard(level: viewModel.inputActivityLevel, statusText: viewModel.recognitionStatusText, tint: statusColor)
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 118)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            TunerActionBar(
                isListening: viewModel.isListening,
                microphoneStatusText: viewModel.microphoneStatusText,
                action: viewModel.toggleListening
            )
        }
        .task {
            viewModel.recalculateLastResult()
        }
        .preferredColorScheme(.dark)
    }

    private var statusColor: Color {
        TunerTheme.color(from: viewModel.statusColorName)
    }
}

#Preview {
    ContentView()
}

private enum TunerTheme {
    static let ink = Color(red: 0.12, green: 0.10, blue: 0.09)
    static let panel = Color(red: 0.17, green: 0.15, blue: 0.13)
    static let panelRaised = Color(red: 0.23, green: 0.20, blue: 0.17)
    static let gold = Color(red: 1.00, green: 0.78, blue: 0.50)
    static let copper = Color(red: 0.84, green: 0.45, blue: 0.20)
    static let text = Color(red: 0.98, green: 0.88, blue: 0.72)
    static let muted = Color(red: 0.72, green: 0.65, blue: 0.57)
    static let border = Color.white.opacity(0.12)

    static var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.08),
                    Color(red: 0.18, green: 0.15, blue: 0.13),
                    Color(red: 0.09, green: 0.08, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    copper.opacity(0.34),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )

            RadialGradient(
                colors: [
                    gold.opacity(0.16),
                    .clear
                ],
                center: .bottom,
                startRadius: 40,
                endRadius: 380
            )
        }
    }

    static func color(from name: String) -> Color {
        switch name {
        case "green":
            return Color(red: 0.35, green: 0.88, blue: 0.47)
        case "orange":
            return Color(red: 1.00, green: 0.62, blue: 0.26)
        case "blue":
            return Color(red: 0.40, green: 0.68, blue: 1.00)
        case "red":
            return Color(red: 1.00, green: 0.36, blue: 0.30)
        default:
            return muted
        }
    }
}

private struct TunerCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                TunerTheme.panelRaised.opacity(0.92),
                                TunerTheme.panel.opacity(0.94)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(TunerTheme.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 12)
    }
}

private struct TunerHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text("琵琶调音")
                            .font(.system(size: 42, weight: .black, design: .serif))
                            .foregroundStyle(TunerTheme.text)
                            .shadow(color: TunerTheme.copper.opacity(0.38), radius: 8, x: 0, y: 3)

                        Text("听准")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(TunerTheme.copper)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .stroke(TunerTheme.copper, lineWidth: 1)
                            )
                    }

                    Text("选弦后，轻拨琴弦，App 会告诉你偏高还是偏低。")
                        .font(.callout)
                        .foregroundStyle(TunerTheme.muted)
                }

                Spacer(minLength: 12)

                Image(systemName: "gearshape")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(TunerTheme.gold)
                    .padding(.top, 4)
                    .accessibilityLabel("设置")
            }
        }
    }
}

private struct CurrentSelectionPill: View {
    let string: PipaString

    var body: some View {
        HStack(spacing: 8) {
            Text("当前选择")
                .foregroundStyle(TunerTheme.muted)
            Text(string.shortName)
                .fontWeight(.bold)
                .foregroundStyle(TunerTheme.gold)
            Text("· \(string.rawValue.replacingOccurrences(of: string.shortName, with: ""))")
                .foregroundStyle(TunerTheme.muted)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.24), in: Capsule())
        .overlay(
            Capsule()
                .stroke(TunerTheme.border, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }
}

private struct StringPickerCard: View {
    @Binding var selectedString: PipaString

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "选择弦", subtitle: "手动选择当前拨动的琴弦")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(PipaString.tuningOrder) { string in
                        StringOptionButton(
                            string: string,
                            isSelected: selectedString == string
                        ) {
                            selectedString = string
                        }
                    }
                }
            }
        }
    }
}

private struct StringOptionButton: View {
    let string: PipaString
    let isSelected: Bool
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
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? woodGradient : idleGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? TunerTheme.gold.opacity(0.72) : TunerTheme.border, lineWidth: 1)
            )
            .shadow(color: isSelected ? TunerTheme.copper.opacity(0.34) : .clear, radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var woodGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.52, green: 0.28, blue: 0.13),
                Color(red: 0.28, green: 0.16, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var idleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.06),
                Color.black.opacity(0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ReadoutCard: View {
    @ObservedObject var viewModel: TunerViewModel

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "实时结果", subtitle: viewModel.directionText)

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.detectedFrequencyText)
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(TunerTheme.text)
                        Text("当前频率")
                            .font(.caption)
                            .foregroundStyle(TunerTheme.muted)
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 4) {
                        Text(viewModel.selectedString.displayPitchName)
                            .font(.system(size: 48, weight: .black, design: .serif))
                            .foregroundStyle(TunerTheme.gold)
                        Text(viewModel.targetFrequencyText)
                            .font(.footnote)
                            .foregroundStyle(TunerTheme.muted)
                    }
                }

                HStack(spacing: 12) {
                    MetricTile(title: viewModel.centsText, subtitle: "偏差", tint: TunerTheme.color(from: viewModel.statusColorName))
                    MetricTile(title: viewModel.confidenceText, subtitle: "置信度", tint: Color(red: 0.35, green: 0.88, blue: 0.47))
                }
            }
        }
    }
}

private struct MetricTile: View {
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(TunerTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TunerTheme.border, lineWidth: 1)
        )
    }
}

private struct DeviationMeterCard: View {
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

                        VStack(alignment: .leading, spacing: 20) {
                            MeterLabel(text: "偏高", alignment: .top)
                            Spacer()
                            HStack(spacing: 10) {
                                Rectangle()
                                    .fill(TunerTheme.gold)
                                    .frame(width: 34, height: 2)
                                Text("正中")
                                    .foregroundStyle(TunerTheme.gold)
                            }
                            Spacer()
                            MeterLabel(text: "偏低", alignment: .bottom)
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, proxy.size.width * 0.58)
                        .padding(.vertical, 18)

                        VStack(spacing: 4) {
                            Text(centsOffset == nil ? "0" : centsText)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(TunerTheme.text)
                            Text("cents")
                                .font(.caption)
                                .foregroundStyle(TunerTheme.muted)
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

        let clamped = max(-50.0, min(50.0, centsOffset))
        return (clamped + 50.0) / 100.0
    }
}

private struct MeterLabel: View {
    let text: String
    let alignment: VerticalAlignment

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

private struct AudioStatusCard: View {
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
                    .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

private struct TunerActionBar: View {
    let isListening: Bool
    let microphoneStatusText: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: action) {
                HStack(spacing: 16) {
                    Image(systemName: isListening ? "stop.fill" : "waveform")
                        .font(.system(size: 23, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.22), in: Circle())

                    Rectangle()
                        .fill(Color.black.opacity(0.24))
                        .frame(width: 1, height: 30)

                    Text(isListening ? "停止监听" : "开始监听")
                        .font(.system(size: 26, weight: .black, design: .serif))

                    Spacer(minLength: 0)
                }
                .foregroundStyle(Color(red: 0.12, green: 0.07, blue: 0.03))
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.71, blue: 0.42),
                                    Color(red: 0.62, green: 0.30, blue: 0.13)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(TunerTheme.gold.opacity(0.85), lineWidth: 1.3)
                )
                .shadow(color: TunerTheme.copper.opacity(0.45), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Text(microphoneStatusText)
                .font(.caption)
                .foregroundStyle(TunerTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    TunerTheme.ink.opacity(0.92),
                    TunerTheme.ink
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

private struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(TunerTheme.text)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(TunerTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AudioActivityWaveform: View {
    let level: Double
    let tint: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate * 2.6
            let clampedLevel = max(0, min(1, level))

            Canvas { context, size in
                let baseline = size.height / 2
                let amplitude = max(3, size.height * 0.34 * clampedLevel)
                let mutedAmplitude = size.height * 0.04
                let activeAmplitude = clampedLevel > 0.03 ? amplitude : mutedAmplitude
                var path = Path()

                path.move(to: CGPoint(x: 0, y: baseline))
                for x in stride(from: 0.0, through: size.width, by: 2.0) {
                    let progress = x / max(1, size.width)
                    let wave = sin((progress * 3.0 * .pi * 2.0) + phase)
                    let y = baseline + wave * activeAmplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                context.stroke(
                    path,
                    with: .color(clampedLevel > 0.03 ? tint : TunerTheme.muted.opacity(0.45)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityLabel("音频输入状态")
    }
}
