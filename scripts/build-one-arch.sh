#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'usage: %s <macos-arm64|macos-x86_64|ios-arm64|ios-simulator-arm64|ios-simulator-x86_64>\n' "$0" >&2
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
