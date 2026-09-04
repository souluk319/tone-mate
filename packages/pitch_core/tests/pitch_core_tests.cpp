#include "tonemate/pitch_core.h"

#include <cassert>
#include <cmath>
#include <limits>

namespace {

bool near(double actual, double expected, double tolerance = 1e-9) {
  return std::abs(actual - expected) <= tolerance;
}

}  // namespace

int main() {
  assert(tonemate_pitch_core_abi_version() == 1);
  assert(near(tonemate_midi_to_frequency(69.0), 440.0));
  assert(near(tonemate_midi_to_frequency(60.0), 261.6255653005986));
  assert(near(tonemate_frequency_to_midi(440.0), 69.0));
  assert(near(tonemate_frequency_to_midi(261.6255653005986), 60.0));
  assert(near(tonemate_cents_between(880.0, 440.0), 1200.0));
  assert(near(tonemate_cents_between(440.0, 880.0), -1200.0));
  assert(std::isnan(tonemate_frequency_to_midi(0.0)));
  assert(std::isnan(tonemate_frequency_to_midi(-1.0)));
  assert(std::isnan(tonemate_midi_to_frequency(
      std::numeric_limits<double>::infinity())));
  assert(std::isnan(tonemate_cents_between(440.0, 0.0)));
  return 0;
}
