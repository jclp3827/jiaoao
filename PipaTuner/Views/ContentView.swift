import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TunerViewModel()

    var body: some View {
        ZStack {
            TunerTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TunerHeader(
                        tuningMode: viewModel.tuningMode,
                        toggleTuningMode: viewModel.toggleTuningMode
                    )
                    TunerDashboard(
                        viewModel: viewModel,
                        tuningMode: $viewModel.tuningMode,
                        selectedString: $viewModel.selectedString,
                        statusColor: statusColor
                    )
                    if TunerConfiguration.Diagnostics.showsPanel && viewModel.showsDiagnostics {
                        DiagnosticsCard(diagnostics: viewModel.diagnostics)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 108)
            }
            .scrollIndicators(.hidden)

            if TunerConfiguration.Diagnostics.showsEntryButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingDiagnosticsButton(
                            showsDiagnostics: viewModel.showsDiagnostics,
                            action: viewModel.toggleDiagnostics
                        )
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 94)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            TunerActionBar(
                isListening: viewModel.isListening,
                isStarting: viewModel.isStartingAudio,
                resultStatusText: primaryStatusText,
                microphoneStatusText: viewModel.microphoneStatusText,
                activityLevel: viewModel.inputActivityLevel,
                tint: statusColor,
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

    private var primaryStatusText: String {
        if viewModel.isStartingAudio {
            return viewModel.recognitionStatusText
        }
        return viewModel.detectedFrequencyText == "--" ? viewModel.recognitionStatusText : viewModel.directionText
    }
}

struct TunerDashboard: View {
    @ObservedObject var viewModel: TunerViewModel
    @Binding var tuningMode: TuningMode
    @Binding var selectedString: PipaString
    let statusColor: Color

    var body: some View {
        ViewThatFits(in: .horizontal) {
            wideLayout
            compactLayout
        }
    }

    private var wideLayout: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(spacing: 18) {
                StringPickerCard(selectedString: $selectedString, isEnabled: tuningMode == .manual)
                DeviationMeterCard(centsOffset: viewModel.centsOffset, centsText: viewModel.centsText, statusColor: statusColor)
            }
            .frame(width: 250)

            PipaHeroStage(string: viewModel.activeString, statusColor: statusColor)
                .frame(maxWidth: .infinity, minHeight: 650)

            VStack(spacing: 18) {
                ReadoutCard(viewModel: viewModel, statusColor: statusColor)
                ConfidenceCard(
                    confidenceText: viewModel.confidenceText,
                    statusColor: statusColor,
                    isActive: viewModel.detectedFrequencyText != "--"
                )
                AudioStatusCard(level: viewModel.inputActivityLevel, statusText: viewModel.recognitionStatusText, tint: statusColor)
            }
            .frame(width: 270)
        }
    }

    private var compactLayout: some View {
        HTMLStyleCompactDashboard(
            viewModel: viewModel,
            tuningMode: $tuningMode,
            selectedString: $selectedString,
            statusColor: statusColor
        )
    }
}

#Preview {
    ContentView()
}
