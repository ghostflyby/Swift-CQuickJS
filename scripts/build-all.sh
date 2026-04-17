#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${script_dir}/build-one-arch.sh" macos-arm64
"${script_dir}/build-one-arch.sh" macos-x86_64
"${script_dir}/build-one-arch.sh" ios-arm64
"${script_dir}/build-one-arch.sh" ios-simulator-arm64
"${script_dir}/build-one-arch.sh" ios-simulator-x86_64
"${script_dir}/build-one-arch.sh" maccatalyst-arm64
"${script_dir}/build-one-arch.sh" maccatalyst-x86_64
"${script_dir}/build-one-arch.sh" tvos-arm64
"${script_dir}/build-one-arch.sh" tvos-simulator-arm64
"${script_dir}/build-one-arch.sh" tvos-simulator-x86_64
"${script_dir}/build-one-arch.sh" watchos-arm64_32
"${script_dir}/build-one-arch.sh" watchos-simulator-arm64
"${script_dir}/build-one-arch.sh" watchos-simulator-x86_64
"${script_dir}/build-one-arch.sh" visionos-arm64
"${script_dir}/build-one-arch.sh" visionos-simulator-arm64
"${script_dir}/build-one-arch.sh" visionos-simulator-x86_64
"${script_dir}/package-xcframework.sh"
