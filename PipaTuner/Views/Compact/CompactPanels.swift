import SwiftUI

struct HTMLGlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(8)
            .frame(maxWidth: .infinity)
            .tunerSurface(.glass, cornerRadius: 16)
    }
}

struct HTMLStringPickerPanel: View {
    @Binding var selectedString: PipaString
    let isEnabled: Bool

    var body: some View {
        HTMLGlassPanel {
            VStack(alignment: .leading, spacing: 6) {
                HTMLPanelTitle(isEnabled ? "选择弦" : "自动判弦")
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 4) {
                    ForEach(PipaString.tuningOrder) { string in
                        HTMLStringOption(string: string, isSelected: selectedString == string, isEnabled: isEnabled) {
                            selectedString = string
                        }
                    }
                }
            }
        }
    }
}

struct HTMLStringOption: View {
    let string: PipaString
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("\(string.shortName) / \(string.roleName)")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundStyle(isSelected ? TunerTheme.text : TunerTheme.muted.opacity(0.70))
                    .tunerSingleLine()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 6)
            .tunerOptionChrome(isSelected: isSelected, chromeStyle: .compact, cornerRadius: 10)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.72)
    }
}

struct HTMLReadoutPanel: View {
    @ObservedObject var viewModel: TunerViewModel
    let statusColor: Color

    var body: some View {
        HTMLGlassPanel {
            VStack(spacing: 6) {
                HTMLPanelTitle("实时结果")
                if viewModel.tuningMode == .auto {
                    AutoDetectionPill(title: "自动", value: viewModel.autoStatusText)
                }
                Text(viewModel.detectedFrequencyText)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(primaryReadoutColor)
                    .tunerSingleLine()
                    .frame(height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("目标")
                            .font(.system(size: 9, weight: .bold))
                            .tunerTextTone(.muted)
                            .frame(minWidth: 20, alignment: .leading)
                        Text(viewModel.activeString.frequencyLabel)
                            .tunerMetricText(size: 11, weight: .bold)
                            .monospacedDigit()
                            .tunerSingleLine()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(viewModel.activeString.displayPitchName)
                            .tunerMetricText(size: 22, weight: .black, design: .serif)
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
                .frame(minHeight: 46)
                .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
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
}

struct HTMLTargetPanel: View {
    let string: PipaString

    var body: some View {
        HTMLGlassPanel {
            VStack(spacing: 4) {
                HTMLPanelTitle("目标音高")
                Text(string.displayPitchName)
                    .tunerMetricText(size: 29, weight: .black, design: .serif)
                Text(string.frequencyLabel)
                    .tunerMetricText(size: 14, weight: .bold)
                    .tunerSingleLine()
                Text(string.jianpuLabel)
                    .font(.caption2)
                    .tunerTextTone(.muted)
            }
        }
    }
}

struct HTMLConfidencePanel: View {
    let confidenceText: String
    let statusColor: Color
    let isActive: Bool

    var body: some View {
        HTMLGlassPanel {
            VStack(spacing: 5) {
                HTMLPanelTitle("稳定度")
                Text(confidenceText)
                    .font(.system(size: 23, weight: .black, design: .rounded))
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

struct HTMLPanelTitle: View {
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
