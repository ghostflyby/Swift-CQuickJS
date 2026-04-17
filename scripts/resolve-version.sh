#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

source_dir="${QUICKJS_SOURCE_DIR:-${UPSTREAM_SOURCE_DIR:-}}"
if [[ -z "${source_dir}" ]]; then
  if [[ -d "${repo_root}/vendor/quickjs" ]]; then
    source_dir="${repo_root}/vendor/quickjs"
  elif [[ -d "${repo_root}/../quickjs" ]]; then
    source_dir="${repo_root}/../quickjs"
  else
    source_dir="${repo_root}/vendor/quickjs"
  fi
fi

packaging_version="${PACKAGING_VERSION:-}"
upstream_repo="${UPSTREAM_REPO:-quickjs-ng/quickjs}"
upstream_ref="${UPSTREAM_REF:-}"
if [[ -z "${upstream_ref}" && -d "${source_dir}/.git" ]]; then
  upstream_ref="HEAD"
fi
upstream_ref="${upstream_ref:-HEAD}"

upstream_version="unknown"
if [[ -f "${source_dir}/meson.build" ]]; then
  upstream_version="$(
    sed -nE "s/^[[:space:]]*version:[[:space:]]*'([^']+)'.*/\1/p" "${source_dir}/meson.build" |
      head -n 1
  )"
fi
if [[ -z "${upstream_version}" || "${upstream_version}" == "unknown" ]] && [[ -f "${source_dir}/quickjs.h" ]]; then
  major="$(sed -nE 's/^#define QJS_VERSION_MAJOR[[:space:]]+([0-9]+).*/\1/p' "${source_dir}/quickjs.h" | head -n 1)"
  minor="$(sed -nE 's/^#define QJS_VERSION_MINOR[[:space:]]+([0-9]+).*/\1/p' "${source_dir}/quickjs.h" | head -n 1)"
  patch="$(sed -nE 's/^#define QJS_VERSION_PATCH[[:space:]]+([0-9]+).*/\1/p' "${source_dir}/quickjs.h" | head -n 1)"
  if [[ -n "${major}" && -n "${minor}" && -n "${patch}" ]]; then
    upstream_version="${major}.${minor}.${patch}"
  fi
fi
if [[ -z "${upstream_version}" || "${upstream_version}" == "unknown" ]]; then
  upstream_version="${upstream_ref#v}"
fi
upstream_version="${upstream_version:-unknown}"

upstream_commit="unknown"
if [[ -d "${source_dir}/.git" ]]; then
  if git -C "${source_dir}" rev-parse "${upstream_ref}^{commit}" >/dev/null 2>&1; then
    upstream_commit="$(git -C "${source_dir}" rev-parse "${upstream_ref}^{commit}")"
  elif git -C "${source_dir}" rev-parse HEAD >/dev/null 2>&1; then
    upstream_commit="$(git -C "${source_dir}" rev-parse HEAD)"
  fi
fi

case "${1:-human}" in
  --env)
    printf 'UPSTREAM_REPO=%s\n' "${upstream_repo}"
    printf 'UPSTREAM_SOURCE_DIR=%s\n' "${source_dir}"
    printf 'QUICKJS_SOURCE_DIR=%s\n' "${source_dir}"
    printf 'UPSTREAM_REF=%s\n' "${upstream_ref}"
    printf 'UPSTREAM_VERSION=%s\n' "${upstream_version}"
    printf 'UPSTREAM_COMMIT=%s\n' "${upstream_commit}"
    printf 'PACKAGING_VERSION=%s\n' "${packaging_version}"
    ;;
  *)
    printf 'upstream_repo: %s\n' "${upstream_repo}"
    printf 'upstream_source_dir: %s\n' "${source_dir}"
    printf 'upstream_ref: %s\n' "${upstream_ref}"
    printf 'upstream_version: %s\n' "${upstream_version}"
    printf 'upstream_commit: %s\n' "${upstream_commit}"
    printf 'packaging_version: %s\n' "${packaging_version}"
    ;;
esac
