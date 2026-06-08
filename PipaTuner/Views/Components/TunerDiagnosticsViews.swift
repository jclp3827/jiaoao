import SwiftUI

struct DiagnosticsCard: View {
    let diagnostics: TunerDiagnostics

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "诊断面板", subtitle: "用于真机排查拾音、采纳和锁定过程")

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 120), spacing: 12),
                        GridItem(.flexible(minimum: 120), spacing: 12)
                    ],
                    alignment: .leading,
                    spacing: 12
                ) {
                    DebugMetricTile(title: "当前弦", value: diagnostics.selectedStringName)
                    DebugMetricTile(title: "模式", value: diagnostics.tuningModeName)
                    DebugMetricTile(title: "目标频率", value: frequencyText(diagnostics.targetFrequency))
                    DebugMetricTile(title: "自动判弦", value: diagnostics.autoDetectedStringName ?? "--")
                    DebugMetricTile(title: "原始频率", value: optionalFrequency(diagnostics.rawFrequency))
                    DebugMetricTile(title: "原始置信度", value: optionalPercent(diagnostics.rawConfidence))
                    DebugMetricTile(title: "采纳频率", value: optionalFrequency(diagnostics.acceptedFrequency))
                    DebugMetricTile(title: "锁定频率", value: optionalFrequency(diagnostics.lockedFrequency))
                    DebugMetricTile(title: "偏差", value: optionalCents(diagnostics.centsOffset))
                    DebugMetricTile(title: "方向", value: diagnostics.direction)
                    DebugMetricTile(title: "活动帧", value: "\(diagnostics.activeFrameCount)")
                    DebugMetricTile(title: "采纳帧", value: "\(diagnostics.acceptedDetectionCount)")
                    DebugMetricTile(title: "状态", value: diagnostics.captureState)
                    DebugMetricTile(title: "监听", value: diagnostics.isListening ? "on" : "off")
                }

                snapshotSection(title: "本次拨弦快照", snapshot: diagnostics.currentPluckSnapshot)
                snapshotSection(title: "最近锁定快照", snapshot: diagnostics.lastLockedSnapshot)

                VStack(alignment: .leading, spacing: 6) {
                    Text("识别状态: \(diagnostics.statusText)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(TunerTheme.text)
                    Text("麦克风状态: \(diagnostics.microphoneText)")
                        .font(.footnote)
                        .foregroundStyle(TunerTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("最近采样")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(TunerTheme.text)

                    DiagnosticsHistoryRow(
                        title: "原始",
                        values: diagnostics.rawFrequencyHistory
                    )
                    DiagnosticsHistoryRow(
                        title: "采纳",
                        values: diagnostics.acceptedFrequencyHistory
                    )
                    DiagnosticsHistoryRow(
                        title: "锁定",
                        values: diagnostics.lockedFrequencyHistory
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("最近事件")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(TunerTheme.text)

                    DiagnosticsEventList(events: diagnostics.recentEvents)
                }

                if !diagnostics.autoCandidateSummary.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("自动候选")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(TunerTheme.text)

                        DiagnosticsEventList(events: diagnostics.autoCandidateSummary)
                    }
                }
            }
        }
    }

    private func frequencyText(_ value: Double) -> String {
        String(format: "%.1f Hz", value)
    }

    private func optionalFrequency(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }
        return frequencyText(value)
    }

    private func optionalPercent(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }
        return "\(Int((value * 100.0).rounded()))%"
    }

    private func optionalCents(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }
        return String(format: "%+.1f", value)
    }

    @ViewBuilder
    private func snapshotSection(title: String, snapshot: TuningSnapshot?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(TunerTheme.text)

            if let snapshot {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 120), spacing: 12),
                        GridItem(.flexible(minimum: 120), spacing: 12)
                    ],
                    alignment: .leading,
                    spacing: 12
                ) {
                    DebugMetricTile(title: "弦", value: snapshot.selectedStringName)
                    DebugMetricTile(title: "模式", value: snapshot.tuningModeName)
                    DebugMetricTile(title: "自动判弦", value: snapshot.autoDetectedStringName ?? "--")
                    DebugMetricTile(title: "状态", value: snapshot.captureState)
                    DebugMetricTile(title: "目标", value: frequencyText(snapshot.targetFrequency))
                    DebugMetricTile(title: "原始", value: optionalFrequency(snapshot.rawFrequency))
                    DebugMetricTile(title: "采纳", value: optionalFrequency(snapshot.acceptedFrequency))
                    DebugMetricTile(title: "锁定", value: optionalFrequency(snapshot.lockedFrequency))
                    DebugMetricTile(title: "偏差", value: optionalCents(snapshot.centsOffset))
                    DebugMetricTile(title: "方向", value: snapshot.direction)
                }
            } else {
                Text("暂无数据")
                    .font(.footnote)
                    .foregroundStyle(TunerTheme.muted)
            }
        }
    }
}

struct DiagnosticsHistoryRow: View {
    let title: String
    let values: [Double]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TunerTheme.muted)
                .frame(width: 36, alignment: .leading)

                Text(historyText)
                .tunerMetricText(size: 13, weight: .medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .tunerSurface(.inset, cornerRadius: 16)
    }

    private var historyText: String {
        guard !values.isEmpty else {
            return "--"
        }

        return values
            .map { String(format: "%.1f", $0) }
            .joined(separator: "  ")
    }
}

struct DiagnosticsEventList: View {
    let events: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if events.isEmpty {
                Text("--")
                    .tunerMetricText(size: 13, weight: .medium, tone: .muted)
            } else {
                ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                    Text(event)
                        .tunerMetricText(size: 13, weight: .medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
        .tunerSurface(.inset, cornerRadius: 16)
    }
}

struct DebugMetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TunerTheme.muted)
            Text(value)
                .tunerMetricText(size: 16, weight: .bold)
                .tunerSingleLine(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .tunerSurface(.inset, cornerRadius: 16)
    }
}
