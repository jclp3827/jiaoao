import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TunerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            stringPicker
            readout
            meter
            currentState
            actionRow
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .task {
            viewModel.recalculateLastResult()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("琵琶调音")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text("选弦后，轻拨琴弦，App 会告诉你偏高还是偏低。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var stringPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择琴弦")
                .font(.headline)

            Picker("选择琴弦", selection: $viewModel.selectedString) {
                ForEach(PipaString.tuningOrder) { string in
                    Text(string.shortName).tag(string)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.selectedString.rawValue)
                    .font(.subheadline.weight(.semibold))
                Text(viewModel.selectedString.targetDisplayText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(viewModel.selectedString.tuningHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("实时结果")
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.detectedFrequencyText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("当前频率")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(viewModel.targetFrequencyText)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("目标音高")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                labelChip(title: viewModel.centsText, subtitle: "偏差")
                labelChip(title: viewModel.confidenceText, subtitle: "置信度")
            }

            Text(viewModel.directionText)
                .font(.headline)
                .foregroundStyle(color(from: viewModel.statusColorName))
                .padding(.top, 2)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var meter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("偏差刻度")
                .font(.headline)

            GeometryReader { proxy in
                let height = proxy.size.height
                let centerX = proxy.size.width * 0.5
                let normalized = meterPosition(from: viewModel.centsOffset)
                let clamped = max(0.0, min(1.0, normalized))
                let indicatorY = height * (1.0 - clamped)

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(uiColor: .secondarySystemBackground),
                                    Color(uiColor: .systemBackground)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    VStack {
                        Text("偏高")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        Spacer()

                        Text("正中")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.08), in: Capsule())

                        Spacer()

                        Text("偏低")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 22)

                    ForEach(0..<11, id: \.self) { index in
                        let y = height * CGFloat(index) / 10.0
                        Rectangle()
                            .fill(index == 5 ? Color.primary.opacity(0.55) : Color.primary.opacity(0.22))
                            .frame(width: index == 5 ? 54 : 28, height: index == 5 ? 2.5 : 1.5)
                            .position(x: centerX, y: y)
                    }

                    Rectangle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 2, height: max(88, height * 0.72))
                        .position(x: centerX, y: height / 2)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color(from: viewModel.statusColorName).opacity(0.95),
                                    color(from: viewModel.statusColorName).opacity(0.55)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: 16)
                        .shadow(color: color(from: viewModel.statusColorName).opacity(0.5), radius: 8, x: 0, y: 0)
                        .position(x: centerX, y: indicatorY)

                    Circle()
                        .fill(color(from: viewModel.statusColorName).opacity(0.9))
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .position(x: centerX, y: indicatorY)

                    VStack(spacing: 6) {
                        Text(viewModel.centsText)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(color(from: viewModel.statusColorName))
                        Text("偏差")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: centerX, y: 38)
                }
            }
            .frame(height: 250)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var currentState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态")
                .font(.headline)

            AudioActivityWaveform(level: viewModel.inputActivityLevel, tint: color(from: viewModel.statusColorName))
                .frame(height: 44)

            Text(viewModel.recognitionStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var actionRow: some View {
        HStack {
            Button(action: {
                viewModel.toggleListening()
            }) {
                Label(viewModel.isListening ? "停止监听" : "开始监听", systemImage: viewModel.isListening ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Text(viewModel.microphoneStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func labelChip(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .systemGray6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func meterPosition(from centsOffset: Double?) -> Double {
        guard let centsOffset else {
            return 0.5
        }

        let clamped = max(-50.0, min(50.0, centsOffset))
        return (clamped + 50.0) / 100.0
    }

    private func color(from name: String) -> Color {
        switch name {
        case "green":
            return .green
        case "orange":
            return .orange
        case "blue":
            return .blue
        case "red":
            return .red
        default:
            return .secondary
        }
    }
}

#Preview {
    ContentView()
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
                    with: .color(clampedLevel > 0.03 ? tint : Color.secondary.opacity(0.35)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityLabel("音频输入状态")
    }
}
