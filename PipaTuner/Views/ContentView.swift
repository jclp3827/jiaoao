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
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 122)
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
                    .padding(.trailing, 20)
                    .padding(.bottom, 102)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            TunerActionBar(
                isListening: viewModel.isListening,
                isStarting: viewModel.isStartingAudio,
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
                TargetPitchCard(string: viewModel.activeString)
                ReadoutCard(viewModel: viewModel)
                ConfidenceCard(confidenceText: viewModel.confidenceText)
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
