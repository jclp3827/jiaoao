import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TunerViewModel()

    var body: some View {
        ZStack {
            TunerTheme.background
                .ignoresSafeArea()

            PipaBackdrop(activeString: viewModel.activeString)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
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
                .padding(.horizontal, 15)
                .padding(.top, 6)
                .padding(.bottom, 156)
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
                    .padding(.trailing, 15)
                    .padding(.bottom, 142)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            TunerHeader(
                tuningMode: viewModel.tuningMode
            )
            .padding(.horizontal, 15)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [
                        TunerTheme.ink,
                        TunerTheme.ink.opacity(0.92),
                        Color.black.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .safeAreaInset(edge: .bottom) {
            TunerActionBar(
                tuningMode: viewModel.tuningMode,
                selectedString: $viewModel.selectedString,
                displayString: viewModel.tuningMode == .manual ? viewModel.selectedString : viewModel.activeString,
                isListening: viewModel.isListening,
                isStarting: viewModel.isStartingAudio,
                resultStatusText: primaryStatusText,
                microphoneStatusText: viewModel.microphoneStatusText,
                activityLevel: viewModel.inputActivityLevel,
                tint: statusColor,
                toggleTuningMode: viewModel.toggleTuningMode,
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
        HStack(alignment: .center, spacing: 16) {
            VStack(spacing: 16) {
                DeviationMeterCard(centsOffset: viewModel.centsOffset, centsText: viewModel.centsText, statusColor: statusColor)
            }
            .frame(width: 224)

            PipaHeroStage(string: viewModel.activeString, statusColor: statusColor)
                .frame(maxWidth: .infinity, minHeight: 628)

            VStack(spacing: 16) {
                ReadoutCard(viewModel: viewModel, statusColor: statusColor)
                ConfidenceCard(
                    confidenceText: viewModel.confidenceText,
                    statusColor: statusColor,
                    isActive: viewModel.detectedFrequencyText != "--"
                )
                AudioStatusCard(level: viewModel.inputActivityLevel, statusText: viewModel.recognitionStatusText, tint: statusColor)
            }
            .frame(width: 264)
        }
    }

    private var compactLayout: some View {
        CompactDashboard(
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
