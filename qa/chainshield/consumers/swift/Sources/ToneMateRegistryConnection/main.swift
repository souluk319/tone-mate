import ToneMateAppleAudio

let configuration = AudioCaptureConfiguration.voiceDefault
precondition(configuration.sampleRate == 48_000 && configuration.channelCount == 1)
print("ToneMateAppleAudio registry import OK: mono, \(configuration.sampleRate) Hz")
