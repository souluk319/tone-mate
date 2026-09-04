#ifndef TONEMATE_PITCH_CORE_H
#define TONEMATE_PITCH_CORE_H

#include <stdint.h>

#if defined(_WIN32) && defined(TONEMATE_PITCH_CORE_SHARED)
#if defined(TONEMATE_PITCH_CORE_BUILDING)
#define TONEMATE_PITCH_CORE_API __declspec(dllexport)
#else
#define TONEMATE_PITCH_CORE_API __declspec(dllimport)
#endif
#elif defined(__GNUC__) || defined(__clang__)
#define TONEMATE_PITCH_CORE_API __attribute__((visibility("default")))
#else
#define TONEMATE_PITCH_CORE_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

enum { TONEMATE_PITCH_CORE_ABI_VERSION = 1 };

TONEMATE_PITCH_CORE_API int32_t tonemate_pitch_core_abi_version(void);

// Converts a MIDI note value to frequency in hertz using A4 = 440 Hz.
// Returns NaN when midi_note is not finite.
TONEMATE_PITCH_CORE_API double tonemate_midi_to_frequency(double midi_note);

// Converts a positive frequency in hertz to a fractional MIDI note value.
// Returns NaN for zero, negative, or non-finite input.
TONEMATE_PITCH_CORE_API double tonemate_frequency_to_midi(double frequency_hz);

// Returns the signed interval from reference_hz to frequency_hz in cents.
// Returns NaN when either input is zero, negative, or non-finite.
TONEMATE_PITCH_CORE_API double tonemate_cents_between(
    double frequency_hz,
    double reference_hz);

#ifdef __cplusplus
}
#endif

#endif
