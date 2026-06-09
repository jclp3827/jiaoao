import SwiftUI

struct CompactGlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(7)
            .frame(maxWidth: .infinity)
            .tunerSurface(.glass, cornerRadius: 14)
    }
}

struct CompactReadoutPanel: View {
    @ObservedObject var viewModel: TunerViewModel
    let statusColor: Color

    var body: some View {
        CompactGlassPanel {
            VStack(spacing: 5) {
                CompactPanelTitle("实时结果")
                if viewModel.tuningMode == .auto {
                    AutoDetectionPill(title: "", value: viewModel.autoStatusText)
                }
                Text(viewModel.detectedFrequencyText)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(primaryReadoutColor)
                    .tunerSingleLine()
                    .frame(height: 23)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("目标")
                            .font(.system(size: 9, weight: .bold))
                            .tunerTextTone(.muted)
                            .frame(minWidth: 20, alignment: .leading)
                        Text(viewModel.activeString.frequencyLabel)
                            .tunerMetricText(size: 10.5, weight: .bold)
                            .monospacedDigit()
                            .tunerSingleLine()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(readoutPitchName)
                            .tunerMetricText(size: 21, weight: .black, design: .serif)
                            .frame(minWidth: 22, alignment: .leading)
                        Text(viewModel.activeString.jianpuLabel)
                            .font(.system(size: 9, weight: .regular))
                            .tunerTextTone(.muted)
                            .tunerSingleLine()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .frame(minHeight: 44)
                .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(referenceBorderColor, lineWidth: 1)
                )
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

struct CompactConfidencePanel: View {
    let confidenceText: String
    let statusColor: Color
    let isActive: Bool

    var body: some View {
        CompactGlassPanel {
            VStack(spacing: 5) {
                CompactPanelTitle("稳定度")
                Text(confidenceText)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tint)
                    .tunerSingleLine()
                Text("识别质量")
                    .font(.caption2)
                    .tunerTextTone(.muted)

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(index < activeSegments ? tint : TunerTheme.muted.opacity(0.22))
                            .frame(height: 5)
                    }
                }
            }
        }
    }

    private var activeSegments: Int {
        let digits = confidenceText.filter(\.isNumber)
        let value = Int(digits) ?? 0
        return max(0, min(5, Int((Double(value) / 100.0 * 5.0).rounded(.up))))
    }

    private var tint: Color {
        isActive ? statusColor : TunerTheme.muted
    }
}

struct CompactPanelTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .tunerMetricText(size: 14, weight: .bold, design: .serif)
            .tunerSingleLine(0.8)
    }
}
