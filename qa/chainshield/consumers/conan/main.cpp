#include <tonemate/pitch_core.h>
#include <cmath>
#include <iostream>

int main() {
    const auto frequency = tonemate_midi_to_frequency(69.0);
    if (tonemate_pitch_core_abi_version() != 1 || std::abs(frequency - 440.0) > 1e-9) return 1;
    std::cout << "ToneMatePitchCore registry link OK: A4 = " << frequency << " Hz\n";
}
