#!/usr/bin/env bash

set -euo pipefail

PKGNAME="${1:-}"

if [ -z "$PKGNAME" ]; then
    # unable to resolve pkgname-version
    # compile from source
    exit 1
fi

TAG="$(git describe --tags --exact-match 2>/dev/null | head -1)"
URL="https://github.com/emqx/jq/releases/download/$TAG/$PKGNAME"

mkdir -p _packages
PKGFILE="_packages/${PKGNAME}"
if [ ! -f "$PKGFILE" ]; then
    curl -f -L -o "${PKGFILE}" "${URL}"
fi

if [ ! -f "${PKGFILE}.sha256" ]; then
    curl -f -L -o "${PKGFILE}.sha256" "${URL}.sha256"
fi

expected_sha="$(tr -d '\r' <"${PKGFILE}.sha256" | awk '{print $1}')"
if [ -z "${expected_sha}" ]; then
    echo "missing checksum in ${PKGFILE}.sha256" >&2
    exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
    actual_sha="$(sha256sum "${PKGFILE}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
    actual_sha="$(shasum -a 256 "${PKGFILE}" | awk '{print $1}')"
else
    echo "sha256sum or shasum not found" >&2
    exit 1
fi

if [ "${expected_sha}" != "${actual_sha}" ]; then
    echo "checksum mismatch for ${PKGFILE}" >&2
    exit 1
fi

tar -xzf "${PKGFILE}" -C .
