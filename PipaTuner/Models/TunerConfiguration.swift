import AVFoundation
import Foundation

enum TunerConfiguration {
    enum Build {
        static let isDevelopment: Bool = {
            #if TUNER_DEVELOPMENT
            true
            #else
            false
            #endif
        }()

        static let isProduction: Bool = !isDevelopment
    }
}

extension TunerConfiguration {
    enum AudioInput {
        static let preferredSampleRate = 44_100.0
        static let tapBufferSize: AVAudioFrameCount = 8192
        static let activeFrameLevel = 0.024
        static let activityNormalizationLevel = 0.018
        static let peakNormalizationLevel = 0.055
    }

    enum PitchDetection {
        static let minimumFrequency = 60.0
        static let maximumFrequency = 1_200.0
        static let silenceRMS = 0.0015
        static let yinThreshold = 0.16
        static let candidateThreshold = 0.26
        static let minimumConfidence = 0.18
    }

    enum Tuning {
        static let inTuneThresholdCents = 12.0
        static let centsDisplayRange = 1_200.0
        static let centsStableWindow = 45.0
        static let centsOctaveUnit = 1_200.0
        static let weightingFloor = 0.01
        static let maxAcceptedDetectionsPerPluck = 6
        static let manualMaximumRawFrequencyMultiplier = 2.2
    }

    enum Harmonics {
        static let divisors = [1.0, 2.0, 3.0, 4.0]
        static let multipliers = [1.0]
        static let harmonicMatchWindowCents = 260.0
        static let harmonicPenalty = 70.0
        static let subharmonicPenalty = 90.0
        static let yinPenaltyScale = 180.0
    }

    enum Diagnostics {
        static let historyLimit = 10
        static let eventLimit = 12
        static var isEnabled: Bool {
            Build.isDevelopment
        }

        static var showsEntryButton: Bool {
            isEnabled
        }

        static var showsPanel: Bool {
            isEnabled
        }
    }

    enum AutoClassification {
        static let divisorPenalty = 35.0
        static let multiplierPenalty = 220.0
        static let primaryBandPenalty = 260.0
        static let lowRawPrimaryBandPenalty = 760.0
        static let selectedStringPriorBonus = 220.0
        static let decisiveScoreGap = 180.0
        static let decisiveRawCentsWindow = 160.0
        static let recaptureScoreMargin = 120.0
        static let primaryBandUpperMultiplier = 1.08
        static let primaryBandLowerMultiplier = 0.55
    }
}
