import Foundation
import Testing
import ToneMateAppleAudio

private func measure(_ samples: [Float]) throws -> InputLevelMeasurement {
    try samples.withUnsafeBufferPointer { try InputLevelMeasurement(samples: $0) }
}

@Test func digitalSilenceIsDistinctFromMissingInput() throws {
    let result = try measure([0, -0.0, 0])
    #expect(result.sampleCount == 3)
    #expect(result.peakAmplitude == 0)
    #expect(result.rmsAmplitude == 0)
    #expect(result.rmsDBFS == nil)
    #expect(result.peakDBFS == nil)
    #expect(result.clippedFraction == 0)
    #expect(throws: InputLevelMeasurement.MeasurementError.emptyInput) {
        try measure([])
    }
}

@Test func constantInputHasKnownDigitalLevel() throws {
    let result = try measure([0.5, -0.5, 0.5, -0.5])
    #expect(result.peakAmplitude == 0.5)
    #expect(result.rmsAmplitude == 0.5)
    #expect(abs(try #require(result.rmsDBFS) - (-6.020599913279624)) < 1e-10)
    #expect(result.peakDBFS == result.rmsDBFS)
    #expect(result.clippedSampleCount == 0)
}

@Test(arguments: [44_100, 48_000])
func twoSecondHummingLevelAtSupportedRates(sampleRate: Int) throws {
    // Integer cycles provide an analytical RMS reference; this is unit-test
    // input, not a substitute for actual microphone or registry acceptance.
    let samples: [Float] = (0..<(sampleRate * 2)).map {
        Float(0.25 * sin(2 * Double.pi * 440 * Double($0) / Double(sampleRate)))
    }
    let result = try measure(samples)
    #expect(result.sampleCount == sampleRate * 2)
    #expect(abs(result.rmsAmplitude - 0.25 / sqrt(2)) < 1e-8)
    #expect(abs(try #require(result.rmsDBFS) - (-15.051499783199061)) < 1e-6)
    #expect(result.clippedSampleCount == 0)
}

@Test func clippingIncludesBothSignsAndPreservesOverRangeValues() throws {
    let result = try measure([1, -1, 1.5, -1.5, 0.5, -0.5, 0, 0])
    #expect(result.clippedSampleCount == 4)
    #expect(result.clippedFraction == 0.5)
    #expect(result.peakAmplitude == 1.5)
    #expect(try #require(result.peakDBFS) > 0)
    #expect(abs(result.rmsAmplitude - sqrt(7.0 / 8)) < 1e-12)
    let below = try measure([Float(1).nextDown, -Float(1).nextDown])
    #expect(below.clippedSampleCount == 0)
}

@Test(arguments: [Float.nan, Float.infinity, -Float.infinity])
func nonFiniteSamplesInvalidateTheWholeMeasurement(value: Float) {
    #expect(throws: InputLevelMeasurement.MeasurementError.nonFiniteSample(index: 1)) {
        try measure([0.5, value, 0.25])
    }
}

@Test func finiteFloatExtremesDoNotOverflowOrUnderflowTheAccumulator() throws {
    let loud = try measure([Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude])
    #expect(loud.rmsAmplitude.isFinite)
    #expect(loud.rmsAmplitude == Double(Float.greatestFiniteMagnitude))
    #expect(loud.clippedSampleCount == 2)
    let quiet = try measure([Float.leastNonzeroMagnitude])
    #expect(quiet.rmsAmplitude > 0)
    #expect(try #require(quiet.rmsDBFS).isFinite)
}

@Test func measurementsDoNotRetainOrModifySourceSamples() throws {
    var samples: [Float] = [0.25, -0.25]
    let first = try measure(samples)
    #expect(samples == [0.25, -0.25])
    for _ in 0..<100 { #expect(try measure(samples) == first) }
    samples[0] = 1
    #expect(first.peakAmplitude == 0.25)
    #expect(try measure(samples).clippedSampleCount == 1)
}
