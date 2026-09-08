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

// Experimental YIN baseline: 4096 mono samples, 44.1/48 kHz, 65–1047 Hz.
// Range limits bound lag search, not a strict band-pass filter.
// Not a voice detector or a calibrated confidence score.
enum { TONEMATE_PITCH_FRAME_SIZE = 4096 };
enum {
  TONEMATE_PITCH_OK = 0,
  TONEMATE_PITCH_UNVOICED = 1,
  TONEMATE_PITCH_INVALID_INPUT = -1
};
typedef struct tonemate_pitch_detector tonemate_pitch_detector;
typedef struct tonemate_pitch_result {
  double frequency_hz;
  double periodicity;
} tonemate_pitch_result;

// Create/destroy outside the audio callback. NULL means unsupported rate or OOM.
TONEMATE_PITCH_CORE_API tonemate_pitch_detector* tonemate_pitch_detector_create(
    int32_t sample_rate);
TONEMATE_PITCH_CORE_API void tonemate_pitch_detector_destroy(
    tonemate_pitch_detector* detector);
// Worker-only, one caller per detector; no allocation, I/O or retained PCM.
// Exactly FRAME_SIZE finite normalized [-1, 1] samples are required.
// Non-OK clears result. Silence/DC returns UNVOICED; NULL result is invalid.
TONEMATE_PITCH_CORE_API int32_t tonemate_pitch_detector_process(
    tonemate_pitch_detector* detector, const float* samples, int32_t sample_count,
    tonemate_pitch_result* result);

#ifdef __cplusplus
}
#endif

#endif
