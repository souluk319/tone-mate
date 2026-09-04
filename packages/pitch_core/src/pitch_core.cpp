#include "tonemate/pitch_core.h"

#include <cmath>
#include <limits>

namespace {

constexpr double kA4FrequencyHz = 440.0;
constexpr double kA4MidiNote = 69.0;
constexpr double kSemitonesPerOctave = 12.0;
constexpr double kCentsPerOctave = 1200.0;

double invalid_result() {
  return std::numeric_limits<double>::quiet_NaN();
}

bool is_positive_finite(double value) {
  return std::isfinite(value) && value > 0.0;
}

}  // namespace

int32_t tonemate_pitch_core_abi_version(void) {
  return TONEMATE_PITCH_CORE_ABI_VERSION;
}

double tonemate_midi_to_frequency(double midi_note) {
  if (!std::isfinite(midi_note)) {
    return invalid_result();
  }
  return kA4FrequencyHz *
         std::exp2((midi_note - kA4MidiNote) / kSemitonesPerOctave);
}

double tonemate_frequency_to_midi(double frequency_hz) {
  if (!is_positive_finite(frequency_hz)) {
    return invalid_result();
  }
  return kA4MidiNote +
         kSemitonesPerOctave * std::log2(frequency_hz / kA4FrequencyHz);
}

double tonemate_cents_between(double frequency_hz, double reference_hz) {
  if (!is_positive_finite(frequency_hz) ||
      !is_positive_finite(reference_hz)) {
    return invalid_result();
  }
  return kCentsPerOctave * std::log2(frequency_hz / reference_hz);
}
