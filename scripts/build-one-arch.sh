#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'usage: %s <slice>\n' "$0" >&2
  printf 'supported slices: macos-arm64 macos-x86_64 ios-arm64 ios-simulator-arm64 ios-simulator-x86_64 maccatalyst-arm64 maccatalyst-x86_64 tvos-arm64 tvos-simulator-arm64 tvos-simulator-x86_64 watchos-arm64_32 watchos-simulator-arm64 watchos-simulator-x86_64 visionos-arm64 visionos-simulator-arm64 visionos-simulator-x86_64\n' >&2
  exit 2
fi

slice="$1"
case "${slice}" in
  arm64|macos-arm64)
    platform="macos-arm64"
    arch="arm64"
    sdk="macosx"
    target="arm64-apple-macos${MACOSX_DEPLOYMENT_TARGET:-11.0}"
    ;;
  x86_64|macos-x86_64)
    platform="macos-x86_64"
    arch="x86_64"
    sdk="macosx"
    target="x86_64-apple-macos${MACOSX_DEPLOYMENT_TARGET:-11.0}"
    ;;
  ios-arm64)
    platform="ios-arm64"
    arch="arm64"
    sdk="iphoneos"
    target="arm64-apple-ios${IOS_DEPLOYMENT_TARGET:-13.0}"
    ;;
  ios-simulator-arm64)
    platform="ios-simulator-arm64"
    arch="arm64"
    sdk="iphonesimulator"
    target="arm64-apple-ios${IOS_DEPLOYMENT_TARGET:-13.0}-simulator"
    ;;
  ios-simulator-x86_64)
    platform="ios-simulator-x86_64"
    arch="x86_64"
    sdk="iphonesimulator"
    target="x86_64-apple-ios${IOS_DEPLOYMENT_TARGET:-13.0}-simulator"
    ;;
  maccatalyst-arm64)
    platform="maccatalyst-arm64"
    arch="arm64"
    sdk="macosx"
    target="arm64-apple-ios${MACCATALYST_DEPLOYMENT_TARGET:-13.1}-macabi"
    ;;
  maccatalyst-x86_64)
    platform="maccatalyst-x86_64"
    arch="x86_64"
    sdk="macosx"
    target="x86_64-apple-ios${MACCATALYST_DEPLOYMENT_TARGET:-13.1}-macabi"
    ;;
  tvos-arm64)
    platform="tvos-arm64"
    arch="arm64"
    sdk="appletvos"
    target="arm64-apple-tvos${TVOS_DEPLOYMENT_TARGET:-13.0}"
    ;;
  tvos-simulator-arm64)
    platform="tvos-simulator-arm64"
    arch="arm64"
    sdk="appletvsimulator"
    target="arm64-apple-tvos${TVOS_DEPLOYMENT_TARGET:-13.0}-simulator"
    ;;
  tvos-simulator-x86_64)
    platform="tvos-simulator-x86_64"
    arch="x86_64"
    sdk="appletvsimulator"
    target="x86_64-apple-tvos${TVOS_DEPLOYMENT_TARGET:-13.0}-simulator"
    ;;
  watchos-arm64_32)
    platform="watchos-arm64_32"
    arch="arm64_32"
    sdk="watchos"
    target="arm64_32-apple-watchos${WATCHOS_DEPLOYMENT_TARGET:-6.0}"
    ;;
  watchos-simulator-arm64)
    platform="watchos-simulator-arm64"
    arch="arm64"
    sdk="watchsimulator"
    target="arm64-apple-watchos${WATCHOS_DEPLOYMENT_TARGET:-6.0}-simulator"
    ;;
  watchos-simulator-x86_64)
    platform="watchos-simulator-x86_64"
    arch="x86_64"
    sdk="watchsimulator"
    target="x86_64-apple-watchos${WATCHOS_DEPLOYMENT_TARGET:-6.0}-simulator"
    ;;
  visionos-arm64)
    platform="visionos-arm64"
    arch="arm64"
    sdk="xros"
    target="arm64-apple-xros${VISIONOS_DEPLOYMENT_TARGET:-1.0}"
    ;;
  visionos-simulator-arm64)
    platform="visionos-simulator-arm64"
    arch="arm64"
    sdk="xrsimulator"
    target="arm64-apple-xros${VISIONOS_DEPLOYMENT_TARGET:-1.0}-simulator"
    ;;
  visionos-simulator-x86_64)
    platform="visionos-simulator-x86_64"
    arch="x86_64"
    sdk="xrsimulator"
    target="x86_64-apple-xros${VISIONOS_DEPLOYMENT_TARGET:-1.0}-simulator"
    ;;
  *)
    printf 'unsupported slice: %s\n' "${slice}" >&2
    exit 2
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
quickjs_dir="${QUICKJS_SOURCE_DIR:-}"
if [[ -z "${quickjs_dir}" ]]; then
  if [[ -d "${repo_root}/vendor/quickjs" ]]; then
    quickjs_dir="${repo_root}/vendor/quickjs"
  elif [[ -d "${repo_root}/../quickjs" ]]; then
    quickjs_dir="${repo_root}/../quickjs"
  else
    quickjs_dir="${repo_root}/vendor/quickjs"
  fi
fi
work_dir="${WORK_DIR:-${repo_root}/.build}"
out_dir="${OUT_DIR:-${repo_root}/out}"
build_dir="${work_dir}/build-${platform}"
install_dir="${out_dir}/${platform}"
static_dir="${install_dir}/static"
dynamic_dir="${install_dir}/dynamic"
static_headers="${static_dir}/include"
dynamic_headers="${dynamic_dir}/include"
sdk_path="$(xcrun --sdk "${sdk}" --show-sdk-path)"

sources=(
  "${quickjs_dir}/dtoa.c"
  "${quickjs_dir}/libregexp.c"
  "${quickjs_dir}/libunicode.c"
  "${quickjs_dir}/quickjs.c"
)

if [[ ! -f "${quickjs_dir}/quickjs.h" ]]; then
  printf 'QuickJS source was not found at %s. Set QUICKJS_SOURCE_DIR or checkout quickjs-ng/quickjs into vendor/quickjs.\n' "${quickjs_dir}" >&2
  exit 1
fi

rm -rf "${build_dir}" "${install_dir}"
mkdir -p \
  "${build_dir}/static-objects" "${build_dir}/dynamic-objects" \
  "${static_dir}/lib" "${dynamic_dir}/lib" \
  "${static_headers}" "${dynamic_headers}"

if [[ -f "${quickjs_dir}/LICENSE" ]]; then
  cp "${quickjs_dir}/LICENSE" "${install_dir}/LICENSE.txt"
fi

copy_headers() {
  local headers_dir="$1"
  local modulemap="$2"

  cp "${repo_root}/include/cquickjs.h" "${headers_dir}/cquickjs.h"
  cp "${repo_root}/include/${modulemap}" "${headers_dir}/module.modulemap"
  cp "${quickjs_dir}/quickjs.h" "${headers_dir}/quickjs.h"
}

compile_objects() {
  local object_dir="$1"
  local pic_flag="$2"
  local objects_file="$3"
  local source
  local object

  : > "${objects_file}"
  for source in "${sources[@]}"; do
    object="${object_dir}/$(basename "${source}" .c).o"
    xcrun --sdk "${sdk}" clang \
      -target "${target}" \
      -arch "${arch}" \
      -isysroot "${sdk_path}" \
      -std=gnu11 \
      -O3 \
      -DNDEBUG \
      -D_GNU_SOURCE=1 \
      -funsigned-char \
      ${pic_flag} \
      -I "${quickjs_dir}" \
      -c "${source}" \
      -o "${object}"
    printf '%s\n' "${object}" >> "${objects_file}"
  done
}

static_objects_file="${build_dir}/static-objects.txt"
dynamic_objects_file="${build_dir}/dynamic-objects.txt"

compile_objects "${build_dir}/static-objects" "" "${static_objects_file}"
xcrun libtool -static -o "${static_dir}/lib/libcquickjs.a" $(cat "${static_objects_file}")
copy_headers "${static_headers}" "module.static.modulemap"

compile_objects "${build_dir}/dynamic-objects" "-fPIC" "${dynamic_objects_file}"
xcrun --sdk "${sdk}" clang \
  -target "${target}" \
  -arch "${arch}" \
  -isysroot "${sdk_path}" \
  -dynamiclib \
  -install_name "@rpath/CQuickJSDynamic.framework/CQuickJSDynamic" \
  -o "${dynamic_dir}/lib/CQuickJSDynamic" \
  $(cat "${dynamic_objects_file}") \
  -lm
copy_headers "${dynamic_headers}" "module.dynamic.modulemap"

printf 'built %s at %s\n' "${platform}" "${install_dir}"
