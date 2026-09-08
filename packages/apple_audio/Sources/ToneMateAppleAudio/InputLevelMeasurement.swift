import Foundation

/// Raw digital input levels for ENV-02/03. Measure one channel on the analysis
/// worker, not in the audio callback. Samples are borrowed and never retained.
/// These values are not calibrated sound pressure, VAD, or a pass/fail verdict.
public struct InputLevelMeasurement: Equatable, Sendable {
    public enum MeasurementError: Error, Equatable, Sendable {
        case emptyInput
        case nonFiniteSample(index: Int)
    }

    public let sampleCount: Int
    public let peakAmplitude: Double
    public let rmsAmplitude: Double
    /// Count of samples at or beyond digital full scale, including both signs.
    public let clippedSampleCount: Int

    public var clippedFraction: Double {
        Double(clippedSampleCount) / Double(sampleCount)
    }

    /// nil denotes exact digital silence, rather than a fabricated noise floor.
    public var rmsDBFS: Double? {
        rmsAmplitude > 0 ? 20 * log10(rmsAmplitude) : nil
    }

    public var peakDBFS: Double? {
        peakAmplitude > 0 ? 20 * log10(peakAmplitude) : nil
    }

    public init(samples: UnsafeBufferPointer<Float>) throws {
        guard !samples.isEmpty else { throw MeasurementError.emptyInput }
        var peak = 0.0
        var sumOfSquares = 0.0
        var clipped = 0
        for index in samples.indices {
            let value = Double(samples[index])
            guard value.isFinite else {
                throw MeasurementError.nonFiniteSample(index: index)
            }
            let magnitude = abs(value)
            peak = max(peak, magnitude)
            sumOfSquares += value * value
            if magnitude >= 1 { clipped += 1 }
        }
        sampleCount = samples.count
        peakAmplitude = peak
        rmsAmplitude = sqrt(sumOfSquares / Double(samples.count))
        clippedSampleCount = clipped
    }
}
