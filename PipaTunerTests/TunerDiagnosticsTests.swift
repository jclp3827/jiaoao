import XCTest
@testable import PipaTuner

extension PipaTunerTests {
    @MainActor
    func testDiagnosticsToggleUpdatesVisibilityState() {
        let viewModel = TunerViewModel()

        XCTAssertFalse(viewModel.showsDiagnostics)

        viewModel.toggleDiagnostics()
        XCTAssertTrue(viewModel.showsDiagnostics)

        viewModel.toggleDiagnostics()
        XCTAssertFalse(viewModel.showsDiagnostics)
    }

    @MainActor
    func testDiagnosticsCaptureManualRawAcceptedAndLockedValues() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        sendDetectedFrame(frequency: 400.0, confidence: 0.91, rms: 0.16, activity: 0.7, to: viewModel)

        XCTAssertEqual(viewModel.diagnostics.selectedStringName, PipaString.first.shortName)
        XCTAssertEqual(viewModel.diagnostics.rawFrequency ?? 0, 400.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequency ?? 0, 400.0, accuracy: 0.5)
        XCTAssertEqual(viewModel.diagnostics.captureState, "active")
        XCTAssertEqual(viewModel.diagnostics.acceptedDetectionCount, 1)
        XCTAssertEqual(viewModel.diagnostics.rawFrequencyHistory.count, 1)
        XCTAssertEqual(viewModel.diagnostics.rawFrequencyHistory.first ?? 0, 400.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequencyHistory.count, 1)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequencyHistory.first ?? 0, 400.0, accuracy: 0.5)

        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.diagnostics.lockedFrequency ?? 0, 400.0, accuracy: 0.5)
        XCTAssertEqual(viewModel.diagnostics.captureState, "locked")
        XCTAssertEqual(viewModel.diagnostics.direction, TuningDirection.sharp.rawValue)
        XCTAssertEqual(viewModel.diagnostics.lockedFrequencyHistory.count, 1)
        XCTAssertEqual(viewModel.diagnostics.lockedFrequencyHistory.first ?? 0, 400.0, accuracy: 0.5)
        XCTAssertTrue(viewModel.diagnostics.recentEvents.contains(where: { $0.contains("原始 400.0 Hz") }))
        XCTAssertTrue(viewModel.diagnostics.recentEvents.contains(where: { $0.contains("原始采纳 400.0 Hz") }))
        XCTAssertTrue(viewModel.diagnostics.recentEvents.contains(where: { $0.contains("本次锁定 400.0 Hz") }))
        XCTAssertEqual(viewModel.diagnostics.currentPluckSnapshot?.lockedFrequency ?? 0, 400.0, accuracy: 0.5)
        XCTAssertEqual(viewModel.diagnostics.lastLockedSnapshot?.lockedFrequency ?? 0, 400.0, accuracy: 0.5)
    }

    @MainActor
    func testDiagnosticsKeepRawAndAssistedDetectionSeparated() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .fourth

        sendRawFrame(frequency: 180.0, confidence: 0.93, rms: 0.16, activity: 0.7, assistedFrequency: 220.0, assistedConfidence: 0.90, assistedRMS: 0.16, to: viewModel)
        finishPluck(on: viewModel)

        XCTAssertEqual(viewModel.diagnostics.rawFrequency ?? 0, 180.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequency ?? 0, 180.0, accuracy: 0.5)
        XCTAssertEqual(viewModel.diagnostics.lockedFrequency ?? 0, 180.0, accuracy: 0.5)
        XCTAssertTrue(viewModel.diagnostics.recentEvents.contains(where: { $0.contains("原始 180.0 Hz") }))
        XCTAssertTrue(viewModel.diagnostics.recentEvents.contains(where: { $0.contains("辅助 220.0 Hz") }))
    }

    @MainActor
    func testDiagnosticsHistoryCapsAtConfiguredLimit() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        for step in 0..<(TunerConfiguration.Diagnostics.historyLimit + 2) {
            let rawFrequency = 400.0 + Double(step)
            sendDetectedFrame(frequency: rawFrequency, confidence: 0.92, rms: 0.16, activity: 0.7, to: viewModel)
        }

        XCTAssertEqual(viewModel.diagnostics.rawFrequencyHistory.count, TunerConfiguration.Diagnostics.historyLimit)
        XCTAssertEqual(viewModel.diagnostics.acceptedFrequencyHistory.count, TunerConfiguration.Diagnostics.historyLimit)
        XCTAssertEqual(viewModel.diagnostics.rawFrequencyHistory.first ?? 0, 402.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.diagnostics.rawFrequencyHistory.last ?? 0, 411.0, accuracy: 0.001)
    }

    @MainActor
    func testChangingStringClearsDiagnosticsHistory() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        sendDetectedFrame(frequency: 400.0, confidence: 0.91, rms: 0.16, activity: 0.7, to: viewModel)
        finishPluck(on: viewModel)

        XCTAssertFalse(viewModel.diagnostics.rawFrequencyHistory.isEmpty)
        XCTAssertFalse(viewModel.diagnostics.acceptedFrequencyHistory.isEmpty)
        XCTAssertFalse(viewModel.diagnostics.lockedFrequencyHistory.isEmpty)
        XCTAssertFalse(viewModel.diagnostics.recentEvents.isEmpty)

        viewModel.selectedString = .third

        XCTAssertTrue(viewModel.diagnostics.rawFrequencyHistory.isEmpty)
        XCTAssertTrue(viewModel.diagnostics.acceptedFrequencyHistory.isEmpty)
        XCTAssertTrue(viewModel.diagnostics.lockedFrequencyHistory.isEmpty)
        XCTAssertTrue(viewModel.diagnostics.recentEvents.isEmpty)
    }

    @MainActor
    func testDiagnosticsEventListRecordsRejectedFrames() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        sendRejectedFrame(reason: .noCandidate, activity: 0.7, to: viewModel)

        XCTAssertEqual(viewModel.diagnostics.recentEvents.last, "未找到稳定候选音高")
    }

    @MainActor
    func testDiagnosticsEventListCapsAtConfiguredLimit() {
        let viewModel = TunerViewModel()
        viewModel.selectedString = .first

        for _ in 0..<(TunerConfiguration.Diagnostics.eventLimit + 3) {
            sendRejectedFrame(reason: .noCandidate, activity: 0.7, to: viewModel)
        }

        XCTAssertEqual(viewModel.diagnostics.recentEvents.count, TunerConfiguration.Diagnostics.eventLimit)
    }

    func testDiagnosticsRecordsAudioLifecycleEvents() {
        let reporter = TunerDiagnosticsReporter()
        var diagnostics = TunerDiagnostics()

        reporter.recordAudioLifecycleEvent(.startRequested, in: &diagnostics)
        reporter.recordAudioLifecycleEvent(.permissionGranted, in: &diagnostics)
        reporter.recordAudioLifecycleEvent(.startSucceeded, in: &diagnostics)
        reporter.recordAudioLifecycleEvent(.stopRequested, in: &diagnostics)

        XCTAssertEqual(diagnostics.recentEvents, [
            "音频: 请求启动",
            "音频: 麦克风权限已允许",
            "音频: 启动成功",
            "音频: 停止监听"
        ])
    }
}
