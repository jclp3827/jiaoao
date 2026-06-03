import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TunerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            stringPicker
            readout
            meter
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
                let width = proxy.size.width
                let normalized = meterPosition(from: viewModel.centsText)
                let clamped = max(0.0, min(1.0, normalized))
                let indicatorX = width * clamped

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(uiColor: .systemGreen))
                        .frame(width: max(8, width * 0.1), height: 8)
                        .position(x: indicatorX, y: 4)
                }
                .overlay(alignment: .center) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.7))
                        .frame(width: 2, height: 18)
                        .position(x: width / 2, y: 4)
                }
                .overlay(alignment: .center) {
                    Circle()
                        .fill(color(from: viewModel.statusColorName))
                        .frame(width: 14, height: 14)
                        .position(x: indicatorX, y: 4)
                }
            }
            .frame(height: 24)

            HStack {
                Text("偏低")
                Spacer()
                Text("正中")
                Spacer()
                Text("偏高")
            }
            .font(.caption)
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

    private func meterPosition(from centsText: String) -> Double {
        let cleaned = centsText
            .replacingOccurrences(of: "cents", with: "")
            .replacingOccurrences(of: "+", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let cents = Double(cleaned) else {
            return 0.5
        }

        let clamped = max(-50.0, min(50.0, cents))
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
