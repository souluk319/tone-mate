#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
version=0.1.0-alpha.1
output_dir="$repo_root/dist/hosted-upload"
scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/tonemate-hosted-upload.XXXXXX")
trap 'rm -rf "$scratch_dir"' EXIT

if [[ -n $(git -C "$repo_root" status --porcelain --untracked-files=normal) ]]; then
  printf '%s\n' 'Refusing to build publication artifacts from a dirty ToneMate worktree.' >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' 'jq is required to write package manifests.' >&2
  exit 1
fi

mkdir -p "$output_dir"
source_commit=$(git -C "$repo_root" rev-parse HEAD)
created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

swift_stage="$scratch_dir/apple_audio"
mkdir -p "$swift_stage"
cp "$repo_root/packages/apple_audio/Package.swift" "$swift_stage/"
cp "$repo_root/packages/apple_audio/LICENSE" "$swift_stage/"
cp -R "$repo_root/packages/apple_audio/Sources" "$swift_stage/"
cp -R "$repo_root/packages/apple_audio/Tests" "$swift_stage/"
swift_output="$scratch_dir/tonemate.apple-audio-$version.zip"
(
  cd "$swift_stage"
  swift package archive-source --output "$swift_output"
)

cocoapods_stage="$scratch_dir/ToneMatePitch-$version"
mkdir -p "$cocoapods_stage/Sources/ToneMateAppleAudio"
cp "$repo_root/distribution/cocoapods/ToneMatePitch.podspec.json" "$cocoapods_stage/"
cp "$repo_root/packages/apple_audio/LICENSE" "$cocoapods_stage/"
cp "$repo_root/packages/apple_audio/Sources/ToneMateAppleAudio/"*.swift \
  "$cocoapods_stage/Sources/ToneMateAppleAudio/"
(
  cd "$cocoapods_stage"
  zip -X -q -r "$scratch_dir/ToneMatePitch-$version.zip" .
)

if ! command -v conan >/dev/null 2>&1; then
  printf '%s\n' 'Conan 2.31.1 is required to build the Conan web-upload archive.' >&2
  exit 1
fi

conan_home="$scratch_dir/conan-home"
export CONAN_HOME="$conan_home"
conan profile detect --force >/dev/null
conan create "$repo_root/packages/pitch_core" \
  --name tonemate-pitch-core \
  --version "$version" \
  --user tonemate \
  --channel stable \
  --no-remote \
  -s build_type=Release \
  -s compiler.cppstd=20 \
  --build=missing
conan cache save \
  "tonemate-pitch-core/$version@tonemate/stable#*:*#*" \
  --file "$scratch_dir/tonemate-pitch-core-$version.tgz"

mv "$scratch_dir/tonemate-pitch-core-$version.tgz" "$output_dir/"
mv "$swift_output" "$output_dir/"
mv "$scratch_dir/ToneMatePitch-$version.zip" "$output_dir/"

(
  cd "$output_dir"
  shasum -a 256 \
    "tonemate-pitch-core-$version.tgz" \
    "tonemate.apple-audio-$version.zip" \
    "ToneMatePitch-$version.zip" > SHA256SUMS
)

write_manifest() {
  format=$1
  coordinate=$2
  artifact_file=$3
  tool_name=$4
  tool_version=$5
  artifact_sha256=$(shasum -a 256 "$output_dir/$artifact_file" | awk '{print $1}')
  jq -n \
    --arg source_commit "$source_commit" \
    --arg product_version "$version" \
    --arg format "$format" \
    --arg coordinate "$coordinate" \
    --arg version "$version" \
    --arg artifact_file "$artifact_file" \
    --arg artifact_sha256 "$artifact_sha256" \
    --arg tool_name "$tool_name" \
    --arg tool_version "$tool_version" \
    --arg created_at "$created_at" \
    '{
      source_commit: $source_commit,
      source_dirty: false,
      product_version: $product_version,
      format: $format,
      coordinate: $coordinate,
      version: $version,
      artifact_file: $artifact_file,
      artifact_sha256: $artifact_sha256,
      toolchain: {($tool_name): $tool_version},
      lockfiles: [],
      created_at: $created_at
    }' > "$output_dir/$artifact_file.manifest.json"
}

write_manifest \
  conan \
  "tonemate-pitch-core/$version@tonemate/stable" \
  "tonemate-pitch-core-$version.tgz" \
  conan \
  "$(conan --version | awk '{print $3}')"
write_manifest \
  swift \
  "tonemate.apple-audio@$version" \
  "tonemate.apple-audio-$version.zip" \
  swift \
  "$(swift --version | sed -n '1s/.*Apple Swift version \([^ ]*\).*/\1/p')"
write_manifest \
  cocoapods \
  "ToneMatePitch@$version" \
  "ToneMatePitch-$version.zip" \
  cocoapods \
  "$(pod --version)"

printf 'Hosted web-upload artifacts written to %s\n' "$output_dir"
