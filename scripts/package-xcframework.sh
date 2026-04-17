#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
out_dir="${OUT_DIR:-${repo_root}/out}"
dist_dir="${DIST_DIR:-${repo_root}/dist}"
static_xcframework_path="${dist_dir}/cquickjs-static.xcframework"
dynamic_xcframework_path="${dist_dir}/cquickjs-dynamic.xcframework"
static_zip_path="${dist_dir}/cquickjs-static.xcframework.zip"
dynamic_zip_path="${dist_dir}/cquickjs-dynamic.xcframework.zip"
license_output_path="${dist_dir}/LICENSE.txt"
packaging_dir="${out_dir}/packaging"
static_packaging_dir="${packaging_dir}/static"
dynamic_packaging_dir="${packaging_dir}/dynamic"
dynamic_frameworks_dir="${packaging_dir}/dynamic-frameworks"

required_slices=(
  macos-arm64
  macos-x86_64
  ios-arm64
  ios-simulator-arm64
  ios-simulator-x86_64
  maccatalyst-arm64
  maccatalyst-x86_64
  tvos-arm64
  tvos-simulator-arm64
  tvos-simulator-x86_64
  watchos-arm64_32
  watchos-simulator-arm64
  watchos-simulator-x86_64
  visionos-arm64
  visionos-simulator-arm64
  visionos-simulator-x86_64
)

static_args=()
dynamic_args=()

static_lib_path() {
  printf '%s/%s/static/lib/libcquickjs.a' "${out_dir}" "$1"
}

static_headers_path() {
  printf '%s/%s/static/include' "${out_dir}" "$1"
}

dynamic_lib_path() {
  printf '%s/%s/dynamic/lib/CQuickJSDynamic' "${out_dir}" "$1"
}

dynamic_headers_path() {
  printf '%s/%s/dynamic/include' "${out_dir}" "$1"
}

for slice in "${required_slices[@]}"; do
  for path in \
    "$(static_lib_path "${slice}")" \
    "$(static_headers_path "${slice}")" \
    "$(dynamic_lib_path "${slice}")" \
    "$(dynamic_headers_path "${slice}")"; do
    if [[ ! -e "${path}" ]]; then
      printf 'missing required build output: %s\n' "${path}" >&2
      exit 1
    fi
  done
done

rm -rf \
  "${static_xcframework_path}" "${dynamic_xcframework_path}" \
  "${static_zip_path}" "${dynamic_zip_path}" "${license_output_path}" \
  "${packaging_dir}"
mkdir -p "${dist_dir}" "${static_packaging_dir}" "${dynamic_packaging_dir}" "${dynamic_frameworks_dir}"

create_dynamic_framework() {
  local framework_path="$1"
  local binary_path="$2"
  local headers_path="$3"
  local minimum_os_version="$4"
  local framework_name="CQuickJSDynamic"

  rm -rf "${framework_path}"
  mkdir -p "${framework_path}/Headers" "${framework_path}/Modules"
  cp "${binary_path}" "${framework_path}/${framework_name}"
  chmod u+w "${framework_path}/${framework_name}"
  rsync -a --delete --exclude module.modulemap "${headers_path}/" "${framework_path}/Headers/"
  cp "${repo_root}/include/module.dynamic.modulemap" "${framework_path}/Modules/module.modulemap"
  cat > "${framework_path}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${framework_name}</string>
  <key>CFBundleIdentifier</key>
  <string>org.quickjs-ng.${framework_name}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${framework_name}</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>MinimumOSVersion</key>
  <string>${minimum_os_version}</string>
</dict>
</plist>
PLIST
}

write_dynamic_slice_modulemaps() {
  local framework_path
  local slice_dir

  while IFS= read -r -d '' framework_path; do
    slice_dir="$(dirname "${framework_path}")"
    cat > "${slice_dir}/module.modulemap" <<MODULEMAP
module CQuickJSDynamic {
  umbrella header "CQuickJSDynamic.framework/Headers/cquickjs.h"
  link framework "CQuickJSDynamic"
  export *
}
MODULEMAP
  done < <(find "${dynamic_xcframework_path}" -mindepth 2 -maxdepth 2 -name 'CQuickJSDynamic.framework' -type d -print0)
}

make_static_slice_with_paths() {
  local name="$1"
  local headers_slice="$2"
  shift 2
  local libs=("$@")
  local slice_dir="${static_packaging_dir}/${name}"
  local output_lib="${slice_dir}/lib/libcquickjs.a"
  local output_headers="${slice_dir}/include"

  mkdir -p "${slice_dir}/lib" "${output_headers}"
  rsync -a --delete "$(static_headers_path "${headers_slice}")/" "${output_headers}/"
  if [[ "${#libs[@]}" -eq 1 ]]; then
    cp "${libs[0]}" "${output_lib}"
  else
    xcrun lipo -create "${libs[@]}" -output "${output_lib}"
  fi

  static_args+=(-library "${output_lib}" -headers "${output_headers}")
}

make_dynamic_slice_with_paths() {
  local name="$1"
  local headers_slice="$2"
  local minimum_os_version="$3"
  shift 3
  local libs=("$@")
  local slice_dir="${dynamic_packaging_dir}/${name}"
  local output_binary="${slice_dir}/CQuickJSDynamic"
  local framework_path="${dynamic_frameworks_dir}/${name}/CQuickJSDynamic.framework"

  mkdir -p "${slice_dir}"
  if [[ "${#libs[@]}" -eq 1 ]]; then
    cp "${libs[0]}" "${output_binary}"
  else
    xcrun lipo -create "${libs[@]}" -output "${output_binary}"
  fi

  create_dynamic_framework "${framework_path}" "${output_binary}" "$(dynamic_headers_path "${headers_slice}")" "${minimum_os_version}"
  dynamic_args+=(-framework "${framework_path}")
}

make_static_slice_with_paths macos macos-arm64 \
  "$(static_lib_path macos-arm64)" \
  "$(static_lib_path macos-x86_64)"
make_static_slice_with_paths ios ios-arm64 "$(static_lib_path ios-arm64)"
make_static_slice_with_paths ios-simulator ios-simulator-arm64 \
  "$(static_lib_path ios-simulator-arm64)" \
  "$(static_lib_path ios-simulator-x86_64)"
make_static_slice_with_paths maccatalyst maccatalyst-arm64 \
  "$(static_lib_path maccatalyst-arm64)" \
  "$(static_lib_path maccatalyst-x86_64)"
make_static_slice_with_paths tvos tvos-arm64 "$(static_lib_path tvos-arm64)"
make_static_slice_with_paths tvos-simulator tvos-simulator-arm64 \
  "$(static_lib_path tvos-simulator-arm64)" \
  "$(static_lib_path tvos-simulator-x86_64)"
make_static_slice_with_paths watchos watchos-arm64_32 "$(static_lib_path watchos-arm64_32)"
make_static_slice_with_paths watchos-simulator watchos-simulator-arm64 \
  "$(static_lib_path watchos-simulator-arm64)" \
  "$(static_lib_path watchos-simulator-x86_64)"
make_static_slice_with_paths visionos visionos-arm64 "$(static_lib_path visionos-arm64)"
make_static_slice_with_paths visionos-simulator visionos-simulator-arm64 \
  "$(static_lib_path visionos-simulator-arm64)" \
  "$(static_lib_path visionos-simulator-x86_64)"

xcodebuild -create-xcframework "${static_args[@]}" -output "${static_xcframework_path}"

make_dynamic_slice_with_paths macos macos-arm64 "11.0" \
  "$(dynamic_lib_path macos-arm64)" \
  "$(dynamic_lib_path macos-x86_64)"
make_dynamic_slice_with_paths ios ios-arm64 "13.0" "$(dynamic_lib_path ios-arm64)"
make_dynamic_slice_with_paths ios-simulator ios-simulator-arm64 "13.0" \
  "$(dynamic_lib_path ios-simulator-arm64)" \
  "$(dynamic_lib_path ios-simulator-x86_64)"
make_dynamic_slice_with_paths maccatalyst maccatalyst-arm64 "13.1" \
  "$(dynamic_lib_path maccatalyst-arm64)" \
  "$(dynamic_lib_path maccatalyst-x86_64)"
make_dynamic_slice_with_paths tvos tvos-arm64 "13.0" "$(dynamic_lib_path tvos-arm64)"
make_dynamic_slice_with_paths tvos-simulator tvos-simulator-arm64 "13.0" \
  "$(dynamic_lib_path tvos-simulator-arm64)" \
  "$(dynamic_lib_path tvos-simulator-x86_64)"
make_dynamic_slice_with_paths watchos watchos-arm64_32 "6.0" "$(dynamic_lib_path watchos-arm64_32)"
make_dynamic_slice_with_paths watchos-simulator watchos-simulator-arm64 "6.0" \
  "$(dynamic_lib_path watchos-simulator-arm64)" \
  "$(dynamic_lib_path watchos-simulator-x86_64)"
make_dynamic_slice_with_paths visionos visionos-arm64 "1.0" "$(dynamic_lib_path visionos-arm64)"
make_dynamic_slice_with_paths visionos-simulator visionos-simulator-arm64 "1.0" \
  "$(dynamic_lib_path visionos-simulator-arm64)" \
  "$(dynamic_lib_path visionos-simulator-x86_64)"

xcodebuild -create-xcframework "${dynamic_args[@]}" -output "${dynamic_xcframework_path}"

write_dynamic_slice_modulemaps

if [[ -f "${out_dir}/macos-arm64/LICENSE.txt" ]]; then
  cp "${out_dir}/macos-arm64/LICENSE.txt" "${license_output_path}"
fi

(
  cd "${dist_dir}"
  ditto -c -k --sequesterRsrc --keepParent "cquickjs-static.xcframework" "cquickjs-static.xcframework.zip"
  ditto -c -k --sequesterRsrc --keepParent "cquickjs-dynamic.xcframework" "cquickjs-dynamic.xcframework.zip"
  swift package compute-checksum "cquickjs-static.xcframework.zip" > "cquickjs-static.xcframework.zip.checksum"
  swift package compute-checksum "cquickjs-dynamic.xcframework.zip" > "cquickjs-dynamic.xcframework.zip.checksum"
)

printf 'packaged %s\n' "${static_xcframework_path}"
printf 'packaged %s\n' "${dynamic_xcframework_path}"
