#!/usr/bin/env bash
# Release signing policy for stable vs pre-release tags.
#
# Usage: release-signing-policy.sh <tag> <has_gpg_key:0|1>
#
# Prints one of: sign | publish-unsigned | fail
# Exits 0 for sign/publish-unsigned, 1 for fail (stable tag without signing key).
#
# Used by release.yml and unit-tested from validate-release.sh.
set -Eeuo pipefail

tag="${1:-}"
has_key="${2:-0}"

if [[ -z "$tag" ]]; then
  echo "usage: release-signing-policy.sh <tag> <has_gpg_key:0|1>" >&2
  exit 2
fi

if [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  stable=1
else
  stable=0
fi

if [[ -z "${has_key}" || "$has_key" == "0" ]]; then
  if [[ "$stable" -eq 1 ]]; then
    echo "fail"
    exit 1
  fi
  echo "publish-unsigned"
  exit 0
fi

echo "sign"
exit 0
