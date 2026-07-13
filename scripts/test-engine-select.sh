#!/usr/bin/env bash
# Unit-style tests for the deployment-engine contract (v1.10.0).
#
# Verifies engine normalization, the safe default (native), persistence round-trip
# through the toolkit config, and the docker helper defaults. Hermetic: no sudo,
# no Docker daemon, no network. The config file is redirected to a temp path so
# write_dev_config_file does not touch the real system config.
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0
note_fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}
pass() { echo "OK: $*"; }

TMP_CONFIG="$(mktemp /tmp/erpnext-dev-engine-config.XXXXXX)"
TMP_LEGACY="$(mktemp /tmp/erpnext-dev-engine-legacy.XXXXXX)"
cleanup() { rm -f "$TMP_CONFIG" "$TMP_LEGACY"; }
trap cleanup EXIT

# Entry-script-provided guard flags + defaults, as the real entry point sets them
# before sourcing the libs.
export ERPNEXT_DEV_ENTRY_SCRIPT="${ROOT_DIR}/erpnext-dev.sh"
export SITE_NAME="erp.test"
SITE_NAME_ENV_PROVIDED=1
SITE_NAME_SOURCE="test"
ASSUME_YES=1
DEPLOYMENT_MODE="development"
PRODUCTION_DOMAIN=""
PRODUCTION_SSL_MODE="planned"
RUNTIME_MODE=""
HOST_OS="linux"
HOST_OS_ENV_PROVIDED=1
DEPLOYMENT_ENGINE=""
DEPLOYMENT_ENGINE_ENV_PROVIDED=0
FRAPPE_USER="frappe"
BENCH_PARENT="/home/frappe/frappe"
BENCH_NAME="frappe-bench"
BENCH_DIR="/home/frappe/frappe/frappe-bench"
ERPNEXT_SERVICE_NAME="erpnext-dev.service"
DOCKER_WORKDIR="/tmp/erpnext-dev-docker-test"
DOCKER_PROJECT_NAME="erpnext-dev"
DOCKER_PUBLISH_PORT="8080"
DOCKER_ERPNEXT_IMAGE="frappe/erpnext:v16.26.2"
CONFIG_FILE="$TMP_CONFIG"
LEGACY_CONFIG_FILE="$TMP_LEGACY"

# require_sudo must be a no-op for the hermetic write test.
SUDO=""

# shellcheck disable=SC1091
source "${ROOT_DIR}/lib/common.sh"
erpnext_dev_init_terminal_colors 2>/dev/null || true
# shellcheck disable=SC1091
source "${ROOT_DIR}/lib/config.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/lib/docker.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/lib/engine.sh"

# Neutralize privilege + logging side effects for the hermetic write test.
require_sudo() { :; }
log() { :; }

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "${label}: '${actual}'"
  else
    note_fail "${label}: expected '${expected}', got '${actual}'"
  fi
}

echo "== normalization =="
assert_eq "normalize native" "native" "$(normalize_deployment_engine native)"
assert_eq "normalize Docker" "docker" "$(normalize_deployment_engine Docker)"
assert_eq "normalize container" "docker" "$(normalize_deployment_engine container)"
assert_eq "normalize vm" "native" "$(normalize_deployment_engine VM)"
if normalize_deployment_engine "bogus" >/dev/null 2>&1; then
  note_fail "normalize bogus: should have failed"
else
  pass "normalize bogus: rejected"
fi

echo "== default / effective =="
DEPLOYMENT_ENGINE=""
assert_eq "unset -> native" "native" "$(effective_deployment_engine)"
DEPLOYMENT_ENGINE="garbage"
assert_eq "garbage -> native" "native" "$(effective_deployment_engine)"
DEPLOYMENT_ENGINE="docker"
assert_eq "docker -> docker" "docker" "$(effective_deployment_engine)"
if deployment_engine_is_docker; then pass "is_docker true when docker"; else note_fail "is_docker should be true"; fi
DEPLOYMENT_ENGINE="native"
if deployment_engine_is_docker; then note_fail "is_docker should be false"; else pass "is_docker false when native"; fi

echo "== labels =="
assert_eq "label native" "Native (VM)" "$(deployment_engine_label native)"
assert_eq "label docker" "Docker" "$(deployment_engine_label docker)"

echo "== persistence round-trip =="
DEPLOYMENT_ENGINE="docker"
write_dev_config_file >/dev/null 2>&1
if grep -q '^DEPLOYMENT_ENGINE=docker$' "$TMP_CONFIG"; then
  pass "config wrote DEPLOYMENT_ENGINE=docker"
else
  note_fail "config missing DEPLOYMENT_ENGINE=docker"
  sed 's/^/    /' "$TMP_CONFIG" >&2
fi
loaded="$(read_saved_config_value DEPLOYMENT_ENGINE 2>/dev/null || echo MISSING)"
assert_eq "read back engine" "docker" "$loaded"

echo "== docker helpers (no daemon needed) =="
assert_eq "docker site default" "erp.test" "$(docker_site_name)"
assert_eq "docker site url" "http://localhost:8080" "$(docker_site_url)"
arch="$(host_arch_label)"
if [[ -n "$arch" ]]; then pass "host arch resolved: ${arch}"; else note_fail "host arch empty"; fi
os_eval="$(docker_host_os_eval)"
if [[ "$os_eval" == OK\|* || "$os_eval" == WARN\|* ]]; then
  pass "docker host os eval shape: ${os_eval%%|*}"
else
  note_fail "docker host os eval malformed: ${os_eval}"
fi

if [[ "$failures" -gt 0 ]]; then
  echo "engine-select tests: ${failures} failure(s)" >&2
  exit 1
fi
echo "engine-select tests: all checks passed"
