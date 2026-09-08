#include "tonemate/pitch_core.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <memory>
#include <numbers>
#include <string>
#include <vector>

namespace {
constexpr uint32_t seed = 1470;
using Frame = std::array<float, TONEMATE_PITCH_FRAME_SIZE>;
Frame synthesize(int rate, double hz, int db, bool harmonics, uint32_t phase_seed) {
  // Specified integer LCG, no platform-dependent random distribution.
  const uint32_t phase_bits = phase_seed * 1664525u + 1013904223u;
  const double phase = 2 * std::numbers::pi * (phase_bits / 4294967296.0);
  const double amplitude = std::pow(10.0, db / 20.0);
  Frame frame{};
  for (size_t i = 0; i < frame.size(); ++i) {
    const double angle = 2 * std::numbers::pi * hz * i / rate + phase;
    const double value = harmonics
        ? (std::sin(angle) + 0.5 * std::sin(2 * angle) + 0.25 * std::sin(3 * angle)) / 1.75
        : std::sin(angle);
    frame[i] = static_cast<float>(amplitude * value);
  }
  return frame;
}
struct Metrics {
  std::vector<double> errors;
  size_t missing = 0;
  size_t octave_or_gross = 0;
};
int band(double hz) {
  if (hz < 110) return 0;
  if (hz < 220) return 1;
  if (hz < 440) return 2;
  return 3;
}
}

int main(int argc, char** argv) {
  const bool csv = argc == 2 && std::string(argv[1]) == "--csv";
  if (argc > 1 && !csv) { std::cerr << "usage: pitch_baseline [--csv]\n"; return 2; }
  std::vector<double> frequencies{65, 1047};
  for (int midi = 36; midi <= 84; ++midi)
    frequencies.push_back(tonemate_midi_to_frequency(midi));
  std::sort(frequencies.begin(), frequencies.end());
  std::array<Metrics, 8> metrics;
  size_t count = 0;
  bool deterministic = true;
  if (csv) std::cout << "rate,hz,dbfs,wave,phase_seed,status,estimated_hz,abs_cents\n";
  std::cout.precision(17);
  int rate_index = 0;
  for (int rate : {44100, 48000}) {
    std::unique_ptr<tonemate_pitch_detector, decltype(&tonemate_pitch_detector_destroy)>
        detector(tonemate_pitch_detector_create(rate), tonemate_pitch_detector_destroy);
    if (!detector) { std::cerr << "detector allocation failed\n"; return 1; }
    for (double hz : frequencies) for (int db : {-36, -24, -12})
      for (bool harmonics : {false, true}) for (uint32_t phase = 0; phase < 5; ++phase) {
        const uint32_t phase_seed = seed + phase * 2654435761u;
        const auto pcm = synthesize(rate, hz, db, harmonics, phase_seed);
        deterministic &= pcm == synthesize(rate, hz, db, harmonics, phase_seed);
        tonemate_pitch_result result{};
        const auto status = tonemate_pitch_detector_process(detector.get(), pcm.data(), pcm.size(), &result);
        auto& m = metrics[rate_index * 4 + band(hz)];
        double error = 0;
        if (status != TONEMATE_PITCH_OK || !std::isfinite(result.frequency_hz)
            || result.frequency_hz <= 0) {
          ++m.missing;
        } else {
          error = std::abs(tonemate_cents_between(result.frequency_hz, hz));
          m.errors.push_back(error);
          // Conservative: every error >= half an octave counts, not only exact octave slips.
          m.octave_or_gross += error >= 600;
        }
        // Every waveform/amplitude/rate at A notes (110/220/440/880), phase 0.
        if (phase == 0 && (hz == 110 || hz == 220 || hz == 440 || hz == 880)) {
          for (int repeat = 0; repeat < 100; ++repeat) {
            tonemate_pitch_result replay{};
            const auto replay_status = tonemate_pitch_detector_process(
                detector.get(), pcm.data(), pcm.size(), &replay);
            deterministic &= replay_status == status && replay.frequency_hz == result.frequency_hz
                && replay.periodicity == result.periodicity;
          }
        }
        if (csv) std::cout << rate << ',' << hz << ',' << db << ','
            << (harmonics ? "harmonic" : "sine") << ',' << phase_seed << ',' << status << ','
            << result.frequency_hz << ',' << (status == TONEMATE_PITCH_OK ? std::to_string(error) : "NA") << '\n';
        ++count;
      }
    ++rate_index;
  }
  const char* bands[] = {"[65,110)", "[110,220)", "[220,440)", "[440,1047]"};
  bool passed = deterministic;
  for (size_t i = 0; i < metrics.size(); ++i) {
    auto& m = metrics[i];
    std::sort(m.errors.begin(), m.errors.end());
    const size_t n = m.errors.size();
    const double median = n ? (m.errors[(n - 1) / 2] + m.errors[n / 2]) / 2 : INFINITY;
    const double p95 = n ? m.errors[static_cast<size_t>(std::ceil(n * 0.95)) - 1] : INFINITY;
    const double octave_rate = n ? static_cast<double>(m.octave_or_gross) / n : 1;
    const bool gate = m.missing == 0 && median <= 5 && p95 <= 15 && octave_rate < 0.002;
    passed &= gate;
    std::cerr << (i < 4 ? 44100 : 48000) << " Hz " << bands[i % 4]
              << " n=" << n << " missing=" << m.missing << " median=" << median
              << " p95=" << p95 << " octave_or_gross=" << octave_rate * 100 << "% "
              << (gate ? "PASS" : "FAIL") << '\n';
  }
  std::cerr << "seed=" << seed << " frames=" << count << " deterministic=" << deterministic
            << " result=" << (passed ? "PASS" : "FAIL") << '\n';
  return passed ? 0 : 1;
}
