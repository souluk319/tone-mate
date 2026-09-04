/// Allocation-free timing metadata that can cross the capture-to-analysis
/// boundary without carrying or retaining raw voice samples.
public struct AudioFrameTiming: Equatable, Sendable {
    public let hostTime: UInt64
    public let sampleTime: Int64
    public let frameLength: Int

    public init(hostTime: UInt64, sampleTime: Int64, frameLength: Int) {
        self.hostTime = hostTime
        self.sampleTime = sampleTime
        self.frameLength = frameLength
    }

    public func advanced(by frames: Int) -> AudioFrameTiming {
        AudioFrameTiming(
            hostTime: hostTime,
            sampleTime: sampleTime + Int64(frames),
            frameLength: frameLength
        )
    }
}
