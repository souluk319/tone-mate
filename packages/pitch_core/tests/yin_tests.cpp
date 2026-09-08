#include "tonemate/pitch_core.h"
#include <array>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <numbers>

void check(bool value, const char* message) {
  if (!value) { std::cerr << message << '\n'; std::exit(1); }
}

int main() {
  check(!tonemate_pitch_detector_create(0), "zero sample rate");
  check(!tonemate_pitch_detector_create(96000), "unsupported sample rate");
  check(!tonemate_pitch_detector_create(-44100), "negative sample rate");
  tonemate_pitch_detector_destroy(nullptr);
  for (int rate : {44100, 48000}) {
    auto* detector = tonemate_pitch_detector_create(rate);
    check(detector != nullptr, "create");
    std::array<float, TONEMATE_PITCH_FRAME_SIZE> samples{};
    tonemate_pitch_result result{440, 1};
    auto process = [&] { return tonemate_pitch_detector_process(
        detector, samples.data(), samples.size(), &result); };
    check(process() == TONEMATE_PITCH_UNVOICED, "silence");
    check(result.frequency_hz == 0 && result.periodicity == 0, "clear stale result");
    samples.fill(0.25f);
    check(process() == TONEMATE_PITCH_UNVOICED, "DC");
    for (float bad : {std::numeric_limits<float>::quiet_NaN(),
                      std::numeric_limits<float>::infinity(), 1.01f, -1.01f}) {
      samples.back() = bad;
      check(process() == TONEMATE_PITCH_INVALID_INPUT, "invalid PCM");
    }
    check(tonemate_pitch_detector_process(detector, nullptr, samples.size(), &result)
          == TONEMATE_PITCH_INVALID_INPUT, "null PCM");
    check(tonemate_pitch_detector_process(nullptr, samples.data(), samples.size(), &result)
          == TONEMATE_PITCH_INVALID_INPUT, "null detector");
    check(tonemate_pitch_detector_process(detector, samples.data(), samples.size(), nullptr)
          == TONEMATE_PITCH_INVALID_INPUT, "null result");
    for (int count : {-1, 0, 4095, 4097})
      check(tonemate_pitch_detector_process(detector, samples.data(), count, &result)
            == TONEMATE_PITCH_INVALID_INPUT, "wrong frame size");
    for (double frequency : {65.0, 110.0, 220.0, 440.0, 1047.0}) {
      for (size_t i = 0; i < samples.size(); ++i)
        samples[i] = 0.25 * std::sin(2 * std::numbers::pi * frequency * i / rate);
      const auto status = process();
      if (status != TONEMATE_PITCH_OK)
        std::cerr << "rate=" << rate << " frequency=" << frequency << " status=" << status << '\n';
      check(status == TONEMATE_PITCH_OK, "clean tone detected");
      check(std::abs(tonemate_cents_between(result.frequency_hz, frequency)) <= 5,
            "clean tone accuracy");
      const auto first = result;
      for (int repeat = 0; repeat < 100; ++repeat) {
        check(process() == TONEMATE_PITCH_OK, "replay status");
        check(result.frequency_hz == first.frequency_hz && result.periodicity == first.periodicity,
              "100 replays exactly deterministic");
      }
      samples.back() = std::numeric_limits<float>::quiet_NaN();
      check(process() == TONEMATE_PITCH_INVALID_INPUT, "invalid input after valid tone");
      check(result.frequency_hz == 0 && result.periodicity == 0, "no stale valid pitch");
    }
    tonemate_pitch_detector_destroy(detector);
  }
  std::cout << "YIN input, accuracy and 100-replay checks passed\n";
}
