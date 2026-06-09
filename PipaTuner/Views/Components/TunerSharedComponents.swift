import SwiftUI

enum TunerSurfaceStyle {
    case card
    case glass
    case badge
    case inset
}

enum TunerOptionChromeStyle {
    case full
    case compact
}

enum TunerTextTone {
    case primary
    case muted
    case gold
}

private struct TunerSurfaceModifier: ViewModifier {
    let style: TunerSurfaceStyle
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        switch style {
        case .card:
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(TunerTheme.raisedPanelGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(TunerTheme.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 9)
        case .glass:
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(TunerTheme.panel.opacity(0.76))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(TunerTheme.gold.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.32), radius: 13, x: 0, y: 8)
        case .badge:
            content
                .background(Color.black.opacity(0.24), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(TunerTheme.border, lineWidth: 1)
                )
        case .inset:
            content
                .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(TunerTheme.border, lineWidth: 1)
                )
        }
    }
}

extension View {
    func tunerSurface(_ style: TunerSurfaceStyle, cornerRadius: CGFloat) -> some View {
        modifier(TunerSurfaceModifier(style: style, cornerRadius: cornerRadius))
    }

    func tunerOptionChrome(
        isSelected: Bool,
        chromeStyle: TunerOptionChromeStyle = .full,
        cornerRadius: CGFloat
    ) -> some View {
        modifier(
            TunerOptionChromeModifier(
                isSelected: isSelected,
                chromeStyle: chromeStyle,
                cornerRadius: cornerRadius
            )
        )
    }

    func tunerTextTone(_ tone: TunerTextTone) -> some View {
        foregroundStyle(tunerColor(for: tone))
    }

    func tunerMetricText(
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design = .rounded,
        tone: TunerTextTone = .primary
    ) -> some View {
        font(.system(size: size, weight: weight, design: design))
            .foregroundStyle(tunerColor(for: tone))
    }

    func tunerSingleLine(_ minimumScale: CGFloat = 0.72) -> some View {
        lineLimit(1)
            .minimumScaleFactor(minimumScale)
    }
}

private func tunerColor(for tone: TunerTextTone) -> Color {
    switch tone {
    case .primary:
        return TunerTheme.text
    case .muted:
        return TunerTheme.muted
    case .gold:
        return TunerTheme.gold
    }
}

private struct TunerOptionChromeModifier: ViewModifier {
    let isSelected: Bool
    let chromeStyle: TunerOptionChromeStyle
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let strokeColor = isSelected ? TunerTheme.gold.opacity(0.72) : idleStrokeColor

        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: strokeLineWidth)
            )
            .shadow(color: isSelected ? TunerTheme.copper.opacity(0.26) : .clear, radius: 8, x: 0, y: 5)
    }

    private var backgroundFill: AnyShapeStyle {
        switch chromeStyle {
        case .full:
            return AnyShapeStyle(isSelected ? TunerTheme.optionSelectedGradient : TunerTheme.optionIdleGradient)
        case .compact:
            return AnyShapeStyle(Color.black.opacity(0.001))
        }
    }

    private var idleStrokeColor: Color {
        switch chromeStyle {
        case .full:
            return TunerTheme.border
        case .compact:
            return .clear
        }
    }

    private var strokeLineWidth: CGFloat {
        switch chromeStyle {
        case .full:
            return 1
        case .compact:
            return 1.2
        }
    }
}

struct TunerCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tunerSurface(.card, cornerRadius: 18)
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(TunerTheme.text)
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(TunerTheme.muted)
                .multilineTextAlignment(textAlignment)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var textAlignment: TextAlignment {
        alignment == .center ? .center : .leading
    }
}

struct AudioActivityWaveform: View {
    let level: Double
    let tint: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate * 2.6
            let clampedLevel = max(0, min(1, level))

            Canvas { context, size in
                let baseline = size.height / 2
                let barWidth = min(3.2, max(2.4, size.width / 60))
                let spacing = barWidth * 2.2
                let count = max(1, Int(size.width / spacing))
                let totalWidth = CGFloat(count - 1) * spacing
                let startX = (size.width - totalWidth) / 2
                let mutedHeight = size.height * 0.22
                let activeRange = size.height * (0.28 + 0.58 * clampedLevel)
                let strokeColor = clampedLevel > 0.03 ? tint : TunerTheme.muted.opacity(0.45)

                for index in 0..<count {
                    let progress = Double(index) / Double(max(1, count - 1))
                    let primary = abs(sin(progress * .pi * 2.0 + phase))
                    let secondary = abs(sin(progress * .pi * 5.0 - phase * 0.72))
                    let mixed = 0.35 + 0.45 * primary + 0.20 * secondary
                    let height = clampedLevel > 0.015 ? max(mutedHeight, activeRange * mixed) : mutedHeight
                    let x = startX + CGFloat(index) * spacing
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: baseline - height / 2))
                    path.addLine(to: CGPoint(x: x, y: baseline + height / 2))
                    context.stroke(
                        path,
                        with: .color(strokeColor),
                        style: StrokeStyle(lineWidth: barWidth, lineCap: .round)
                    )
                }
            }
        }
        .accessibilityLabel("音频输入状态")
    }
}

struct CurrentSelectionPill: View {
    let string: PipaString
    var showsLabel = true

    var body: some View {
        HStack(spacing: 8) {
            if showsLabel {
                Text("当前选择")
                    .foregroundStyle(TunerTheme.muted)
            }
            Text(string.shortName)
                .fontWeight(.bold)
                .foregroundStyle(TunerTheme.gold)
            Text("· \(string.rawValue.replacingOccurrences(of: string.shortName, with: ""))")
                .foregroundStyle(TunerTheme.muted)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .tunerSurface(.badge, cornerRadius: 999)
        .frame(maxWidth: .infinity)
    }
}

struct AutoDetectionPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .foregroundStyle(TunerTheme.muted)
            }
            Text(displayValue)
                .fontWeight(.bold)
                .foregroundStyle(TunerTheme.gold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .tunerSurface(.badge, cornerRadius: 999)
    }

    private var displayValue: String {
        value == "等待判弦" ? "等待\n判弦" : value
    }
}

struct FloatingIconButton: View {
    let systemName: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(TunerTheme.panelRaised.opacity(0.92))
                )
                .overlay(
                    Circle()
                        .stroke(TunerTheme.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.32), radius: 13, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}
