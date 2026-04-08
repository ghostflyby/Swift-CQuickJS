# Swift-CQuickJS

`Swift-CQuickJS` is a Swift Package Manager package that exposes the
`quickjs-ng` C API as a Swift-importable `CQuickJS` module.

The default implementation is vendored as a git submodule:

- Upstream: <https://github.com/quickjs-ng/quickjs>
- Path: `Vendor/quickjs`

## Package Layout

- Product: `CQuickJS`
- Target: `CQuickJS`
- Public header: `Sources/CQuickJS/include/cquickjs.h`

The target currently builds the core QuickJS engine sources:

- `Vendor/quickjs/dtoa.c`
- `Vendor/quickjs/libregexp.c`
- `Vendor/quickjs/libunicode.c`
- `Vendor/quickjs/quickjs.c`

## Downstream Override

This package is structured so downstream users can replace the implementation
by editing the package locally instead of changing their own targets.

Typical flow:

1. Add the package as a dependency.
2. Use SwiftPM's package editing workflow to edit `Swift-CQuickJS`.
3. Replace `Vendor/quickjs` or adjust the `CQuickJS` target sources/header
   export to point at your own implementation.

As long as the package continues to expose a `CQuickJS` module, downstream
Swift targets can keep importing `CQuickJS` unchanged.

## Cloning

This repository uses a submodule. Clone with:

```bash
git clone --recurse-submodules <repo-url>
```

Or after cloning:

```bash
git submodule update --init --recursive
```
