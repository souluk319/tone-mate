#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
version=0.1.0-alpha.2
identity=tonemate.apple-audio
archive_root="$identity-$version"
output_dir="$repo_root/dist/hosted-upload/swift-$version"

if [[ -n $(git status --porcelain --untracked-files=normal) ]]; then
  echo 'Commit the package source before preparing a release.' >&2
  exit 1
fi
if [[ -e $output_dir ]]; then
  echo "Refusing to overwrite existing release: $output_dir" >&2
  exit 1
fi
command -v jq >/dev/null
source_commit=$(git rev-parse HEAD)
scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/tonemate-swift-package.XXXXXX")
trap 'rm -rf -- "$scratch_dir"' EXIT
git archive HEAD packages/apple_audio | tar -xf - -C "$scratch_dir"
mv "$scratch_dir/packages/apple_audio" "$scratch_dir/$archive_root"
swift package --package-path "$scratch_dir/$archive_root" archive-source \
  --output "$scratch_dir/$archive_root.zip"

unzip -Z1 "$scratch_dir/$archive_root.zip" | awk -v root="$archive_root/" '
  index($0, root) != 1 { invalid = 1 }
  $0 == root "Package.swift" { manifest = 1 }
  END { exit (invalid || !manifest) }
'
artifact_sha256=$(shasum -a 256 "$scratch_dir/$archive_root.zip" | awk '{print $1}')
swift_version=$(swift --version | head -1)
jq -n --arg source_commit "$source_commit" --arg coordinate "$identity@$version" \
  --arg version "$version" --arg artifact_file "$archive_root.zip" \
  --arg artifact_sha256 "$artifact_sha256" --arg swift "$swift_version" \
  '{format:"swift",coordinate:$coordinate,version:$version,source_commit:$source_commit,
    source_dirty:false,artifact_file:$artifact_file,artifact_sha256:$artifact_sha256,
    toolchain:{swift:$swift},publication_status:"not-published"}' \
  > "$scratch_dir/$archive_root.zip.manifest.json"
mkdir -p "$output_dir"
cp "$scratch_dir/$archive_root.zip" "$scratch_dir/$archive_root.zip.manifest.json" "$output_dir/"
printf 'Package: %s@%s\nArchive: %s/%s.zip\nSHA-256: %s\n' \
  "$identity" "$version" "$output_dir" "$archive_root" "$artifact_sha256"
