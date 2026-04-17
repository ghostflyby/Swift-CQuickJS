# Swift-CQuickJS

`Swift-CQuickJS` packages the `quickjs-ng` C API for Swift Package Manager.
It provides prebuilt Apple binary targets and a system-library target.

QuickJS source is not vendored in this repository. Release workflows checkout
the selected upstream release from <https://github.com/quickjs-ng/quickjs> into
`vendor/quickjs` during the build.

## Products

- `CQuickJSStatic`: static XCFramework binary target.
- `CQuickJSDynamic`: dynamic XCFramework binary target.
- `CQuickJSSystem`: system library target that imports an installed `quickjs-ng`
  library through `pkg-config`.

The local binary targets are expected at:

- `dist/cquickjs-static.xcframework`
- `dist/cquickjs-dynamic.xcframework`

Supported binary slices match the current build scripts:

- macOS arm64 + x86_64, minimum macOS 11.0.
- iOS arm64, minimum iOS 13.0.
- iOS Simulator arm64 + x86_64, minimum iOS 13.0.
- Mac Catalyst arm64 + x86_64, minimum iOS 13.1.
- tvOS arm64, minimum tvOS 13.0.
- tvOS Simulator arm64 + x86_64, minimum tvOS 13.0.
- watchOS arm64_32, minimum watchOS 6.0.
- watchOS Simulator arm64 + x86_64, minimum watchOS 6.0.
- visionOS arm64, minimum visionOS 1.0.
- visionOS Simulator arm64 + x86_64, minimum visionOS 1.0.

## Usage

Choose one product and import its matching module:

```swift
import CQuickJSStatic
```

or:

```swift
import CQuickJSDynamic
```

or, when linking against a system installation:

```swift
import CQuickJSSystem
```

## Building Artifacts

Checkout QuickJS-NG source first:

```bash
git clone https://github.com/quickjs-ng/quickjs vendor/quickjs
```

Build all Apple slices and package both XCFrameworks:

```bash
scripts/build-all.sh
```

The script writes intermediate build output to `out/` and distributable
artifacts to `dist/`.

You can also point at an existing checkout:

```bash
QUICKJS_SOURCE_DIR=/path/to/quickjs scripts/build-all.sh
```

To build one slice:

```bash
scripts/build-one-arch.sh macos-arm64
```

Supported slice names are:

- `macos-arm64`
- `macos-x86_64`
- `ios-arm64`
- `ios-simulator-arm64`
- `ios-simulator-x86_64`
- `maccatalyst-arm64`
- `maccatalyst-x86_64`
- `tvos-arm64`
- `tvos-simulator-arm64`
- `tvos-simulator-x86_64`
- `watchos-arm64_32`
- `watchos-simulator-arm64`
- `watchos-simulator-x86_64`
- `visionos-arm64`
- `visionos-simulator-arm64`
- `visionos-simulator-x86_64`

## Release Manifest

GitHub Actions contains two workflows:

- `build`: manually builds a selected upstream ref, packages static and dynamic
  XCFrameworks, creates a release, and commits a URL-based `Package.swift`.
- `check-upstream`: manually or daily checks the latest upstream release and
  triggers `build` when no package release exists for that upstream version.

When `packaging_version` is not provided, the workflow publishes tags as:

```text
<upstream-version>-pack.<number>
```

The `<number>` suffix is incremented from existing release tags.

For a release that hosts zipped XCFrameworks remotely, compute or reuse the
checksums in `dist/*.checksum` and generate a URL-based manifest:

```bash
scripts/write-package-swift.sh \
  <static-xcframework-zip-url> <static-checksum> \
  <dynamic-xcframework-zip-url> <dynamic-checksum>
```

## Downstream Override

This package keeps the QuickJS implementation isolated so downstream users can
edit this package and replace either `Vendor/quickjs` or the build scripts
without changing their own package graph.

When overriding, keep the public module names stable if downstream code imports
`CQuickJSStatic`, `CQuickJSDynamic`, or `CQuickJSSystem`.
