# ToneMateAppleAudio

ToneMate's Apple audio module. Registry identity: `tonemate.apple-audio`;
prepared Swift release: `0.1.0-alpha.2`. Requires Swift 6.0, iOS 15/macOS 13.

`InputLevelMeasurement` supplies the digital input-level and clipping measurements
needed by ENV-02/03. On the analysis worker, pass one channel of normalized Float
PCM using `InputLevelMeasurement(samples: channelBuffer)`. The buffer must remain
valid and unchanged until the call returns; samples are not retained or sent
anywhere. Output contains sample count, peak/RMS amplitude, dBFS and the count
and fraction of samples whose absolute amplitude is at least 1. Values beyond
full scale are preserved, not silently clamped. For stereo, measure channels
separately so cancellation cannot hide clipping.

Empty input and non-finite samples throw. Exact digital silence has amplitude
zero and `nil` dBFS. Digital levels are not calibrated SPL, voice detection or
an environment pass/fail decision. No microphone capture, Flutter integration
or device validation is included yet. Do not invoke measurement in the audio
callback; the capture-to-worker handoff remains a separate implementation step.

Existing `AudioCaptureConfiguration` and `AudioFrameTiming` APIs remain available.

```sh
swift test --package-path packages/apple_audio
bash scripts/build-swift-package.sh
```

The packaging command requires a clean commit and refuses to overwrite an
existing release directory. It produces the source ZIP and coordinate/digest
manifest under `dist/hosted-upload/swift-0.1.0-alpha.2/`. It does not publish to
Cloudsmith, Gitea or ChainShield. Packaging and local tests are not #1470 PASS.
