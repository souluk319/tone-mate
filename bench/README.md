# Pitch baseline (#2)

```sh
cmake -S bench -B build/pitch-baseline -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/pitch-baseline
ctest --test-dir build/pitch-baseline --output-on-failure
build/pitch-baseline/pitch_baseline --csv > build/pitch-baseline/frames.csv
```

Seed 1470; 4096-sample frames; 44.1/48 kHz; MIDI 36–84 plus 65/1047 Hz;
sine and 1:0.5:0.25 harmonic tones; −36/−24/−12 dBFS peak; five phases.
This generates 3060 clean frames in memory, not recorded user audio. Each row
contains its truth/configuration. PCM regeneration is checked exactly within
the same executable; cross-platform libm bit identity is not claimed.

Every sample-rate/band must have zero missing estimates, median absolute error
≤5 cents, nearest-rank p95 ≤15 cents and octave-or-gross error rate <0.2%.
Errors ≥600 cents conservatively count toward that last rate. Failed estimates
are counted separately and fail the run rather than disappearing from metrics.
100 exact replays cover A notes 110/220/440/880 Hz at both rates, waveforms and
amplitudes; unit tests additionally replay the 65/1047 Hz edges.

This is only the synthetic clean subset of TV-003/006/016. Real voices, noisy
signals, streaming timing, microphone/device performance and ChainShield #1470
remain unverified. YIN is a baseline candidate, not the final algorithm choice.
Algorithm reference: de Cheveigné & Kawahara (2002), [YIN](https://doi.org/10.1121/1.1458024).
