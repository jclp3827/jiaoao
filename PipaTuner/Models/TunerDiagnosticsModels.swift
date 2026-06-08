import Foundation

enum TunerDiagnosticsCaptureState {
    static let idle = "idle"
    static let active = "active"
    static let locked = "locked"
    static let unstable = "unstable"
}

struct AudioAnalysisFrame {
    let rawDetection: PitchDetectionResult?
    let assistedDetection: PitchDetectionResult?
    let activityLevel: Double
    let rawAnalysisReason: PitchAnalysisReason
    let assistedAnalysisReason: PitchAnalysisReason?

    init(
        detection: PitchDetectionResult?,
        activityLevel: Double,
        analysisReason: PitchAnalysisReason = .success
    ) {
        self.rawDetection = detection
        self.assistedDetection = nil
        self.activityLevel = activityLevel
        self.rawAnalysisReason = analysisReason
        self.assistedAnalysisReason = nil
    }

    init(
        rawDetection: PitchDetectionResult?,
        assistedDetection: PitchDetectionResult? = nil,
        activityLevel: Double,
        rawAnalysisReason: PitchAnalysisReason = .success,
        assistedAnalysisReason: PitchAnalysisReason? = nil
    ) {
        self.rawDetection = rawDetection
        self.assistedDetection = assistedDetection
        self.activityLevel = activityLevel
        self.rawAnalysisReason = rawAnalysisReason
        self.assistedAnalysisReason = assistedAnalysisReason
    }
}

struct TunerDiagnostics: Equatable {
    var tuningModeName: String = TuningMode.manual.title
    var selectedStringName: String = PipaString.first.shortName
    var targetFrequency: Double = PipaString.first.targetFrequency
    var autoDetectedStringName: String?
    var autoCandidateSummary: [String] = []
    var rawFrequency: Double?
    var rawConfidence: Double?
    var rawFrequencyHistory: [Double] = []
    var acceptedFrequency: Double?
    var acceptedConfidence: Double?
    var acceptedFrequencyHistory: [Double] = []
    var lockedFrequency: Double?
    var lockedConfidence: Double?
    var lockedFrequencyHistory: [Double] = []
    var detectedFrequency: Double?
    var centsOffset: Double?
    var direction: String = TuningDirection.silent.rawValue
    var activityLevel: Double = 0
    var activeFrameCount: Int = 0
    var acceptedDetectionCount: Int = 0
    var captureState: String = TunerDiagnosticsCaptureState.idle
    var statusText: String = "未开始"
    var microphoneText: String = "麦克风尚未启动"
    var isListening: Bool = false
    var recentEvents: [String] = []
    var currentPluckSnapshot: TuningSnapshot?
    var lastLockedSnapshot: TuningSnapshot?
}

struct AutoStringCandidate: Equatable {
    let string: PipaString
    let normalizedFrequency: Double
    let confidence: Double
    let centsDistance: Double
    let rawCentsDistance: Double
    let normalizationPenalty: Double
    let classificationScore: Double
}

struct AutoStringClassification: Equatable {
    let bestCandidate: AutoStringCandidate
    let rankedCandidates: [AutoStringCandidate]
    let primaryBandString: PipaString?
}

struct TuningSnapshot: Equatable {
    var selectedStringName: String
    var targetFrequency: Double
    var tuningModeName: String
    var autoDetectedStringName: String?
    var rawFrequency: Double?
    var rawConfidence: Double?
    var acceptedFrequency: Double?
    var acceptedConfidence: Double?
    var lockedFrequency: Double?
    var lockedConfidence: Double?
    var detectedFrequency: Double?
    var centsOffset: Double?
    var direction: String = TuningDirection.silent.rawValue
    var captureState: String
}
