#include "tonemate/pitch_core.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <new>

struct tonemate_pitch_detector {
  int32_t sample_rate;
  std::array<double, 741> difference{};
};

tonemate_pitch_detector* tonemate_pitch_detector_create(int32_t sample_rate) {
  if (sample_rate != 44100 && sample_rate != 48000) return nullptr;
  return new (std::nothrow) tonemate_pitch_detector{sample_rate, {}};
}

void tonemate_pitch_detector_destroy(tonemate_pitch_detector* detector) {
  delete detector;
}

int32_t tonemate_pitch_detector_process(
    tonemate_pitch_detector* detector, const float* samples, int32_t sample_count,
    tonemate_pitch_result* result) {
  if (!result) return TONEMATE_PITCH_INVALID_INPUT;
  *result = {};
  if (!detector || !samples || sample_count != TONEMATE_PITCH_FRAME_SIZE)
    return TONEMATE_PITCH_INVALID_INPUT;

  double mean = 0.0;
  for (int32_t i = 0; i < sample_count; ++i) {
    if (!std::isfinite(samples[i]) || std::abs(samples[i]) > 1.0f)
      return TONEMATE_PITCH_INVALID_INPUT;
    mean += samples[i];
  }
  mean /= sample_count;
  double variance = 0.0;
  for (int32_t i = 0; i < sample_count; ++i) {
    const double centered = samples[i] - mean;
    variance += centered * centered;
  }
  if (variance / sample_count < 1e-12) return TONEMATE_PITCH_UNVOICED;

  // YIN squared difference / cumulative mean normalization and first trough.
  // de Cheveigne & Kawahara (2002), doi:10.1121/1.1458024.
  // Fixed half-frame comparison window; temporal smoothing is not implemented.
  constexpr int window = TONEMATE_PITCH_FRAME_SIZE / 2;
  const int minimum = static_cast<int>(std::floor(detector->sample_rate / 1047.0));
  const int maximum = static_cast<int>(std::ceil(detector->sample_rate / 65.0));
  auto& d = detector->difference;
  d[0] = 1.0;
  double cumulative = 0.0;
  for (int lag = 1; lag <= maximum + 1; ++lag) {
    double sum = 0.0;
    for (int i = 0; i < window; ++i) {
      const double delta = static_cast<double>(samples[i]) - samples[i + lag];
      sum += delta * delta;
    }
    cumulative += sum;
    d[lag] = cumulative > 0.0 ? sum * lag / cumulative : 1.0;
  }
  for (int lag = minimum; lag <= maximum; ++lag) {
    if (d[lag] >= 0.15 || d[lag] > d[lag - 1] || d[lag] > d[lag + 1]) continue;
    const double curvature = d[lag - 1] - 2.0 * d[lag] + d[lag + 1];
    const double offset = curvature > 0.0
        ? std::clamp(0.5 * (d[lag - 1] - d[lag + 1]) / curvature, -0.5, 0.5)
        : 0.0;
    const double hz = detector->sample_rate / (lag + offset);
    // The search is bounded by integer lags. Do not reject or clamp a valid
    // boundary trough merely because interpolation crosses the nominal limit.
    result->frequency_hz = hz;
    result->periodicity = std::clamp(1.0 - d[lag], 0.0, 1.0);
    return TONEMATE_PITCH_OK;
  }
  return TONEMATE_PITCH_UNVOICED;
}
