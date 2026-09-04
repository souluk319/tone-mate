/// Validated configuration shared by ToneMate's Apple audio capture lanes.
///
/// This value is prepared before an audio callback starts. The callback must
/// not allocate, block, perform I/O, or construct this value.
public struct AudioCaptureConfiguration: Equatable, Sendable {
    public enum ValidationError: Error, Equatable, Sendable {
        case unsupportedSampleRate(Double)
        case unsupportedChannelCount(Int)
        case unsupportedFramesPerBuffer(Int)
    }

    public let sampleRate: Double
    public let channelCount: Int
    public let framesPerBuffer: Int

    public init(
        sampleRate: Double,
        channelCount: Int,
        framesPerBuffer: Int
    ) throws {
        guard sampleRate.isFinite, (8_000...192_000).contains(sampleRate) else {
            throw ValidationError.unsupportedSampleRate(sampleRate)
        }
        guard (1...2).contains(channelCount) else {
            throw ValidationError.unsupportedChannelCount(channelCount)
        }
        guard (64...8_192).contains(framesPerBuffer),
              framesPerBuffer.isMultiple(of: 2) else {
            throw ValidationError.unsupportedFramesPerBuffer(framesPerBuffer)
        }
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.framesPerBuffer = framesPerBuffer
    }

    public static let voiceDefault = try! AudioCaptureConfiguration(
        sampleRate: 48_000,
        channelCount: 1,
        framesPerBuffer: 512
    )
}
