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

macos_arm64_static_lib="${out_dir}/macos-arm64/static/lib/libcquickjs.a"
macos_arm64_static_headers="${out_dir}/macos-arm64/static/include"
macos_x86_64_static_lib="${out_dir}/macos-x86_64/static/lib/libcquickjs.a"
macos_x86_64_static_headers="${out_dir}/macos-x86_64/static/include"
ios_device_static_lib="${out_dir}/ios-arm64/static/lib/libcquickjs.a"
ios_device_static_headers="${out_dir}/ios-arm64/static/include"
ios_simulator_arm64_static_lib="${out_dir}/ios-simulator-arm64/static/lib/libcquickjs.a"
ios_simulator_arm64_static_headers="${out_dir}/ios-simulator-arm64/static/include"
ios_simulator_x86_64_static_lib="${out_dir}/ios-simulator-x86_64/static/lib/libcquickjs.a"
ios_simulator_x86_64_static_headers="${out_dir}/ios-simulator-x86_64/static/include"

macos_arm64_dynamic_lib="${out_dir}/macos-arm64/dynamic/lib/CQuickJSDynamic"
macos_arm64_dynamic_headers="${out_dir}/macos-arm64/dynamic/include"
macos_x86_64_dynamic_lib="${out_dir}/macos-x86_64/dynamic/lib/CQuickJSDynamic"
macos_x86_64_dynamic_headers="${out_dir}/macos-x86_64/dynamic/include"
ios_device_dynamic_lib="${out_dir}/ios-arm64/dynamic/lib/CQuickJSDynamic"
ios_device_dynamic_headers="${out_dir}/ios-arm64/dynamic/include"
ios_simulator_arm64_dynamic_lib="${out_dir}/ios-simulator-arm64/dynamic/lib/CQuickJSDynamic"
ios_simulator_arm64_dynamic_headers="${out_dir}/ios-simulator-arm64/dynamic/include"
ios_simulator_x86_64_dynamic_lib="${out_dir}/ios-simulator-x86_64/dynamic/lib/CQuickJSDynamic"
ios_simulator_x86_64_dynamic_headers="${out_dir}/ios-simulator-x86_64/dynamic/include"

macos_universal_dir="${out_dir}/macos-universal"
macos_static_universal_lib="${macos_universal_dir}/static/lib/libcquickjs.a"
macos_static_universal_headers="${macos_universal_dir}/static/include"
macos_dynamic_universal_lib="${macos_universal_dir}/dynamic/lib/CQuickJSDynamic"
macos_dynamic_universal_headers="${macos_universal_dir}/dynamic/include"
ios_simulator_universal_dir="${out_dir}/ios-simulator-universal"
ios_simulator_static_universal_lib="${ios_simulator_universal_dir}/static/lib/libcquickjs.a"
ios_simulator_static_universal_headers="${ios_simulator_universal_dir}/static/include"
ios_simulator_dynamic_universal_lib="${ios_simulator_universal_dir}/dynamic/lib/CQuickJSDynamic"
dynamic_frameworks_dir="${out_dir}/dynamic-frameworks"
macos_dynamic_framework="${dynamic_frameworks_dir}/macos/CQuickJSDynamic.framework"
ios_device_dynamic_framework="${dynamic_frameworks_dir}/ios/CQuickJSDynamic.framework"
ios_simulator_dynamic_framework="${dynamic_frameworks_dir}/ios-simulator/CQuickJSDynamic.framework"

for path in \
  "${macos_arm64_static_lib}" "${macos_arm64_static_headers}" \
  "${macos_x86_64_static_lib}" "${macos_x86_64_static_headers}" \
  "${ios_device_static_lib}" "${ios_device_static_headers}" \
  "${ios_simulator_arm64_static_lib}" "${ios_simulator_arm64_static_headers}" \
  "${ios_simulator_x86_64_static_lib}" "${ios_simulator_x86_64_static_headers}" \
  "${macos_arm64_dynamic_lib}" "${macos_arm64_dynamic_headers}" \
  "${macos_x86_64_dynamic_lib}" "${macos_x86_64_dynamic_headers}" \
  "${ios_device_dynamic_lib}" "${ios_device_dynamic_headers}" \
  "${ios_simulator_arm64_dynamic_lib}" "${ios_simulator_arm64_dynamic_headers}" \
  "${ios_simulator_x86_64_dynamic_lib}" "${ios_simulator_x86_64_dynamic_headers}"; do
  if [[ ! -e "${path}" ]]; then
    printf 'missing required build output: %s\n' "${path}" >&2
    exit 1
  fi
done

rm -rf \
  "${static_xcframework_path}" "${dynamic_xcframework_path}" \
  "${static_zip_path}" "${dynamic_zip_path}" "${license_output_path}" \
  "${macos_universal_dir}" "${ios_simulator_universal_dir}" "${dynamic_frameworks_dir}"
mkdir -p \
  "${dist_dir}" \
  "${macos_universal_dir}/static/lib" "${macos_universal_dir}/dynamic/lib" \
  "${ios_simulator_universal_dir}/static/lib" "${ios_simulator_universal_dir}/dynamic/lib"

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

rsync -a --delete "${macos_arm64_static_headers}/" "${macos_static_universal_headers}/"
xcrun lipo -create "${macos_arm64_static_lib}" "${macos_x86_64_static_lib}" -output "${macos_static_universal_lib}"
rsync -a --delete "${ios_simulator_arm64_static_headers}/" "${ios_simulator_static_universal_headers}/"
xcrun lipo -create \
  "${ios_simulator_arm64_static_lib}" \
  "${ios_simulator_x86_64_static_lib}" \
  -output "${ios_simulator_static_universal_lib}"

xcodebuild -create-xcframework \
  -library "${macos_static_universal_lib}" \
  -headers "${macos_static_universal_headers}" \
  -library "${ios_device_static_lib}" \
  -headers "${ios_device_static_headers}" \
  -library "${ios_simulator_static_universal_lib}" \
  -headers "${ios_simulator_static_universal_headers}" \
  -output "${static_xcframework_path}"

rsync -a --delete "${macos_arm64_dynamic_headers}/" "${macos_dynamic_universal_headers}/"
xcrun lipo -create "${macos_arm64_dynamic_lib}" "${macos_x86_64_dynamic_lib}" -output "${macos_dynamic_universal_lib}"
xcrun lipo -create \
  "${ios_simulator_arm64_dynamic_lib}" \
  "${ios_simulator_x86_64_dynamic_lib}" \
  -output "${ios_simulator_dynamic_universal_lib}"

create_dynamic_framework "${macos_dynamic_framework}" "${macos_dynamic_universal_lib}" "${macos_dynamic_universal_headers}" "11.0"
create_dynamic_framework "${ios_device_dynamic_framework}" "${ios_device_dynamic_lib}" "${ios_device_dynamic_headers}" "13.0"
create_dynamic_framework "${ios_simulator_dynamic_framework}" "${ios_simulator_dynamic_universal_lib}" "${ios_simulator_arm64_dynamic_headers}" "13.0"

xcodebuild -create-xcframework \
  -framework "${macos_dynamic_framework}" \
  -framework "${ios_device_dynamic_framework}" \
  -framework "${ios_simulator_dynamic_framework}" \
  -output "${dynamic_xcframework_path}"

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
