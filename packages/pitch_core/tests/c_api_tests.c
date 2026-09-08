#include "tonemate/pitch_core.h"
#include <math.h>
#include <stdio.h>

int main(void) {
  float samples[TONEMATE_PITCH_FRAME_SIZE];
  for (int i = 0; i < TONEMATE_PITCH_FRAME_SIZE; ++i)
    samples[i] = (float)(0.25 * sin(2.0 * acos(-1.0) * 440.0 * i / 48000));
  tonemate_pitch_detector* detector = tonemate_pitch_detector_create(48000);
  if (!detector) return 1;
  tonemate_pitch_result result = {0, 0};
  const int32_t status = tonemate_pitch_detector_process(
      detector, samples, TONEMATE_PITCH_FRAME_SIZE, &result);
  tonemate_pitch_detector_destroy(detector);
  if (status != TONEMATE_PITCH_OK || !isfinite(result.frequency_hz)
      || fabs(tonemate_cents_between(result.frequency_hz, 440)) > 5) {
    fprintf(stderr, "C caller: status=%d frequency=%f\n", (int)status, result.frequency_hz);
    return 1;
  }
  return tonemate_pitch_core_abi_version() == TONEMATE_PITCH_CORE_ABI_VERSION ? 0 : 1;
}
