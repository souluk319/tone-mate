import Testing
@testable import ToneMateAppleAudio

@Test func voiceDefaultIsMono48K() {
    let configuration = AudioCaptureConfiguration.voiceDefault
    #expect(configuration.sampleRate == 48_000)
    #expect(configuration.channelCount == 1)
    #expect(configuration.framesPerBuffer == 512)
}

@Test func configurationRejectsInvalidValues() {
    #expect(throws: AudioCaptureConfiguration.ValidationError.self) {
        try AudioCaptureConfiguration(
            sampleRate: 0,
            channelCount: 1,
            framesPerBuffer: 512
        )
    }
    #expect(throws: AudioCaptureConfiguration.ValidationError.self) {
        try AudioCaptureConfiguration(
            sampleRate: 48_000,
            channelCount: 3,
            framesPerBuffer: 512
        )
    }
    #expect(throws: AudioCaptureConfiguration.ValidationError.self) {
        try AudioCaptureConfiguration(
            sampleRate: 48_000,
            channelCount: 1,
            framesPerBuffer: 511
        )
    }
}

@Test func timingAdvancesWithoutChangingFrameLength() {
    let start = AudioFrameTiming(hostTime: 10, sampleTime: 1_024, frameLength: 512)
    let next = start.advanced(by: 512)
    #expect(next.hostTime == 10)
    #expect(next.sampleTime == 1_536)
    #expect(next.frameLength == 512)
}
