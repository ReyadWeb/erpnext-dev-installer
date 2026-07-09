#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

# ============================================================
# ERPNext / Frappe Developer Toolkit Manager
# Target: Ubuntu 24.04 / 26.04 LTS developer VM
# Default: Frappe v16 + ERPNext v16 + site erp.test
# Mode: local development using bench start
# ============================================================

APP_NAME="ERPNext Developer Toolkit"
SCRIPT_VERSION="1.1.87"

FRAPPE_USER="${FRAPPE_USER:-frappe}"
FRAPPE_HOME="/home/${FRAPPE_USER}"
BENCH_PARENT="${BENCH_PARENT:-${FRAPPE_HOME}/frappe}"
BENCH_NAME="${BENCH_NAME:-frappe-bench}"
BENCH_DIR="${BENCH_PARENT}/${BENCH_NAME}"
SITE_NAME_ENV_PROVIDED=0
if [[ -n "${SITE_NAME+x}" ]]; then
  SITE_NAME_ENV_PROVIDED=1
fi
SITE_NAME="${SITE_NAME:-erp.test}"
SITE_NAME_SOURCE="default"
DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-development}"
PRODUCTION_DOMAIN="${PRODUCTION_DOMAIN:-}"
PRODUCTION_SSL_MODE="${PRODUCTION_SSL_MODE:-planned}"
AUTO_START="${AUTO_START:-prompt}"
ENABLE_AUTOSTART="${ENABLE_AUTOSTART:-prompt}"
APP_BACKUP_BEFORE_INSTALL="${APP_BACKUP_BEFORE_INSTALL:-prompt}"
APP_BACKUP_AFTER_INSTALL="${APP_BACKUP_AFTER_INSTALL:-prompt}"
FIREWALL_BACKUP_DIR="${FIREWALL_BACKUP_DIR:-/var/backups/erpnext-dev/firewall}"
ERPNEXT_SERVICE_NAME="${ERPNEXT_SERVICE_NAME:-erpnext-dev.service}"
READY_TIMEOUT="${READY_TIMEOUT:-90}"
READY_INTERVAL="${READY_INTERVAL:-5}"
CONFIG_FILE="${CONFIG_FILE:-/etc/erpnext-dev/config.env}"
LEGACY_CONFIG_FILE="${LEGACY_CONFIG_FILE:-${FRAPPE_HOME}/erpnext-dev-config.env}"

SSL_CERT_DIR="${SSL_CERT_DIR:-/etc/erpnext-dev-ssl}"
SSL_NGINX_CONF_DIR="${SSL_NGINX_CONF_DIR:-/etc/nginx}"
SSL_REDIRECT_HTTP="${SSL_REDIRECT_HTTP:-true}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
LETSENCRYPT_STAGING="${LETSENCRYPT_STAGING:-false}"
PRODUCTION_SSL_WEBROOT="${PRODUCTION_SSL_WEBROOT:-/var/www/erpnext-production-acme}"
CLOUDFLARE_ORIGIN_DIR="${CLOUDFLARE_ORIGIN_DIR:-/etc/ssl/cloudflare-origin}"
CLOUDFLARE_ORIGIN_CERT_FILE="${CLOUDFLARE_ORIGIN_CERT_FILE:-}"
CLOUDFLARE_ORIGIN_KEY_FILE="${CLOUDFLARE_ORIGIN_KEY_FILE:-}"

FRAPPE_BRANCH="${FRAPPE_BRANCH:-version-16}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-version-16}"

NODE_VERSION="${NODE_VERSION:-24}"
PYTHON_VERSION="${PYTHON_VERSION:-3.14}"

DB_ADMIN_USER="${DB_ADMIN_USER:-frappe_db_admin}"
DB_ADMIN_PASSWORD="${DB_ADMIN_PASSWORD:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

ASSUME_YES=0
ACTION=""
DOCTOR_FORMAT="human"
# Default SUDO to an empty command prefix. Some read-only/status functions
# call helper routines before require_sudo() has initialized SUDO; with
# set -u enabled, leaving it unset can make those checks falsely fail.
SUDO="${SUDO:-}"

# Logging and locking are initialized centrally so every command path behaves
# the same way whether the toolkit is run as root, through sudo, or as a
# normal user. Keep defaults user-safe; callers may still override LOG_DIR,
# LOG_FILE, LOCK_DIR, or LOCK_FILE explicitly when needed.
LOG_DIR_WAS_SET=0
LOG_FILE_WAS_SET=0
LOCK_DIR_WAS_SET=0
LOCK_FILE_WAS_SET=0
[[ -n "${LOG_DIR+x}" ]] && LOG_DIR_WAS_SET=1
[[ -n "${LOG_FILE+x}" ]] && LOG_FILE_WAS_SET=1
[[ -n "${LOCK_DIR+x}" ]] && LOCK_DIR_WAS_SET=1
[[ -n "${LOCK_FILE+x}" ]] && LOCK_FILE_WAS_SET=1

if [[ "$LOG_DIR_WAS_SET" -eq 0 ]]; then
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    LOG_DIR="/var/log/erpnext-dev"
  else
    LOG_DIR="${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}/erpnext-dev/logs"
  fi
fi

if [[ "$LOCK_DIR_WAS_SET" -eq 0 ]]; then
  LOCK_DIR="/tmp/erpnext-dev-locks"
fi
if [[ "$LOCK_FILE_WAS_SET" -eq 0 ]]; then
  LOCK_FILE="${LOCK_DIR}/toolkit.lock"
fi

TOOLKIT_INSTALL_DIR="${TOOLKIT_INSTALL_DIR:-/opt/erpnext-dev}"
INSTALLER_CANONICAL_PATH="${INSTALLER_CANONICAL_PATH:-${TOOLKIT_INSTALL_DIR}/erpnext-dev.sh}"
TOOLKIT_CLI_PATH="${TOOLKIT_CLI_PATH:-/usr/local/bin/erpnext-dev}"
BACKUP_SCHEDULE_SERVICE="${BACKUP_SCHEDULE_SERVICE:-erpnext-dev-backup.service}"
BACKUP_SCHEDULE_TIMER="${BACKUP_SCHEDULE_TIMER:-erpnext-dev-backup.timer}"
BACKUP_SCHEDULE_ON_CALENDAR="${BACKUP_SCHEDULE_ON_CALENDAR:-daily}"
BACKUP_SCHEDULE_RANDOM_DELAY="${BACKUP_SCHEDULE_RANDOM_DELAY:-30m}"
BACKUP_RETENTION_KEEP_COMPLETE="${BACKUP_RETENTION_KEEP_COMPLETE:-14}"
BACKUP_RETENTION_WARN_DISK_PERCENT="${BACKUP_RETENTION_WARN_DISK_PERCENT:-80}"
OFF_VM_BACKUP_CONFIG_FILE="${OFF_VM_BACKUP_CONFIG_FILE:-/etc/erpnext-dev/off-vm-backup.env}"
OFF_VM_BACKUP_STATE_FILE="${OFF_VM_BACKUP_STATE_FILE:-/etc/erpnext-dev/off-vm-backup.state}"
OFF_VM_BACKUP_TARGET="${OFF_VM_BACKUP_TARGET:-}"
OFF_VM_BACKUP_SSH_IDENTITY="${OFF_VM_BACKUP_SSH_IDENTITY:-}"
OFF_VM_BACKUP_DEFAULT_IDENTITY="${OFF_VM_BACKUP_DEFAULT_IDENTITY:-/root/.ssh/erpnext_offvm_backup}"
RESTORE_BACKUP_SSH_IDENTITY="${RESTORE_BACKUP_SSH_IDENTITY:-/root/.ssh/erpnext_restore_backup}"
RESTORE_PULL_CONFIG_FILE="${RESTORE_PULL_CONFIG_FILE:-/etc/erpnext-dev/restore-pull.env}"
RESTORE_REHEARSAL_RECORD_FILE="${RESTORE_REHEARSAL_RECORD_FILE:-/etc/erpnext-dev/restore-rehearsal.env}"
RESTORE_AUTHORIZED_KEYS_USER="${RESTORE_AUTHORIZED_KEYS_USER:-erpbackup}"
OFF_VM_BACKUP_RSYNC_DELETE="${OFF_VM_BACKUP_RSYNC_DELETE:-false}"
HEALTH_CHECK_SERVICE="${HEALTH_CHECK_SERVICE:-erpnext-dev-health-check.service}"
HEALTH_CHECK_TIMER="${HEALTH_CHECK_TIMER:-erpnext-dev-health-check.timer}"
HEALTH_CHECK_STATE_FILE="${HEALTH_CHECK_STATE_FILE:-/etc/erpnext-dev/health-check.state}"
HEALTH_CHECK_ON_CALENDAR="${HEALTH_CHECK_ON_CALENDAR:-hourly}"
HEALTH_CHECK_RANDOM_DELAY="${HEALTH_CHECK_RANDOM_DELAY:-10m}"
HEALTH_CHECK_DISK_WARN_PERCENT="${HEALTH_CHECK_DISK_WARN_PERCENT:-80}"
HEALTH_CHECK_BACKUP_MAX_AGE_HOURS="${HEALTH_CHECK_BACKUP_MAX_AGE_HOURS:-30}"
GO_LIVE_RECORD_FILE="${GO_LIVE_RECORD_FILE:-/etc/erpnext-dev/go-live-validation.env}"

# Hard safety gates for fresh installs. These are intentionally conservative because
# a too-small VM can leave a half-installed ERPNext stack, corrupt user expectations,
# or create an unstable service that is difficult for beginners to recover.
MIN_INSTALL_CPU_CORES="${MIN_INSTALL_CPU_CORES:-2}"
RECOMMENDED_INSTALL_CPU_CORES="${RECOMMENDED_INSTALL_CPU_CORES:-4}"
MIN_INSTALL_RAM_MB="${MIN_INSTALL_RAM_MB:-4096}"
RECOMMENDED_INSTALL_RAM_MB="${RECOMMENDED_INSTALL_RAM_MB:-8192}"
MIN_INSTALL_DISK_GB="${MIN_INSTALL_DISK_GB:-30}"
RECOMMENDED_INSTALL_DISK_GB="${RECOMMENDED_INSTALL_DISK_GB:-60}"
MIN_INSTALL_TMP_GB="${MIN_INSTALL_TMP_GB:-4}"
ERPNEXT_ALLOW_UNSAFE_INSTALL="${ERPNEXT_ALLOW_UNSAFE_INSTALL:-false}"

_ERPNEXT_DEV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/common.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/common.sh" >&2
  exit 1
fi
# shellcheck source=lib/common.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/common.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/config.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/config.sh" >&2
  exit 1
fi
# shellcheck source=lib/config.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/config.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/access.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/access.sh" >&2
  exit 1
fi
# shellcheck source=lib/access.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/access.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/support.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/support.sh" >&2
  exit 1
fi
# shellcheck source=lib/support.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/support.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/backup.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/backup.sh" >&2
  exit 1
fi
# shellcheck source=lib/backup.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/backup.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/ssl.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/ssl.sh" >&2
  exit 1
fi
# shellcheck source=lib/ssl.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/ssl.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/firewall.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/firewall.sh" >&2
  exit 1
fi
# shellcheck source=lib/firewall.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/firewall.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/apps.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/apps.sh" >&2
  exit 1
fi
# shellcheck source=lib/apps.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/apps.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/health.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/health.sh" >&2
  exit 1
fi
# shellcheck source=lib/health.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/health.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/storage.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/storage.sh" >&2
  exit 1
fi
# shellcheck source=lib/storage.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/storage.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/service.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/service.sh" >&2
  exit 1
fi
# shellcheck source=lib/service.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/service.sh"
if [[ ! -f "${_ERPNEXT_DEV_ROOT}/lib/install.sh" ]]; then
  echo "ERROR: Missing toolkit library: ${_ERPNEXT_DEV_ROOT}/lib/install.sh" >&2
  exit 1
fi
# shellcheck source=lib/install.sh disable=SC1091
source "${_ERPNEXT_DEV_ROOT}/lib/install.sh"
erpnext_dev_init_terminal_colors

prepare_log_file
exec > >(tee -a "$LOG_FILE") 2>&1

install_toolkit_cli_entry() {
  local dest cli_dir
  dest="${INSTALLER_CANONICAL_PATH:-/opt/erpnext-dev/erpnext-dev.sh}"
  cli_dir="$(dirname "${TOOLKIT_CLI_PATH:-/usr/local/bin/erpnext-dev}")"
  mkdir -p "$cli_dir" 2>/dev/null || return 1
  ln -sf "$dest" "${TOOLKIT_CLI_PATH:-/usr/local/bin/erpnext-dev}" 2>/dev/null || return 1
  chmod 755 "${TOOLKIT_CLI_PATH:-/usr/local/bin/erpnext-dev}" 2>/dev/null || true
  return 0
}

install_self_for_reuse() {
  # One-command quickstart runs from a temporary /tmp bootstrap file. Copy the active
  # toolkit into /opt and expose the short erpnext-dev command for future use.
  local src dest src_root dest_root
  dest="${INSTALLER_CANONICAL_PATH:-/opt/erpnext-dev/erpnext-dev.sh}"
  src="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || true)"
  [[ -n "$src" && -f "$src" ]] || return 0

  src_root="$(cd "$(dirname "$src")" && pwd)"
  dest_root="$(dirname "$dest")"
  mkdir -p "$dest_root" 2>/dev/null || true

  if [[ "$src" != "$dest" ]]; then
    if cp "$src" "$dest" 2>/dev/null; then
      chmod 755 "$dest" 2>/dev/null || true
      chown root:root "$dest" 2>/dev/null || true
    fi
  else
    chmod 755 "$dest" 2>/dev/null || true
    chown root:root "$dest" 2>/dev/null || true
  fi

  sync_toolkit_lib_tree "$src_root" "$dest_root" 2>/dev/null || warn "Could not copy toolkit lib/ tree to ${dest_root}/lib"

  install_toolkit_cli_entry 2>/dev/null || true
}


show_where_installed() {
  local src stable_state cli_state cli_target config_state
  src="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo unknown)"
  if [[ -x "${INSTALLER_CANONICAL_PATH}" ]]; then
    stable_state="OK"
  else
    stable_state="WARN"
  fi
  if [[ -x "${TOOLKIT_CLI_PATH}" ]]; then
    cli_state="OK"
    cli_target="$(readlink -f "${TOOLKIT_CLI_PATH}" 2>/dev/null || echo "${TOOLKIT_CLI_PATH}")"
  else
    cli_state="WARN"
    cli_target="not installed"
  fi
  if [[ -f "${CONFIG_FILE}" ]]; then
    config_state="OK"
  else
    config_state="INFO"
  fi

  ui_box_start "ERPNext Toolkit Installation"
  status_line "Version" "INFO" "${SCRIPT_VERSION}"
  status_line "Active script" "INFO" "${src}"
  status_line "Stable toolkit" "${stable_state}" "${INSTALLER_CANONICAL_PATH}"
  status_line "CLI command" "${cli_state}" "${TOOLKIT_CLI_PATH}${cli_target:+ -> ${cli_target}}"
  status_line "Config file" "${config_state}" "${CONFIG_FILE}"
  status_line "Short command" "INFO" "erpnext-dev"
  ui_box_end
}

find_toolkit_checksum_file() {
  local active_dir stable_dir candidate
  active_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")")"
  stable_dir="$(dirname "${INSTALLER_CANONICAL_PATH:-/opt/erpnext-dev/erpnext-dev.sh}")"

  for candidate in \
    "${CHECKSUM_FILE:-}" \
    "${TOOLKIT_CHECKSUM_FILE:-}" \
    "./SHA256SUMS" \
    "${active_dir}/SHA256SUMS" \
    "${stable_dir}/SHA256SUMS" \
    "/opt/erpnext-dev/SHA256SUMS"; do
    [[ -n "$candidate" && -f "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done
  return 1
}

checksum_expected_for_toolkit() {
  local checksum_file="$1"
  awk '
    $2 == "erpnext-dev.sh" { print $1; found=1; exit }
    $2 == "./erpnext-dev.sh" { print $1; found=1; exit }
    $2 ~ /\/erpnext-dev\.sh$/ { print $1; found=1; exit }
    END { if (!found) exit 1 }
  ' "$checksum_file"
}

verify_toolkit_integrity() {
  local active stable cli_target checksum_file expected active_hash stable_hash cli_hash match_state=0
  active="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")"
  stable="${INSTALLER_CANONICAL_PATH:-/opt/erpnext-dev/erpnext-dev.sh}"
  cli_target="$(readlink -f "${TOOLKIT_CLI_PATH:-/usr/local/bin/erpnext-dev}" 2>/dev/null || true)"

  ui_box_start "Verify ERPNext Toolkit Integrity"
  status_line "Toolkit version" "INFO" "${SCRIPT_VERSION}"
  status_line "Active script" "$([[ -f "$active" ]] && echo OK || echo WARN)" "$active"
  status_line "Stable toolkit" "$([[ -f "$stable" ]] && echo OK || echo WARN)" "$stable"
  if [[ -n "$cli_target" ]]; then
    status_line "CLI command" "OK" "${TOOLKIT_CLI_PATH:-/usr/local/bin/erpnext-dev} -> ${cli_target}"
  else
    status_line "CLI command" "WARN" "${TOOLKIT_CLI_PATH:-/usr/local/bin/erpnext-dev} not found"
  fi

  if ! command -v sha256sum >/dev/null 2>&1; then
    status_line "sha256sum" "FAIL" "sha256sum command not found"
    ui_box_end
    return 1
  fi

  if [[ -f "$active" ]]; then
    active_hash="$(sha256sum "$active" | awk '{print $1}')"
    status_line "Active SHA256" "INFO" "$active_hash"
  fi
  if [[ -f "$stable" ]]; then
    stable_hash="$(sha256sum "$stable" | awk '{print $1}')"
    status_line "Stable SHA256" "INFO" "$stable_hash"
  fi
  if [[ -n "$cli_target" && -f "$cli_target" ]]; then
    cli_hash="$(sha256sum "$cli_target" | awk '{print $1}')"
    status_line "CLI SHA256" "INFO" "$cli_hash"
  fi

  if checksum_file="$(find_toolkit_checksum_file 2>/dev/null)"; then
    status_line "Checksum file" "OK" "$checksum_file"
    if expected="$(checksum_expected_for_toolkit "$checksum_file" 2>/dev/null)"; then
      status_line "Expected SHA256" "INFO" "$expected"
      if [[ -n "${active_hash:-}" && "$active_hash" == "$expected" ]]; then
        status_line "Active match" "OK" "active script matches SHA256SUMS"
      else
        status_line "Active match" "FAIL" "active script does not match SHA256SUMS"
        match_state=1
      fi
      if [[ -n "${stable_hash:-}" ]]; then
        if [[ "$stable_hash" == "$expected" ]]; then
          status_line "Stable match" "OK" "stable toolkit matches SHA256SUMS"
        else
          status_line "Stable match" "WARN" "stable toolkit does not match SHA256SUMS"
        fi
      fi
      if [[ -n "${cli_hash:-}" ]]; then
        if [[ "$cli_hash" == "$expected" ]]; then
          status_line "CLI match" "OK" "CLI target matches SHA256SUMS"
        else
          status_line "CLI match" "WARN" "CLI target does not match SHA256SUMS"
        fi
      fi
    else
      status_line "Expected SHA256" "WARN" "no erpnext-dev.sh entry found in checksum file"
    fi
  else
    status_line "Checksum file" "WARN" "not found; download SHA256SUMS beside erpnext-dev.sh or set CHECKSUM_FILE=/path/SHA256SUMS"
  fi

  echo
  echo "Verified stable-path update example:"
  echo "  VERSION=\"v${SCRIPT_VERSION}\""
  echo '  workdir="$(mktemp -d /tmp/erpnext-dev-update.XXXXXX)"; cd "$workdir" || exit 1'
  echo '  curl -fsSLO "https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/${VERSION}/erpnext-dev.sh"'
  echo '  curl -fsSLO "https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/${VERSION}/SHA256SUMS"'
  echo "  sha256sum -c SHA256SUMS"
  echo "  sudo mkdir -p /opt/erpnext-dev"
  echo "  sudo install -m 0755 erpnext-dev.sh /opt/erpnext-dev/erpnext-dev.sh"
  echo "  sudo install -m 0644 SHA256SUMS /opt/erpnext-dev/SHA256SUMS"
  echo "  sudo ln -sf /opt/erpnext-dev/erpnext-dev.sh /usr/local/bin/erpnext-dev"
  echo "  sudo erpnext-dev verify-toolkit"
  ui_box_end
  return "$match_state"
}

install_toolkit_cli() {
  require_sudo
  install_self_for_reuse
  ui_box_start "Install ERPNext Toolkit CLI"
  if [[ -x "${INSTALLER_CANONICAL_PATH}" ]]; then
    status_line "Stable toolkit" "OK" "${INSTALLER_CANONICAL_PATH}"
  else
    status_line "Stable toolkit" "FAIL" "${INSTALLER_CANONICAL_PATH} missing"
    ui_box_end
    return 1
  fi

  if install_toolkit_cli_entry; then
    status_line "CLI command" "OK" "${TOOLKIT_CLI_PATH}"
    echo
    echo "You can now run:"
    echo "  erpnext-dev --help"
    echo "  sudo erpnext-dev menu"
  else
    status_line "CLI command" "FAIL" "could not create ${TOOLKIT_CLI_PATH}"
    ui_box_end
    return 1
  fi
  ui_box_end
}

repair_toolkit_cli() {
  install_toolkit_cli
}

update_toolkit() {
  require_sudo
  local url tmp lib_file lib_url lib_dest lib_dir cache_bust
  url="https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/erpnext-dev.sh?cache_bust=$(date +%s)"
  cache_bust="$(date +%s)"
  tmp="$(mktemp /tmp/erpnext-dev-update.XXXXXX.sh)" || fail "Could not create temporary update file."

  ui_box_start "Update ERPNext Toolkit"
  status_line "Download URL" "INFO" "$url"
  status_line "Temporary file" "INFO" "$tmp"
  status_line "Stable toolkit" "INFO" "$INSTALLER_CANONICAL_PATH"

  command -v curl >/dev/null 2>&1 || fail "curl is required. Install it with: sudo apt-get install -y curl ca-certificates"

  log "Downloading latest toolkit"
  curl -fsSL "$url" -o "$tmp" || fail "Failed to download latest toolkit."
  chmod +x "$tmp"
  bash -n "$tmp" || fail "Downloaded toolkit failed bash syntax validation."

  mkdir -p "$(dirname "$INSTALLER_CANONICAL_PATH")"
  cp "$tmp" "$INSTALLER_CANONICAL_PATH"
  chmod 755 "$INSTALLER_CANONICAL_PATH"
  chown root:root "$INSTALLER_CANONICAL_PATH" 2>/dev/null || true

  lib_dir="$(dirname "$INSTALLER_CANONICAL_PATH")/lib"
  mkdir -p "$lib_dir"
  for lib_file in common.sh config.sh access.sh support.sh backup.sh ssl.sh firewall.sh apps.sh health.sh storage.sh service.sh install.sh; do
    lib_url="https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/lib/${lib_file}?cache_bust=${cache_bust}"
    lib_dest="${lib_dir}/${lib_file}"
    if curl -fsSL "$lib_url" -o "$lib_dest"; then
      chmod 644 "$lib_dest" 2>/dev/null || true
      chown root:root "$lib_dest" 2>/dev/null || true
      status_line "Library ${lib_file}" "OK" "$lib_dest"
    else
      status_line "Library ${lib_file}" "WARN" "could not download lib/${lib_file}"
    fi
  done

  install_toolkit_cli_entry || fail "Updated toolkit, but failed to recreate ${TOOLKIT_CLI_PATH}."

  ok "Toolkit updated."
  "$INSTALLER_CANONICAL_PATH" version
  ui_box_end
}





path_is_dir() {
  local path="$1"

  [[ -d "$path" ]] && return 0

  if [[ "${SUDO:-}" == "sudo" ]]; then
    $SUDO test -d "$path" 2>/dev/null
  else
    test -d "$path" 2>/dev/null
  fi
}

path_is_file() {
  local path="$1"

  [[ -f "$path" ]] && return 0

  if [[ "${SUDO:-}" == "sudo" ]]; then
    $SUDO test -f "$path" 2>/dev/null
  else
    test -f "$path" 2>/dev/null
  fi
}

path_is_executable() {
  local path="$1"

  [[ -x "$path" ]] && return 0

  if [[ "${SUDO:-}" == "sudo" ]]; then
    $SUDO test -x "$path" 2>/dev/null
  else
    test -x "$path" 2>/dev/null
  fi
}

bench_dir_is_valid() {
  local candidate="$1"

  path_is_dir "$candidate" && path_is_dir "$candidate/apps/frappe" && path_is_dir "$candidate/sites"
}

require_bench_dir() {
  local bench_dir

  if bench_dir="$(detect_bench_dir 2>/dev/null)" && path_is_dir "$bench_dir"; then
    echo "$bench_dir"
    return 0
  fi

  err "Bench folder not found. Expected one of:"
  bench_dir_candidates | awk '{print "  - " $0}' >&2
  err "Run Recommended Setup first, or run: $(toolkit_cmd install-status)"
  return 1
}


erpnext_vm_context_detected() {
  local candidate

  # Do not use sudo here. This is a safety check that should run without
  # modifying the host or prompting for a password.
  while IFS= read -r candidate; do
    [[ -z "$candidate" ]] && continue
    if [[ -d "$candidate/apps/frappe" && -d "$candidate/sites" ]]; then
      return 0
    fi
  done < <(bench_dir_candidates 2>/dev/null | awk '!seen[$0]++')

  [[ -f "$(erpnext_service_path)" ]] && return 0
  [[ -x "${FRAPPE_HOME}/start-erpnext-dev.sh" ]] && return 0
  [[ -f "${FRAPPE_HOME}/erpnext-dev-credentials.txt" ]] && return 0

  return 1
}

show_environment_check() {
  local host user cwd vm_ip detected_bench="missing"
  host="$(hostname 2>/dev/null || echo unknown)"
  user="$(id -un 2>/dev/null || echo unknown)"
  cwd="$(pwd 2>/dev/null || echo unknown)"
  vm_ip="$(get_vm_ip 2>/dev/null || echo unknown)"

  if detect_bench_dir >/dev/null 2>&1; then
    detected_bench="$(detect_bench_dir 2>/dev/null || true)"
  fi

  echo
  echo "============================================================"
  echo "Environment / Location Check"
  echo "============================================================"
  status_line "Current host" "INFO" "$host"
  status_line "Current user" "INFO" "$user"
  status_line "Current directory" "INFO" "$cwd"
  status_line "Detected IP" "INFO" "$vm_ip"
  status_line "Expected site" "INFO" "$SITE_NAME"
  status_line "Site source" "INFO" "$SITE_NAME_SOURCE"
  status_line "Config file" "INFO" "$CONFIG_FILE"
  status_line "Expected bench" "INFO" "$BENCH_DIR"
  if [[ "$detected_bench" == "missing" ]] && { service_exists || path_is_file "${FRAPPE_HOME}/erpnext-dev-credentials.txt" || path_is_executable "${FRAPPE_HOME}/start-erpnext-dev.sh"; }; then
    detected_bench="${BENCH_DIR} (expected; run doctor for sudo-confirmed status)"
  fi
  status_line "Detected bench" "INFO" "$detected_bench"

  if erpnext_vm_context_detected; then
    status_line "ERPNext VM context" "OK" "this looks like the ERPNext VM"
    echo
    echo "VM-only actions are allowed here, including:"
    echo "  $(toolkit_cmd ssl-status)"
    echo "  $(toolkit_cmd configure-local-ssl)"
    echo "  $(toolkit_cmd install-local-ssl-cert)"
  else
    status_line "ERPNext VM context" "WARN" "not detected"
    echo
    echo "This looks like the HOST machine, not the ERPNext VM."
    echo
    echo "Run VM-only commands after SSHing into the VM, for example:"
    echo "  ssh test@VM_IP"
    echo
    echo "Host-side commands are OK here, for example:"
    echo "  mkcert -install"
    echo "  mkcert -cert-file ${SITE_NAME}.crt -key-file ${SITE_NAME}.key ${SITE_NAME} VM_IP"
    echo "  scp ${SITE_NAME}.crt test@VM_IP:/tmp/${SITE_NAME}.crt"
    echo "  curl -I http://${SITE_NAME}"
    echo "  curl -kI https://${SITE_NAME}"
  fi

  echo "============================================================"
}

show_vm_only_guard_message() {
  local action="$1"
  local vm_ip
  vm_ip="$(get_vm_ip 2>/dev/null || true)"

  echo
  echo "============================================================"
  echo "Wrong Machine / VM-Only Command Guard"
  echo "============================================================"
  warn "The command '${action}' must be run inside the ERPNext VM."
  echo
  echo "This script did not detect the ERPNext bench, service, helper, or credentials on this machine."
  echo "To avoid changing the Linux HOST by mistake, the command was blocked before sudo work."
  echo
  echo "Current machine:"
  echo "  Hostname: $(hostname 2>/dev/null || echo unknown)"
  echo "  User:     $(id -un 2>/dev/null || echo unknown)"
  echo "  Folder:   $(pwd 2>/dev/null || echo unknown)"
  echo
  echo "Run this command inside the VM instead. Example:"
  if [[ -n "$vm_ip" && "$vm_ip" != "unknown" ]]; then
    echo "  ssh test@${vm_ip}"
  else
    echo "  ssh test@VM_IP"
  fi
  echo "  $(toolkit_cmd "${action}")"
  echo
  echo "Commands that belong on the HOST:"
  echo "  mkcert -install"
  echo "  mkcert -cert-file ${SITE_NAME}.crt -key-file ${SITE_NAME}.key ${SITE_NAME} VM_IP"
  echo "  scp ${SITE_NAME}.crt test@VM_IP:/tmp/${SITE_NAME}.crt"
  echo "  scp ${SITE_NAME}.key test@VM_IP:/tmp/${SITE_NAME}.key"
  echo "  curl -I http://${SITE_NAME}"
  echo "  curl -kI https://${SITE_NAME}"
  echo
  echo "To check where you are, run:"
  echo "  $(toolkit_cmd environment-check)"
  echo "============================================================"
}

require_erpnext_vm_context() {
  local action="$1"
  if erpnext_vm_context_detected; then
    return 0
  fi
  show_vm_only_guard_message "$action"
  return 1
}




frappe_shell_prefix() {
  # Keep this as a semicolon-separated single line.
  # Some sudo/su command paths can collapse multiline command substitution, which breaks
  # constructs like: export NVM_DIR=...if [ -s ... ]. Semicolons make the prefix robust.
  cat <<'EOF_PREFIX'
export PATH="$HOME/.local/bin:$PATH"; export NVM_DIR="$HOME/.nvm"; if [ -s "$NVM_DIR/nvm.sh" ]; then . "$NVM_DIR/nvm.sh"; fi; if command -v node >/dev/null 2>&1; then export PATH="$(dirname "$(command -v node)"):$PATH"; fi;
EOF_PREFIX
}

frappe_login_bash() {
  # Read a Bash script from stdin and execute it as the frappe user.
  # This must work both when the toolkit is run as root and when it is run
  # by a sudo-capable non-root user. Do not prefix sudo options with an empty
  # $SUDO value; root would otherwise try to execute "-H" as a command.
  if [[ "${EUID}" -eq 0 ]]; then
    su - "$FRAPPE_USER" -s /bin/bash
  else
    sudo -H -u "$FRAPPE_USER" bash
  fi
}

run_as_frappe() {
  local cmd="$1"
  local prefix
  local tmp_script
  local rc

  if ! id "$FRAPPE_USER" >/dev/null 2>&1; then
    return 1
  fi

  prefix="$(frappe_shell_prefix)"
  tmp_script="$(mktemp /tmp/erpnext-dev-frappe-run.XXXXXX.sh)" || return 1

  {
    echo '#!/usr/bin/env bash'
    echo 'set -o pipefail'
    echo "$prefix"
    printf '%s\n' "$cmd"
  } > "$tmp_script"

  chmod 700 "$tmp_script"

  if [[ "${EUID}" -eq 0 ]]; then
    chown "$FRAPPE_USER:$FRAPPE_USER" "$tmp_script" 2>/dev/null || true
    su - "$FRAPPE_USER" -s /bin/bash -c "bash '$tmp_script'"
    rc=$?
    rm -f "$tmp_script"
  else
    sudo chown "$FRAPPE_USER:$FRAPPE_USER" "$tmp_script" 2>/dev/null || true
    sudo -iu "$FRAPPE_USER" bash "$tmp_script"
    rc=$?
    sudo rm -f "$tmp_script" 2>/dev/null || rm -f "$tmp_script"
  fi

  return "$rc"
}

run_as_frappe_quiet() {
  local label="$1"
  local cmd="$2"
  local safe_label output_file fallback_dir rc

  safe_label="$(printf '%s' "$label" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9_.-')"
  [[ -n "$safe_label" ]] || safe_label="command"

  output_file="$(mktemp "${LOG_DIR}/erpnext-dev-${safe_label}.XXXXXX.log" 2>/dev/null || true)"
  if [[ -z "$output_file" ]]; then
    fallback_dir="/tmp/erpnext-dev-${EUID:-$(id -u)}-logs"
    mkdir -p "$fallback_dir" 2>/dev/null || true
    chmod 700 "$fallback_dir" 2>/dev/null || true
    output_file="$(mktemp "${fallback_dir}/erpnext-dev-${safe_label}.XXXXXX.log")" || return 1
  fi
  chmod 600 "$output_file" 2>/dev/null || true

  echo "  Output log: ${output_file}"
  if run_as_frappe "$cmd" >"$output_file" 2>&1; then
    return 0
  fi

  rc=$?
  warn "${label} failed. Last 80 lines from ${output_file}:"
  tail -n 80 "$output_file" 2>/dev/null | sed 's/^/  /' || true
  return "$rc"
}






















bench_dir_candidates() {
  printf '%s\n' \
    "${BENCH_DIR}" \
    "${FRAPPE_HOME}/${BENCH_NAME}" \
    "${FRAPPE_HOME}/frappe/${BENCH_NAME}"
}

detect_bench_dir() {
  local candidate found=""

  while IFS= read -r candidate; do
    [[ -z "$candidate" ]] && continue
    if bench_dir_is_valid "$candidate"; then
      echo "$candidate"
      return 0
    fi
    if [[ -z "$found" ]] && path_is_dir "$candidate"; then
      found="$candidate"
    fi
  done < <(bench_dir_candidates | awk '!seen[$0]++')

  if path_is_dir "$FRAPPE_HOME"; then
    if [[ "${SUDO:-}" == "sudo" ]]; then
      candidate="$($SUDO find "$FRAPPE_HOME" -maxdepth 3 -type d -name "$BENCH_NAME" 2>/dev/null | head -n 1 || true)"
    else
      candidate="$(find "$FRAPPE_HOME" -maxdepth 3 -type d -name "$BENCH_NAME" 2>/dev/null | head -n 1 || true)"
    fi
    if [[ -n "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  fi

  if [[ -n "$found" ]]; then
    echo "$found"
    return 0
  fi

  echo "$BENCH_DIR"
  return 1
}

active_bench_dir() {
  local detected

  detected="$(detect_bench_dir 2>/dev/null || true)"
  if [[ -n "$detected" ]]; then
    printf '%s
' "$detected" | head -n 1
  else
    echo "$BENCH_DIR"
  fi
}


bench_site_candidates() {
  local bench_dir="$1"
  local site

  [[ -d "${bench_dir}/sites" ]] || return 1

  if [[ -n "${SUDO:-}" && "${SUDO:-}" == "sudo" ]]; then
    $SUDO find "${bench_dir}/sites" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" 2>/dev/null \
      | grep -Ev "^(assets|private|public|logs|__pycache__)$" \
      | sort
  else
    find "${bench_dir}/sites" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" 2>/dev/null \
      | grep -Ev "^(assets|private|public|logs|__pycache__)$" \
      | sort
  fi
}

detect_site_name_from_bench() {
  local bench_dir current_site default_site sites_count first_site
  bench_dir="$(active_bench_dir)"

  [[ -d "$bench_dir" ]] || return 1

  if [[ -n "${SUDO:-}" && "${SUDO:-}" == "sudo" ]]; then
    current_site="$($SUDO cat "${bench_dir}/sites/currentsite.txt" 2>/dev/null | head -n 1 || true)"
  else
    current_site="$(cat "${bench_dir}/sites/currentsite.txt" 2>/dev/null | head -n 1 || true)"
  fi
  if [[ -n "$current_site" ]] && validate_site_name_value "$current_site" >/dev/null 2>&1; then
    echo "$current_site"
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    if [[ -n "${SUDO:-}" && "${SUDO:-}" == "sudo" ]]; then
      default_site="$($SUDO python3 - "$bench_dir" <<'PY_SITE_DEFAULT' 2>/dev/null || true
import json, sys
from pathlib import Path
p = Path(sys.argv[1]) / "sites" / "common_site_config.json"
try:
    print(json.loads(p.read_text()).get("default_site", ""))
except Exception:
    pass
PY_SITE_DEFAULT
)"
    else
      default_site="$(python3 - "$bench_dir" <<'PY_SITE_DEFAULT' 2>/dev/null || true
import json, sys
from pathlib import Path
p = Path(sys.argv[1]) / "sites" / "common_site_config.json"
try:
    print(json.loads(p.read_text()).get("default_site", ""))
except Exception:
    pass
PY_SITE_DEFAULT
)"
    fi
    if [[ -n "$default_site" ]] && validate_site_name_value "$default_site" >/dev/null 2>&1; then
      echo "$default_site"
      return 0
    fi
  fi

  sites_count="$(bench_site_candidates "$bench_dir" | wc -l | tr -d ' ' || echo 0)"
  if [[ "$sites_count" == "1" ]]; then
    first_site="$(bench_site_candidates "$bench_dir" | head -n 1)"
    if [[ -n "$first_site" ]] && validate_site_name_value "$first_site" >/dev/null 2>&1; then
      echo "$first_site"
      return 0
    fi
  fi

  return 1
}

resolve_site_name_after_sudo() {
  local saved detected

  if [[ "$SITE_NAME_ENV_PROVIDED" -eq 1 ]]; then
    SITE_NAME_SOURCE="environment"
    return 0
  fi

  if [[ "$SITE_NAME_SOURCE" == "setup prompt" || "$SITE_NAME_SOURCE" == "domain wizard" || "$SITE_NAME_SOURCE" == "local quickstart" ]]; then
    return 0
  fi

  if saved="$(read_saved_site_name_with_sudo 2>/dev/null)" && [[ -n "$saved" ]]; then
    if validate_site_name_value "$saved" >/dev/null 2>&1; then
      SITE_NAME="$saved"
      SITE_NAME_SOURCE="saved config"
      return 0
    fi
  fi

  if detected="$(detect_site_name_from_bench 2>/dev/null)" && [[ -n "$detected" ]]; then
    if validate_site_name_value "$detected" >/dev/null 2>&1; then
      SITE_NAME="$detected"
      SITE_NAME_SOURCE="detected bench site"
      return 0
    fi
  fi

  return 0
}

check_bench_app_installed() {
  local app="$1"
  local bench_dir
  bench_dir="$(active_bench_dir)"

  path_is_dir "${bench_dir}/apps/${app}"
}

site_exists() {
  local bench_dir
  bench_dir="$(active_bench_dir)"

  path_is_dir "${bench_dir}/sites/${SITE_NAME}"
}

site_app_installed() {
  local app="$1"
  local bench_dir
  bench_dir="$(active_bench_dir)"

  if ! path_is_dir "$bench_dir" || ! path_is_dir "${bench_dir}/sites/${SITE_NAME}"; then
    return 1
  fi

  run_as_frappe "cd '${bench_dir}' && bench --site '${SITE_NAME}' list-apps" 2>/dev/null | awk '{print $1}' | grep -qx "$app"
}


recommended_action() {
  local installed runtime auto
  installed="$1"
  runtime="$2"
  auto="$3"

  case "$installed" in
    "Installed"|"Installed files found; site app not confirmed")
      if [[ "$runtime" == Running* ]]; then
        if [[ "$auto" == "Enabled" ]]; then
          echo "ERPNext is ready. Open the browser URL below."
        else
          echo "ERPNext is running. Optional: enable autostart with $(toolkit_cmd enable-autostart)"
        fi
      else
        echo "Start ERPNext with $(toolkit_cmd start)"
      fi
      ;;
    "Incomplete")
      echo "Run $(toolkit_cmd repair), or run setup for a clean reinstall."
      ;;
    *)
      echo "Run $(toolkit_cmd setup)"
      ;;
  esac
}

run_status() {
  require_sudo

  local vm_ip installed runtime auto svc bench_dir url_status
  vm_ip="$(get_vm_ip)"
  installed="$(install_state)"
  runtime="$(runtime_state)"
  auto="$(autostart_state)"
  svc="$(service_state)"
  bench_dir="$(active_bench_dir)"

  echo
  echo "============================================================"
  echo "ERPNext Developer Status"
  echo "============================================================"
  printf "  %-18s %s\n" "Install:" "$installed"
  printf "  %-18s %s\n" "Runtime:" "$runtime"
  printf "  %-18s %s\n" "Service:" "$svc"
  printf "  %-18s %s\n" "Autostart:" "$auto"
  printf "  %-18s %s\n" "Site:" "$SITE_NAME"
  printf "  %-18s %s\n" "VM IP:" "$vm_ip"
  printf "  %-18s http://%s:8000\n" "Direct URL:" "$vm_ip"
  printf "  %-18s http://%s:8000\n" "Friendly URL:" "$SITE_NAME"
  echo
  echo "Recommended action:"
  echo "  $(recommended_action "$installed" "$runtime" "$auto")"
  echo
  echo "Notes:"
  echo "  - Direct URL works after ERPNext is running."
  echo "  - Friendly URL also needs the HOST /etc/hosts entry: ${vm_ip} ${SITE_NAME}"
  echo "  - Detailed diagnostics: $(toolkit_cmd doctor)"
  echo "============================================================"
}

run_runtime_status() {
  require_sudo

  echo
  echo "============================================================"
  echo "ERPNext Runtime Status"
  echo "============================================================"
  local runtime_status service_status autostart_status
  runtime_status="$(runtime_state)"
  service_status="$(service_state)"
  autostart_status="$(autostart_state)"

  if [[ "$runtime_status" == Running* ]]; then
    status_line "Runtime" "OK" "$runtime_status"
  elif [[ "$runtime_status" == Starting* ]]; then
    status_line "Runtime" "WARN" "$runtime_status"
  else
    status_line "Runtime" "INFO" "$runtime_status"
  fi

  if [[ "$service_status" == "Running" ]]; then
    status_line "Service" "OK" "$service_status"
  elif [[ "$service_status" == "Not configured" ]]; then
    status_line "Service" "WARN" "$service_status"
  else
    status_line "Service" "INFO" "$service_status"
  fi

  if [[ "$autostart_status" == "Enabled" ]]; then
    status_line "Autostart" "OK" "$autostart_status"
  else
    status_line "Autostart" "WARN" "$autostart_status"
  fi

  local item port label
  local port_checks=(
    "8000:Bench web"
    "9000:Socket.io"
    "11000:Bench Redis queue"
    "13000:Bench Redis cache"
  )

  for item in "${port_checks[@]}"; do
    port="${item%%:*}"
    label="${item#*:}"
    if port_listens "$port"; then
      status_line "$label" "OK" "port ${port} listening"
    elif [[ "$service_status" == "Running" ]]; then
      status_line "$label" "WARN" "port ${port} not listening yet"
    else
      status_line "$label" "INFO" "port ${port} not listening"
    fi
  done

  echo
  if [[ "$runtime_status" == Starting* ]]; then
    echo "ERPNext was recently started/restarted. If ports are still waiting, run:"
    echo "  sleep 30 && $(toolkit_cmd runtime-status)"
    echo "  $(toolkit_cmd logs)"
  else
    echo "If installed but stopped, run: $(toolkit_cmd start)"
  fi
  echo "============================================================"
}

run_installation_status() {
  require_sudo

  local bench_dir
  bench_dir="$(active_bench_dir)"

  echo
  echo "============================================================"
  echo "ERPNext Installation Status"
  echo "============================================================"
  local install_status
  install_status="$(install_state)"
  if [[ "$install_status" == "Installed" ]]; then
    status_line "Install status" "OK" "$install_status"
  elif [[ "$install_status" == "Installed files found; site app not confirmed" ]]; then
    status_line "Install status" "WARN" "$install_status"
  else
    status_line "Install status" "FAIL" "$install_status"
  fi

  if id "$FRAPPE_USER" >/dev/null 2>&1; then
    status_line "frappe user" "OK" "$FRAPPE_USER exists"
  else
    status_line "frappe user" "FAIL" "$FRAPPE_USER missing"
  fi

  if path_is_dir "$bench_dir"; then
    status_line "Bench folder" "OK" "$bench_dir"
  else
    status_line "Bench folder" "FAIL" "$bench_dir missing"
  fi

  if check_bench_app_installed frappe; then
    status_line "Frappe app files" "OK" "apps/frappe exists"
  else
    status_line "Frappe app files" "FAIL" "apps/frappe missing"
  fi

  if check_bench_app_installed erpnext; then
    status_line "ERPNext app files" "OK" "apps/erpnext exists"
  else
    status_line "ERPNext app files" "WARN" "apps/erpnext missing"
  fi

  if site_exists; then
    status_line "Site folder" "OK" "${SITE_NAME} exists"
  else
    status_line "Site folder" "WARN" "${SITE_NAME} missing"
  fi

  if site_app_installed frappe; then
    status_line "Site app: frappe" "OK" "installed on ${SITE_NAME}"
  else
    status_line "Site app: frappe" "WARN" "not confirmed on ${SITE_NAME}"
  fi

  if site_app_installed erpnext; then
    status_line "Site app: erpnext" "OK" "installed on ${SITE_NAME}"
  else
    status_line "Site app: erpnext" "WARN" "not confirmed on ${SITE_NAME}"
  fi

  echo "============================================================"
}

run_service_summary() {
  require_sudo

  echo
  echo "============================================================"
  echo "ERPNext Service / Autostart Status"
  echo "============================================================"
  local service_status autostart_status
  service_status="$(service_state)"
  autostart_status="$(autostart_state)"

  if service_exists; then
    status_line "Service file" "OK" "$(erpnext_service_path)"
  else
    status_line "Service file" "WARN" "not created: $(erpnext_service_path)"
  fi

  if [[ "$service_status" == "Running" ]]; then
    status_line "Service" "OK" "$service_status"
  elif [[ "$service_status" == "Not configured" ]]; then
    status_line "Service" "WARN" "$service_status"
  else
    status_line "Service" "INFO" "$service_status"
  fi

  if [[ "$autostart_status" == "Enabled" ]]; then
    status_line "Autostart" "OK" "$autostart_status"
  else
    status_line "Autostart" "WARN" "$autostart_status"
  fi
  echo
  echo "Useful commands:"
  echo "  $(toolkit_cmd enable-autostart)"
  echo "  $(toolkit_cmd disable-autostart)"
  echo "  $(toolkit_cmd service-start)"
  echo "  $(toolkit_cmd service-stop)"
  echo "  $(toolkit_cmd logs)"
  echo "============================================================"
}

show_status_menu() {
  while true; do
    echo
    echo "============================================================"
    echo "Status"
    echo "============================================================"
    echo "1) Status Summary"
    echo "2) Runtime Status"
    echo "3) Installation Status"
    echo "4) Service / Autostart Status"
    echo "5) Optional App Status"
    echo "6) Full Health Report"
    menu_footer
    menu_read_choice status_choice

    case "$status_choice" in
      1) run_status; pause_after_screen "Press Enter to return to Status Menu..." ;;
      2) run_runtime_status; pause_after_screen "Press Enter to return to Status Menu..." ;;
      3) run_installation_status; pause_after_screen "Press Enter to return to Status Menu..." ;;
      4) run_service_summary; pause_after_screen "Press Enter to return to Status Menu..." ;;
      5) run_app_status; pause_after_screen "Press Enter to return to Status Menu..." ;;
      6) run_full_status; pause_after_screen "Press Enter to return to Status Menu..." ;;
      b|B|"") return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option"; pause_after_screen "Press Enter to continue..." ;;
    esac
  done
}



status_line_plain() {
  local label="$1"
  local state="$2"
  local message="$3"

  printf "  %-28s %-7s %s\n" "$label" "$state" "$message"
}

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '"%s"' "$s"
}

doctor_add_check() {
  DOCTOR_CHECK_NAMES+=("$1")
  DOCTOR_CHECK_STATUSES+=("$2")
  DOCTOR_CHECK_DETAILS+=("$3")
}

doctor_command_version() {
  local cmd="$1"
  shift || true

  if command -v "$cmd" >/dev/null 2>&1; then
    "$cmd" "$@" 2>/dev/null | head -n 1 || true
  else
    echo "missing"
  fi
}

doctor_run_as_frappe_one_line() {
  local cmd="$1"

  if id "$FRAPPE_USER" >/dev/null 2>&1; then
    run_as_frappe "$cmd" 2>/dev/null | head -n 1 || true
  else
    echo "frappe user missing"
  fi
}

doctor_storage_detail() {
  local data layout root_bytes vg_free_bytes tail_free_bytes can_expand reason
  data="$(storage_eval 2>/dev/null || true)"

  while IFS='=' read -r k v; do
    case "$k" in
      LAYOUT) layout="$v" ;;
      ROOT_BYTES) root_bytes="$v" ;;
      VG_FREE_BYTES) vg_free_bytes="$v" ;;
      TAIL_FREE_BYTES) tail_free_bytes="$v" ;;
      CAN_EXPAND) can_expand="$v" ;;
      REASON) reason="$v" ;;
    esac
  done <<< "$data"

  printf 'layout=%s; root=%s; vg_free=%s; tail_free=%s; reason=%s\n' \
    "${layout:-unknown}" \
    "$(bytes_to_gib "${root_bytes:-0}" 2>/dev/null || echo unknown)" \
    "$(bytes_to_gib "${vg_free_bytes:-0}" 2>/dev/null || echo unknown)" \
    "$(bytes_to_gib "${tail_free_bytes:-0}" 2>/dev/null || echo unknown)" \
    "${reason:-unknown}"
}

doctor_optional_app_detail() {
  local bench_dir="$1"
  local app="$2"

  if site_app_installed "$app" 2>/dev/null; then
    echo "installed on ${SITE_NAME}"
  elif app_folder_exists "$bench_dir" "$app" 2>/dev/null && app_in_apps_txt "$app" 2>/dev/null; then
    echo "downloaded and registered, not installed on ${SITE_NAME}"
  elif app_folder_exists "$bench_dir" "$app" 2>/dev/null; then
    echo "downloaded, not registered"
  else
    echo "not installed"
  fi
}

doctor_collect() {
  require_sudo

  DOCTOR_GENERATED_AT="$(date -Iseconds 2>/dev/null || date)"
  DOCTOR_HOSTNAME="$(hostname 2>/dev/null || echo unknown)"
  DOCTOR_CURRENT_USER="$(id -un 2>/dev/null || echo unknown)"
  DOCTOR_VM_IP="$(get_vm_ip 2>/dev/null || echo unknown)"
  DOCTOR_BENCH_DIR="$(active_bench_dir 2>/dev/null || echo "$BENCH_DIR")"
  DOCTOR_INSTALL_STATE="$(install_state 2>/dev/null || echo unknown)"
  DOCTOR_RUNTIME_STATE="$(runtime_state 2>/dev/null || echo unknown)"
  DOCTOR_SERVICE_STATE="$(service_state 2>/dev/null || echo unknown)"
  DOCTOR_AUTOSTART_STATE="$(autostart_state 2>/dev/null || echo unknown)"
  DOCTOR_SSL_STATE="not configured"
  DOCTOR_CHECK_NAMES=()
  DOCTOR_CHECK_STATUSES=()
  DOCTOR_CHECK_DETAILS=()
  DOCTOR_OPTIONAL_APPS=()
  DOCTOR_OPTIONAL_LABELS=()
  DOCTOR_OPTIONAL_DETAILS=()

  if ssl_is_configured 2>/dev/null; then
    DOCTOR_SSL_STATE="configured"
  fi

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DOCTOR_OS="${PRETTY_NAME:-unknown}"
    if [[ "${ID:-}" == "ubuntu" && ( "${VERSION_ID:-}" == "24.04" || "${VERSION_ID:-}" == "26.04" ) ]]; then
      doctor_add_check "OS" "OK" "$DOCTOR_OS"
    else
      doctor_add_check "OS" "FAIL" "${DOCTOR_OS}; supported: Ubuntu 24.04 / 26.04"
    fi
  else
    DOCTOR_OS="unknown"
    doctor_add_check "OS" "FAIL" "/etc/os-release not found"
  fi

  local py_system py_frappe node_frappe mariadb_version redis_version storage_detail storage_data storage_can_expand storage_layout storage_reason
  py_system="$(doctor_command_version python3 --version)"
  py_frappe="$(doctor_run_as_frappe_one_line 'python --version 2>&1')"
  node_frappe="$(doctor_run_as_frappe_one_line 'node --version 2>/dev/null || echo missing')"
  mariadb_version="$(doctor_command_version mariadb --version)"
  if [[ "$mariadb_version" == "missing" ]]; then
    mariadb_version="$(doctor_command_version mysql --version)"
  fi
  redis_version="$(doctor_command_version redis-server --version)"

  doctor_add_check "System Python" "INFO" "$py_system"
  doctor_add_check "frappe Python" "INFO" "$py_frappe"
  doctor_add_check "frappe Node" "INFO" "$node_frappe"
  doctor_add_check "MariaDB version" "INFO" "$mariadb_version"
  doctor_add_check "Redis version" "INFO" "$redis_version"

  if systemctl is-active --quiet mariadb 2>/dev/null; then
    doctor_add_check "MariaDB service" "OK" "running"
  else
    doctor_add_check "MariaDB service" "WARN" "not running"
  fi

  if systemctl is-active --quiet redis-server 2>/dev/null; then
    doctor_add_check "Redis service" "OK" "running"
  else
    doctor_add_check "Redis service" "WARN" "not running"
  fi

  if [[ "$(sysctl -n vm.overcommit_memory 2>/dev/null || echo 0)" == "1" ]]; then
    doctor_add_check "Redis overcommit" "OK" "vm.overcommit_memory=1"
  else
    doctor_add_check "Redis overcommit" "WARN" "not set to 1"
  fi

  if id "$FRAPPE_USER" >/dev/null 2>&1; then
    doctor_add_check "frappe user" "OK" "$FRAPPE_USER exists"
  else
    doctor_add_check "frappe user" "FAIL" "$FRAPPE_USER missing"
  fi

  if path_is_dir "$DOCTOR_BENCH_DIR"; then
    doctor_add_check "Bench folder" "OK" "$DOCTOR_BENCH_DIR"
  else
    doctor_add_check "Bench folder" "FAIL" "$DOCTOR_BENCH_DIR missing"
  fi

  if check_bench_app_installed frappe; then
    doctor_add_check "Frappe app files" "OK" "apps/frappe exists"
  else
    doctor_add_check "Frappe app files" "FAIL" "apps/frappe missing"
  fi

  if check_bench_app_installed erpnext; then
    doctor_add_check "ERPNext app files" "OK" "apps/erpnext exists"
  else
    doctor_add_check "ERPNext app files" "WARN" "apps/erpnext missing"
  fi

  if site_exists; then
    doctor_add_check "Site folder" "OK" "${SITE_NAME} exists"
  else
    doctor_add_check "Site folder" "WARN" "${SITE_NAME} missing"
  fi

  if site_app_installed frappe 2>/dev/null; then
    doctor_add_check "Site app: frappe" "OK" "installed on ${SITE_NAME}"
  else
    doctor_add_check "Site app: frappe" "WARN" "not confirmed on ${SITE_NAME}"
  fi

  if site_app_installed erpnext 2>/dev/null; then
    doctor_add_check "Site app: erpnext" "OK" "installed on ${SITE_NAME}"
  else
    doctor_add_check "Site app: erpnext" "WARN" "not confirmed on ${SITE_NAME}"
  fi

  case "$DOCTOR_INSTALL_STATE" in
    Installed) doctor_add_check "Install state" "OK" "$DOCTOR_INSTALL_STATE" ;;
    Incomplete) doctor_add_check "Install state" "WARN" "$DOCTOR_INSTALL_STATE" ;;
    *) doctor_add_check "Install state" "INFO" "$DOCTOR_INSTALL_STATE" ;;
  esac

  case "$DOCTOR_RUNTIME_STATE" in
    Running*) doctor_add_check "Runtime state" "OK" "$DOCTOR_RUNTIME_STATE" ;;
    Starting*) doctor_add_check "Runtime state" "WARN" "$DOCTOR_RUNTIME_STATE" ;;
    *) doctor_add_check "Runtime state" "INFO" "$DOCTOR_RUNTIME_STATE" ;;
  esac

  case "$DOCTOR_SERVICE_STATE" in
    Running) doctor_add_check "Service state" "OK" "$DOCTOR_SERVICE_STATE" ;;
    "Not configured") doctor_add_check "Service state" "WARN" "$DOCTOR_SERVICE_STATE" ;;
    *) doctor_add_check "Service state" "INFO" "$DOCTOR_SERVICE_STATE" ;;
  esac

  case "$DOCTOR_AUTOSTART_STATE" in
    Enabled) doctor_add_check "Autostart" "OK" "$DOCTOR_AUTOSTART_STATE" ;;
    *) doctor_add_check "Autostart" "WARN" "$DOCTOR_AUTOSTART_STATE" ;;
  esac

  local port label item
  for item in "8000:Bench web" "9000:Socket.io" "11000:Bench Redis queue" "13000:Bench Redis cache"; do
    port="${item%%:*}"
    label="${item#*:}"
    if port_listens "$port"; then
      doctor_add_check "$label" "OK" "port ${port} listening"
    else
      doctor_add_check "$label" "INFO" "port ${port} not listening"
    fi
  done

  storage_data="$(storage_eval 2>/dev/null || true)"
  storage_can_expand="$(printf '%s\n' "$storage_data" | awk -F= '$1=="CAN_EXPAND" {print $2; exit}')"
  storage_layout="$(printf '%s\n' "$storage_data" | awk -F= '$1=="LAYOUT" {print $2; exit}')"
  storage_reason="$(printf '%s\n' "$storage_data" | awk -F= '$1=="REASON" {print $2; exit}')"
  storage_detail="$(doctor_storage_detail)"
  if [[ "${storage_can_expand:-no}" == "yes" ]]; then
    doctor_add_check "Root storage" "WARN" "expansion recommended; ${storage_detail}"
  elif [[ "${storage_layout:-unknown}" == "unknown" ]]; then
    doctor_add_check "Root storage" "WARN" "not automatic; ${storage_reason:-unknown}"
  else
    doctor_add_check "Root storage" "OK" "${storage_detail}"
  fi

  if [[ "$DOCTOR_SSL_STATE" == "configured" ]]; then
    local cert_path cert_detail="configured"
    cert_path="$(ssl_cert_path 2>/dev/null || true)"
    if [[ -n "$cert_path" && -f "$cert_path" ]] && ssl_cert_is_self_signed "$cert_path" 2>/dev/null; then
      cert_detail="configured; self-signed/local test certificate"
    elif [[ -n "$cert_path" && -f "$cert_path" ]]; then
      cert_detail="configured; certificate is not self-signed"
    fi
    doctor_add_check "Local SSL" "OK" "$cert_detail"
  else
    doctor_add_check "Local SSL" "INFO" "not configured"
  fi

  if path_is_executable "${FRAPPE_HOME}/start-erpnext-dev.sh"; then
    doctor_add_check "Start helper" "OK" "${FRAPPE_HOME}/start-erpnext-dev.sh"
  else
    doctor_add_check "Start helper" "WARN" "missing or not executable at ${FRAPPE_HOME}/start-erpnext-dev.sh"
  fi

  if path_is_file "${FRAPPE_HOME}/erpnext-dev-credentials.txt"; then
    doctor_add_check "Credentials file" "OK" "present; content intentionally not displayed"
  else
    doctor_add_check "Credentials file" "WARN" "missing"
  fi

  local optional_profile optional_app optional_label optional_detail
  for optional_profile in $(app_profile_list); do
    app_profile_defaults "$optional_profile" || continue
    optional_app="$LIB_APP_NAME"
    optional_label="$LIB_APP_DISPLAY"
    optional_detail="$(doctor_optional_app_detail "$DOCTOR_BENCH_DIR" "$optional_app")"
    DOCTOR_OPTIONAL_APPS+=("$optional_app")
    DOCTOR_OPTIONAL_LABELS+=("$optional_label")
    DOCTOR_OPTIONAL_DETAILS+=("$optional_detail")
  done

  DOCTOR_BENCH_VERSION="$(doctor_run_as_frappe_one_line "cd '${DOCTOR_BENCH_DIR}' 2>/dev/null && bench version 2>/dev/null | head -n 1")"
  [[ -n "$DOCTOR_BENCH_VERSION" ]] || DOCTOR_BENCH_VERSION="not available"
}

run_doctor_plain() {
  doctor_collect

  echo
  echo "============================================================"
  echo "ERPNext Developer Diagnostics (Plain / Safe to Share)"
  echo "============================================================"
  echo "Generated: ${DOCTOR_GENERATED_AT}"
  echo "Script:    ${APP_NAME} v${SCRIPT_VERSION}"
  echo "Note:      Secrets, passwords, tokens, private keys, and credential contents are intentionally excluded."
  echo
  echo "Context:"
  status_line_plain "Hostname" "INFO" "$DOCTOR_HOSTNAME"
  status_line_plain "Current user" "INFO" "$DOCTOR_CURRENT_USER"
  status_line_plain "VM IP" "INFO" "$DOCTOR_VM_IP"
  status_line_plain "Site" "INFO" "${SITE_NAME} (${SITE_NAME_SOURCE})"
  status_line_plain "Bench" "INFO" "$DOCTOR_BENCH_DIR"
  status_line_plain "Bench version" "INFO" "$DOCTOR_BENCH_VERSION"
  status_line_plain "Service name" "INFO" "$ERPNEXT_SERVICE_NAME"
  status_line_plain "Config file" "INFO" "${CONFIG_FILE}"
  echo
  echo "Checks:"

  local i
  for i in "${!DOCTOR_CHECK_NAMES[@]}"; do
    status_line_plain "${DOCTOR_CHECK_NAMES[$i]}" "${DOCTOR_CHECK_STATUSES[$i]}" "${DOCTOR_CHECK_DETAILS[$i]}"
  done

  echo
  echo "Optional apps:"
  for i in "${!DOCTOR_OPTIONAL_APPS[@]}"; do
    status_line_plain "${DOCTOR_OPTIONAL_APPS[$i]}" "INFO" "${DOCTOR_OPTIONAL_LABELS[$i]}: ${DOCTOR_OPTIONAL_DETAILS[$i]}"
  done

  echo
  echo "Access:"
  echo "  Direct URL:   http://${DOCTOR_VM_IP}:8000"
  echo "  Friendly URL: http://${SITE_NAME}:8000"
  if [[ "$DOCTOR_SSL_STATE" == "configured" ]]; then
    echo "  HTTPS URL:    https://${SITE_NAME}"
  fi
  echo "  HOST mapping: ${DOCTOR_VM_IP} ${SITE_NAME}"
  echo
  echo "Log file for this run: ${LOG_FILE}"
  echo "============================================================"
}

run_doctor_json() {
  doctor_collect

  local i
  printf '{\n'
  printf '  "schema_version": "1",\n'
  printf '  "safe_to_share": true,\n'
  printf '  "redaction_note": ' ; json_escape "Secrets, passwords, tokens, private keys, and credential contents are intentionally excluded." ; printf ',\n'
  printf '  "generated_at": ' ; json_escape "$DOCTOR_GENERATED_AT" ; printf ',\n'
  printf '  "script": {"name": ' ; json_escape "$APP_NAME" ; printf ', "version": ' ; json_escape "$SCRIPT_VERSION" ; printf '},\n'
  printf '  "context": {\n'
  printf '    "hostname": ' ; json_escape "$DOCTOR_HOSTNAME" ; printf ',\n'
  printf '    "current_user": ' ; json_escape "$DOCTOR_CURRENT_USER" ; printf ',\n'
  printf '    "vm_ip": ' ; json_escape "$DOCTOR_VM_IP" ; printf ',\n'
  printf '    "site_name": ' ; json_escape "$SITE_NAME" ; printf ',\n'
  printf '    "site_source": ' ; json_escape "$SITE_NAME_SOURCE" ; printf ',\n'
  printf '    "bench_dir": ' ; json_escape "$DOCTOR_BENCH_DIR" ; printf ',\n'
  printf '    "bench_version": ' ; json_escape "$DOCTOR_BENCH_VERSION" ; printf ',\n'
  printf '    "service_name": ' ; json_escape "$ERPNEXT_SERVICE_NAME" ; printf ',\n'
  printf '    "config_file": ' ; json_escape "$CONFIG_FILE" ; printf ',\n'
  printf '    "install_state": ' ; json_escape "$DOCTOR_INSTALL_STATE" ; printf ',\n'
  printf '    "runtime_state": ' ; json_escape "$DOCTOR_RUNTIME_STATE" ; printf ',\n'
  printf '    "service_state": ' ; json_escape "$DOCTOR_SERVICE_STATE" ; printf ',\n'
  printf '    "autostart_state": ' ; json_escape "$DOCTOR_AUTOSTART_STATE" ; printf ',\n'
  printf '    "local_ssl_state": ' ; json_escape "$DOCTOR_SSL_STATE" ; printf '\n'
  printf '  },\n'
  printf '  "checks": [\n'
  for i in "${!DOCTOR_CHECK_NAMES[@]}"; do
    if [[ "$i" -gt 0 ]]; then printf ',\n'; fi
    printf '    {"name": ' ; json_escape "${DOCTOR_CHECK_NAMES[$i]}" ; printf ', "status": ' ; json_escape "${DOCTOR_CHECK_STATUSES[$i]}" ; printf ', "detail": ' ; json_escape "${DOCTOR_CHECK_DETAILS[$i]}" ; printf '}'
  done
  printf '\n  ],\n'
  printf '  "optional_apps": [\n'
  for i in "${!DOCTOR_OPTIONAL_APPS[@]}"; do
    if [[ "$i" -gt 0 ]]; then printf ',\n'; fi
    printf '    {"app": ' ; json_escape "${DOCTOR_OPTIONAL_APPS[$i]}" ; printf ', "label": ' ; json_escape "${DOCTOR_OPTIONAL_LABELS[$i]}" ; printf ', "detail": ' ; json_escape "${DOCTOR_OPTIONAL_DETAILS[$i]}" ; printf '}'
  done
  printf '\n  ],\n'
  printf '  "access": {\n'
  printf '    "direct_url": ' ; json_escape "http://${DOCTOR_VM_IP}:8000" ; printf ',\n'
  printf '    "friendly_url": ' ; json_escape "http://${SITE_NAME}:8000" ; printf ',\n'
  if [[ "$DOCTOR_SSL_STATE" == "configured" ]]; then
    printf '    "https_url": ' ; json_escape "https://${SITE_NAME}" ; printf ',\n'
  fi
  printf '    "host_mapping": ' ; json_escape "${DOCTOR_VM_IP} ${SITE_NAME}" ; printf '\n'
  printf '  }\n'
  printf '}\n'
}


redact_file_in_place() {
  local file="$1"

  [[ -f "$file" ]] || return 0

  if command -v perl >/dev/null 2>&1; then
    perl -0pi -e 's/(?i)(("?)(?:password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key|authorization|cookie|db_password|admin_password)\2\s*[:=]\s*)(["\x27])(?:(?!\3).)*\3/${1}${3}[REDACTED]${3}/gs; s/(?i)(("?)(?:password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key|authorization|cookie|db_password|admin_password)\2\s*[:=]\s*)[^\s,;}]+/${1}[REDACTED]/g; s/(?i)(Bearer\s+)[A-Za-z0-9._~+\/=-]+/${1}[REDACTED]/g; s/-----BEGIN ([A-Z0-9 ]*PRIVATE KEY)-----.*?-----END \1-----/-----BEGIN $1-----\n[REDACTED]\n-----END $1-----/gis;' "$file" 2>/dev/null || true
  else
    sed -Ei \
      -e "s/(password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key|authorization|cookie)([[:space:]_:=\"]+)[^[:space:]\",;}]+/\1\2[REDACTED]/Ig" \
      -e "s/(Bearer[[:space:]]+)[A-Za-z0-9._~+\/=-]+/\1[REDACTED]/Ig" \
      "$file" 2>/dev/null || true
  fi
}

support_bundle_write_file() {
  local output_file="$1"
  shift

  if ! "$@" > "$output_file" 2>&1; then
    {
      echo
      echo "WARN: command failed while collecting this section."
      echo "Command: $*"
    } >> "$output_file"
  fi

  redact_file_in_place "$output_file"
  chmod 600 "$output_file" 2>/dev/null || true
}

support_bundle_manifest() {
  cat <<EOF_SUPPORT_MANIFEST
ERPNext Developer Toolkit Support Bundle
=========================================

Generated: $(date -Iseconds 2>/dev/null || date)
Script:    ${APP_NAME} v${SCRIPT_VERSION}
Site:      ${SITE_NAME}

Safe-to-share intent:
- This bundle is designed for troubleshooting and support.
- It includes share-safe diagnostics, status summaries, and recent redacted service errors.
- It intentionally excludes credential files, private keys, raw site_config.json secrets, tokens, and database passwords.

Recommended review before sharing:
- Open the included .txt and .json files.
- Confirm there is no client-sensitive text from custom logs before sending outside your organization.

Included files:
- doctor-plain.txt
- doctor.json
- doctor-json-validation.txt
- system-summary.txt
- service-status.txt
- port-status.txt
- storage-status.txt
- ssl-status.txt
- bench-status.txt
- recent-errors.txt
- manifest.txt
EOF_SUPPORT_MANIFEST
}

support_bundle_system_summary() {
  echo "Generated: $(date -Iseconds 2>/dev/null || date)"
  echo "Script: ${APP_NAME} v${SCRIPT_VERSION}"
  echo
  echo "OS release:"
  if [[ -f /etc/os-release ]]; then
    cat /etc/os-release
  else
    echo "/etc/os-release missing"
  fi
  echo
  echo "Kernel:"
  uname -a || true
  echo
  echo "Hostname:"
  hostname || true
  echo
  echo "Current user:"
  id || true
  echo
  echo "Uptime:"
  uptime || true
  echo
  echo "Memory:"
  free -h || true
  echo
  echo "Root filesystem:"
  df -hT / || true
  echo
  echo "Tool versions:"
  python3 --version 2>&1 || true
  mariadb --version 2>&1 || mysql --version 2>&1 || true
  redis-server --version 2>&1 || true
  if id "$FRAPPE_USER" >/dev/null 2>&1; then
    doctor_run_as_frappe_one_line 'node --version 2>/dev/null || echo node missing'
    doctor_run_as_frappe_one_line 'python --version 2>&1 || echo python missing'
  fi
}

support_bundle_service_status() {
  local svc
  for svc in mariadb redis-server "$ERPNEXT_SERVICE_NAME"; do
    echo "============================================================"
    echo "Service: ${svc}"
    echo "============================================================"
    systemctl is-enabled "$svc" 2>/dev/null || true
    systemctl is-active "$svc" 2>/dev/null || true
    systemctl status "$svc" --no-pager --lines=30 2>&1 || true
    echo
  done
}

support_bundle_port_status() {
  echo "Listening TCP ports:"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>&1 || true
  else
    netstat -ltn 2>&1 || true
  fi
  echo
  echo "ERPNext development port checks:"
  local item port label
  for item in "8000:Bench web" "9000:Socket.io" "11000:Bench Redis queue" "13000:Bench Redis cache" "80:HTTP" "443:HTTPS"; do
    port="${item%%:*}"
    label="${item#*:}"
    if port_listens "$port"; then
      printf '%-24s OK    port %s listening\n' "$label" "$port"
    else
      printf '%-24s INFO  port %s not listening\n' "$label" "$port"
    fi
  done
}

support_bundle_storage_status() {
  echo "Raw storage evaluator output:"
  storage_eval 2>&1 || true
  echo
  echo "Root mount:"
  findmnt -n -o SOURCE,FSTYPE,SIZE,AVAIL,TARGET / 2>&1 || true
  echo
  echo "df -hT:"
  df -hT || true
  echo
  echo "lsblk -f:"
  lsblk -f 2>&1 || true
  echo
  if command -v pvs >/dev/null 2>&1; then
    echo "LVM physical volumes:"
    pvs 2>&1 || true
    echo
  fi
  if command -v vgs >/dev/null 2>&1; then
    echo "LVM volume groups:"
    vgs 2>&1 || true
    echo
  fi
  if command -v lvs >/dev/null 2>&1; then
    echo "LVM logical volumes:"
    lvs 2>&1 || true
    echo
  fi
}

support_bundle_ssl_status() {
  echo "Script SSL status:"
  show_ssl_status || true
  echo
  echo "Local SSL verification summary:"
  verify_local_ssl || true
}

support_bundle_bench_status() {
  local bench_dir
  bench_dir="$(active_bench_dir 2>/dev/null || echo "$BENCH_DIR")"

  echo "Bench directory: ${bench_dir}"
  echo "Site: ${SITE_NAME}"
  echo

  if ! id "$FRAPPE_USER" >/dev/null 2>&1; then
    echo "frappe user missing; Bench status unavailable."
    return 0
  fi

  if ! path_is_dir "$bench_dir"; then
    echo "Bench directory missing; Bench status unavailable."
    return 0
  fi

  echo "Bench version:"
  run_as_frappe "cd '${bench_dir}' && bench version" 2>&1 || true
  echo
  echo "Installed site apps:"
  run_as_frappe "cd '${bench_dir}' && bench --site '${SITE_NAME}' list-apps" 2>&1 || true
  echo
  echo "Downloaded app folders and Git branches:"
  run_as_frappe "cd '${bench_dir}' && for appdir in apps/*; do [ -d \"\$appdir\" ] || continue; app=\$(basename \"\$appdir\"); branch=\$(git -C \"\$appdir\" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown); printf '%s %s\\n' \"\$app\" \"\$branch\"; done | sort" 2>&1 || true
}

support_bundle_recent_errors() {
  local svc
  for svc in "$ERPNEXT_SERVICE_NAME" mariadb redis-server; do
    echo "============================================================"
    echo "Recent warnings/errors: ${svc}"
    echo "============================================================"
    journalctl -u "$svc" -n 120 --no-pager -o short-iso -p warning..alert 2>&1 || true
    echo
  done
}



support_bundle_production_checklist() { show_production_checklist; }
support_bundle_backup_status() { show_backup_status; }
support_bundle_backup_verify() { verify_latest_backup_set; }
support_bundle_off_vm_backup_status() { show_off_vm_backup_status; }
support_bundle_restore_rehearsal_status() { show_restore_rehearsal_status; }
support_bundle_health_check_status() { show_health_check_status; }
support_bundle_go_live_status() { show_go_live_status; }

create_support_bundle() {
  require_sudo

  local timestamp bundle_name bundle_parent bundle_dir archive json_stderr validation_file
  timestamp="$(date +%Y%m%d-%H%M%S)"
  bundle_name="erpnext-dev-support-bundle-${timestamp}"
  bundle_parent="${SUPPORT_BUNDLE_DIR:-/tmp}"
  bundle_dir="${bundle_parent}/${bundle_name}"
  archive="${bundle_parent}/${bundle_name}.tar.gz"
  json_stderr="${bundle_dir}/doctor-json.stderr"
  validation_file="${bundle_dir}/doctor-json-validation.txt"

  log "Creating redacted support bundle"

  rm -rf "$bundle_dir" "$archive" 2>/dev/null || true
  mkdir -p "$bundle_dir"
  chmod 700 "$bundle_dir" 2>/dev/null || true

  support_bundle_write_file "${bundle_dir}/manifest.txt" support_bundle_manifest
  support_bundle_write_file "${bundle_dir}/doctor-plain.txt" run_doctor_plain

  if run_doctor_json > "${bundle_dir}/doctor.json" 2> "$json_stderr"; then
    :
  else
    echo "WARN: doctor --json returned a non-zero exit code." > "$validation_file"
  fi
  redact_file_in_place "${bundle_dir}/doctor.json"
  redact_file_in_place "$json_stderr"
  chmod 600 "${bundle_dir}/doctor.json" "$json_stderr" 2>/dev/null || true

  if [[ ! -s "$json_stderr" ]]; then
    rm -f "$json_stderr"
  fi

  if command -v python3 >/dev/null 2>&1 && python3 -m json.tool "${bundle_dir}/doctor.json" >/dev/null 2>&1; then
    echo "OK: doctor.json is valid JSON." >> "$validation_file"
  else
    echo "WARN: doctor.json could not be validated as JSON on this system." >> "$validation_file"
  fi
  chmod 600 "$validation_file" 2>/dev/null || true

  support_bundle_write_file "${bundle_dir}/system-summary.txt" support_bundle_system_summary
  support_bundle_write_file "${bundle_dir}/service-status.txt" support_bundle_service_status
  support_bundle_write_file "${bundle_dir}/port-status.txt" support_bundle_port_status
  support_bundle_write_file "${bundle_dir}/storage-status.txt" support_bundle_storage_status
  support_bundle_write_file "${bundle_dir}/ssl-status.txt" support_bundle_ssl_status
  support_bundle_write_file "${bundle_dir}/bench-status.txt" support_bundle_bench_status
  support_bundle_write_file "${bundle_dir}/recent-errors.txt" support_bundle_recent_errors
  support_bundle_write_file "${bundle_dir}/production-checklist.txt" support_bundle_production_checklist
  support_bundle_write_file "${bundle_dir}/backup-status.txt" support_bundle_backup_status
  support_bundle_write_file "${bundle_dir}/backup-verify.txt" support_bundle_backup_verify
  support_bundle_write_file "${bundle_dir}/off-vm-backup-status.txt" support_bundle_off_vm_backup_status
  support_bundle_write_file "${bundle_dir}/restore-rehearsal-status.txt" support_bundle_restore_rehearsal_status
  support_bundle_write_file "${bundle_dir}/health-check-status.txt" support_bundle_health_check_status
  support_bundle_write_file "${bundle_dir}/go-live-status.txt" support_bundle_go_live_status

  tar -C "$bundle_parent" -czf "$archive" "$bundle_name"
  chmod 600 "$archive" 2>/dev/null || true
  rm -rf "$bundle_dir"

  ok "Support bundle created: ${archive}"
  echo
  echo "Review before sharing:"
  echo "  tar -tzf ${archive}"
  echo "  mkdir -p /tmp/erpnext-support-review && tar -xzf ${archive} -C /tmp/erpnext-support-review"
  echo
  echo "This bundle intentionally excludes credential files, private keys, raw site_config.json secrets, tokens, and passwords."
  ui_next "Review archive contents before sharing."
}

run_full_status() {
  require_sudo

  echo
  echo "============================================================"
  echo "ERPNext Developer Full Health Report"
  echo "============================================================"

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" == "ubuntu" && ( "${VERSION_ID:-}" == "24.04" || "${VERSION_ID:-}" == "26.04" ) ]]; then
      status_line "OS" "OK" "${PRETTY_NAME:-Ubuntu}"
    else
      status_line "OS" "FAIL" "${PRETTY_NAME:-unknown}; supported: Ubuntu 24.04 / 26.04"
    fi
  else
    status_line "OS" "FAIL" "/etc/os-release not found"
  fi

  if systemctl is-active --quiet mariadb; then
    status_line "MariaDB service" "OK" "running"
  else
    status_line "MariaDB service" "WARN" "not running"
  fi

  if systemctl is-active --quiet redis-server; then
    status_line "Redis service" "OK" "running"
  else
    status_line "Redis service" "WARN" "not running"
  fi

  if [[ "$(sysctl -n vm.overcommit_memory 2>/dev/null || echo 0)" == "1" ]]; then
    status_line "Redis overcommit" "OK" "vm.overcommit_memory=1"
  else
    status_line "Redis overcommit" "WARN" "not set to 1"
  fi

  if service_exists; then
    if systemctl is-enabled --quiet "${ERPNEXT_SERVICE_NAME}" 2>/dev/null; then
      status_line "ERPNext autostart" "OK" "enabled"
    else
      status_line "ERPNext autostart" "WARN" "disabled"
    fi

    if systemctl is-active --quiet "${ERPNEXT_SERVICE_NAME}"; then
      status_line "ERPNext service" "OK" "running"
    else
      status_line "ERPNext service" "INFO" "installed but stopped"
    fi
  else
    status_line "ERPNext service" "WARN" "not configured"
  fi

  if id "$FRAPPE_USER" >/dev/null 2>&1; then
    status_line "frappe user" "OK" "$FRAPPE_USER exists"
  else
    status_line "frappe user" "FAIL" "$FRAPPE_USER missing"
  fi

  local bench_dir
  bench_dir="$(active_bench_dir)"

  if path_is_dir "$bench_dir"; then
    status_line "Bench folder" "OK" "$bench_dir"
  else
    status_line "Bench folder" "FAIL" "$bench_dir missing"
  fi

  if check_bench_app_installed frappe; then
    status_line "Frappe app" "OK" "apps/frappe exists"
  else
    status_line "Frappe app" "FAIL" "apps/frappe missing"
  fi

  if check_bench_app_installed erpnext; then
    status_line "ERPNext app files" "OK" "apps/erpnext exists"
  else
    status_line "ERPNext app files" "WARN" "apps/erpnext missing"
  fi

  if path_is_dir "${bench_dir}/sites/${SITE_NAME}"; then
    status_line "Site" "OK" "${SITE_NAME} exists"
  else
    status_line "Site" "WARN" "${SITE_NAME} missing"
  fi

  if site_app_installed frappe; then
    status_line "Site app: frappe" "OK" "installed on ${SITE_NAME}"
  else
    status_line "Site app: frappe" "WARN" "not confirmed on ${SITE_NAME}"
  fi

  if site_app_installed erpnext; then
    status_line "Site app: erpnext" "OK" "installed on ${SITE_NAME}"
  else
    status_line "Site app: erpnext" "WARN" "not confirmed on ${SITE_NAME}"
  fi

  local optional_app optional_label optional_item
  local optional_apps=(
    "crm:Frappe CRM"
    "hrms:Frappe HR / HRMS"
    "telephony:Frappe Telephony"
    "helpdesk:Frappe Helpdesk"
    "insights:Frappe Insights"
    "payments:Frappe Payments"
    "webshop:Frappe Webshop / E-Commerce"
  )

  for optional_item in "${optional_apps[@]}"; do
    optional_app="${optional_item%%:*}"
    optional_label="${optional_item#*:}"
    if site_app_installed "$optional_app"; then
      status_line "Optional: ${optional_app}" "OK" "${optional_label} installed"
    elif app_folder_exists "$bench_dir" "$optional_app"; then
      status_line "Optional: ${optional_app}" "WARN" "downloaded but not installed"
    else
      status_line "Optional: ${optional_app}" "INFO" "not installed"
    fi
  done

  local common_config="${bench_dir}/sites/common_site_config.json"
  if path_is_file "$common_config"; then
    if $SUDO grep -q '"default_site"[[:space:]]*:[[:space:]]*"'"${SITE_NAME}"'"' "$common_config" 2>/dev/null; then
      status_line "Default site" "OK" "${SITE_NAME}"
    else
      status_line "Default site" "WARN" "not set to ${SITE_NAME}"
    fi
  else
    status_line "Common config" "WARN" "common_site_config.json missing at ${common_config}"
  fi

  local port label item
  local port_checks=(
    "8000:Bench web"
    "9000:Socket.io"
    "11000:Bench Redis queue"
    "13000:Bench Redis cache"
  )

  for item in "${port_checks[@]}"; do
    port="${item%%:*}"
    label="${item#*:}"
    if port_listens "$port"; then
      status_line "$label" "OK" "port ${port} listening"
    else
      status_line "$label" "INFO" "port ${port} not listening"
    fi
  done

  if path_is_executable "${FRAPPE_HOME}/start-erpnext-dev.sh"; then
    status_line "Start helper" "OK" "${FRAPPE_HOME}/start-erpnext-dev.sh"
  else
    status_line "Start helper" "WARN" "missing or not executable at ${FRAPPE_HOME}/start-erpnext-dev.sh"
  fi

  if path_is_file "${FRAPPE_HOME}/erpnext-dev-credentials.txt"; then
    status_line "Credentials file" "OK" "${FRAPPE_HOME}/erpnext-dev-credentials.txt"
  else
    status_line "Credentials file" "WARN" "missing at ${FRAPPE_HOME}/erpnext-dev-credentials.txt"
  fi

  status_line "VM IP" "INFO" "$(get_vm_ip)"
  status_line "Direct IP URL" "INFO" "http://$(get_vm_ip):8000"
  status_line "Friendly URL" "INFO" "http://${SITE_NAME}:8000"
  status_line "Host /etc/hosts" "INFO" "$(get_vm_ip) ${SITE_NAME}"

  echo
  echo "Log file: ${LOG_FILE}"
  echo "============================================================"
}






production_ops_summary() {
  local install_state_value runtime_value ssl_pair ssl_state ssl_detail
  local latest_lines completeness off_pair off_state off_detail
  local rehearsal_pair rehearsal_state rehearsal_detail health_pair health_state health_detail go_pair go_state go_detail

  install_state_value="$(production_quick_install_state 2>/dev/null || echo Unknown)"
  runtime_value="$(runtime_state 2>/dev/null || echo Unknown)"
  ssl_pair="$(production_ssl_overall_status 2>/dev/null || echo 'WARN|not confirmed')"
  ssl_state="${ssl_pair%%|*}"
  ssl_detail="${ssl_pair#*|}"

  latest_lines="$(backup_latest_set_paths 2>/dev/null || true)"
  if [[ -n "$latest_lines" ]]; then
    completeness="$(printf '%s\n' "$latest_lines" | sed -n '6p')"
  else
    completeness="none"
  fi

  off_pair="$(off_vm_backup_summary_pair 2>/dev/null || echo 'WARN|not configured')"
  off_state="${off_pair%%|*}"
  off_detail="${off_pair#*|}"
  rehearsal_pair="$(restore_rehearsal_summary_pair 2>/dev/null || echo 'WARN|not recorded')"
  rehearsal_state="${rehearsal_pair%%|*}"
  rehearsal_detail="${rehearsal_pair#*|}"
  go_pair="$(go_live_summary_pair 2>/dev/null || echo 'WARN|not recorded')"
  go_state="${go_pair%%|*}"
  go_detail="${go_pair#*|}"

  status_line "Runtime" "$([[ "$runtime_value" == Running* ]] && echo OK || echo WARN)" "$runtime_value"
  status_line "Install" "$([[ "$install_state_value" == Installed ]] && echo OK || echo WARN)" "$install_state_value"
  status_line "HTTPS" "$ssl_state" "$ssl_detail"

  if ufw_is_active; then
    status_line "Security" "OK" "UFW active"
  else
    status_line "Security" "WARN" "UFW not active"
  fi

  status_line "Local backup" "$([[ "$completeness" == complete ]] && echo OK || echo WARN)" "latest set ${completeness:-none}"
  status_line "Off-VM backup" "$off_state" "$off_detail"
  status_line "Restore rehearsal" "$rehearsal_state" "$rehearsal_detail"

  if health_check_timer_active; then
    health_pair="$(health_check_summary_pair 2>/dev/null || echo 'WARN|state unavailable')"
    health_state="${health_pair%%|*}"
    health_detail="${health_pair#*|}"
    status_line "Health monitoring" "$health_state" "timer active; $health_detail"
  else
    status_line "Health monitoring" "INFO" "timer not configured"
  fi

  status_line "Go-live validation" "$go_state" "$go_detail"
}

production_ops_breadcrumb_title() {
  printf 'ERPNext Production Operations > %s' "$1"
}

production_ops_services_menu() {
  require_sudo
  while true; do
    ui_box_start "$(production_ops_breadcrumb_title "Services and Recovery")"
    echo "1) Service status"
    echo "2) Start ERPNext service"
    echo "3) Stop ERPNext service"
    echo "4) Restart ERPNext service"
    echo "5) Wait for ERPNext readiness"
    echo "6) Service logs"
    echo "7) Follow service logs"
    echo "8) Service recovery plan"
    menu_footer
    menu_read_choice services_choice
    case "$services_choice" in
      1) show_erpnext_service_status; pause_after_screen "Press Enter to return to Services and Recovery..." ;;
      2) start_erpnext_service; pause_after_screen "Press Enter to return to Services and Recovery..." ;;
      3) stop_erpnext_service; pause_after_screen "Press Enter to return to Services and Recovery..." ;;
      4) restart_erpnext_service; pause_after_screen "Press Enter to return to Services and Recovery..." ;;
      5) wait_for_erpnext_ready; pause_after_screen "Press Enter to return to Services and Recovery..." ;;
      6) show_erpnext_service_logs; pause_after_screen "Press Enter to return to Services and Recovery..." ;;
      7) follow_erpnext_service_logs ;;
      8) show_service_recovery_plan; pause_after_screen "Press Enter to return to Services and Recovery..." ;;
      b|B|"") return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}

production_ops_backups_menu() {
  require_sudo
  while true; do
    ui_box_start "$(production_ops_breadcrumb_title "Local Backups")"
    echo "1) Create database + files backup"
    echo "2) Backup status"
    echo "3) Verify latest backup"
    echo "4) Scheduled backup plan"
    echo "5) Configure scheduled backups"
    echo "6) Scheduled backup status"
    echo "7) Retention plan"
    echo "8) Retention status"
    echo "9) Cleanup old backups dry run"
    echo "10) Cleanup old backups"
    echo "11) Full backup/maintenance menu"
    menu_footer
    menu_read_choice local_backup_choice
    case "$local_backup_choice" in
      1) create_site_backup true; pause_after_screen "Press Enter to return to Local Backups..." ;;
      2) show_backup_status; pause_after_screen "Press Enter to return to Local Backups..." ;;
      3) verify_latest_backup_set; pause_after_screen "Press Enter to return to Local Backups..." ;;
      4) show_backup_schedule_plan; pause_after_screen "Press Enter to return to Local Backups..." ;;
      5) configure_backup_schedule; pause_after_screen "Press Enter to return to Local Backups..." ;;
      6) show_backup_schedule_status; pause_after_screen "Press Enter to return to Local Backups..." ;;
      7) show_backup_retention_plan; pause_after_screen "Press Enter to return to Local Backups..." ;;
      8) show_backup_retention_status; pause_after_screen "Press Enter to return to Local Backups..." ;;
      9) cleanup_old_backups dry-run; pause_after_screen "Press Enter to return to Local Backups..." ;;
      10) cleanup_old_backups prompt; pause_after_screen "Press Enter to return to Local Backups..." ;;
      11) run_backup_maintenance_menu ;;
      b|B|"") return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}

production_ops_restore_menu() {
  require_sudo
  while true; do
    ui_box_start "$(production_ops_breadcrumb_title "Restore Readiness and Rehearsal")"
    echo "1) Restore rehearsal status"
    echo "2) Restore rehearsal guide"
    echo "3) Restore rehearsal wizard"
    echo "4) Restore preflight"
    echo "5) Record completed restore rehearsal"
    echo "6) Restore rehearsal report"
    echo "7) List local backups"
    echo "8) Restore database only"
    echo "9) Restore database + files"
    menu_footer
    menu_read_choice restore_choice
    case "$restore_choice" in
      1) show_restore_rehearsal_status; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      2) show_restore_rehearsal_guide; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      3) restore_rehearsal_wizard; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      4) show_restore_preflight; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      5) record_restore_rehearsal; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      6) show_restore_rehearsal_report; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      7) list_site_backups; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      8) restore_site_database; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      9) restore_site_full; pause_after_screen "Press Enter to return to Restore Readiness..." ;;
      b|B|"") return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}

production_ops_security_menu() {
  require_sudo
  while true; do
    ui_box_start "$(production_ops_breadcrumb_title "Security and Firewall")"
    echo "1) Firewall hardening status"
    echo "2) VM firewall status"
    echo "3) Security hardening wizard"
    echo "4) Configure VM firewall"
    echo "5) Production firewall profile"
    echo "6) Configure Fail2Ban"
    echo "7) Fail2Ban status"
    echo "8) Cloud firewall checklist"
    menu_footer
    menu_read_choice security_choice
    case "$security_choice" in
      1) show_firewall_hardening_status; pause_after_screen "Press Enter to return to Security and Firewall..." ;;
      2) show_vm_firewall_status; pause_after_screen "Press Enter to return to Security and Firewall..." ;;
      3) security_hardening_wizard; pause_after_screen "Press Enter to return to Security and Firewall..." ;;
      4) configure_vm_firewall; pause_after_screen "Press Enter to return to Security and Firewall..." ;;
      5) configure_production_vm_firewall; pause_after_screen "Press Enter to return to Security and Firewall..." ;;
      6) configure_fail2ban; pause_after_screen "Press Enter to return to Security and Firewall..." ;;
      7) show_fail2ban_status; pause_after_screen "Press Enter to return to Security and Firewall..." ;;
      8) show_cloud_firewall_checklist; pause_after_screen "Press Enter to return to Security and Firewall..." ;;
      b|B|"") return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}

production_ops_https_menu() {
  require_sudo
  while true; do
    ui_box_start "$(production_ops_breadcrumb_title "HTTPS and Certificates")"
    echo "1) Production SSL status"
    echo "2) SSL mode status"
    echo "3) Production HTTPS / SSL menu"
    echo "4) Cloudflare Origin CA status"
    echo "5) Cloudflare checklist"
    echo "6) SSL compatibility guide"
    menu_footer
    menu_read_choice https_choice
    case "$https_choice" in
      1) show_production_ssl_status; pause_after_screen "Press Enter to return to HTTPS and Certificates..." ;;
      2) show_ssl_mode_status; pause_after_screen "Press Enter to return to HTTPS and Certificates..." ;;
      3) show_production_ssl_menu; pause_after_screen "Press Enter to return to HTTPS and Certificates..." ;;
      4) show_cloudflare_origin_ssl_status; pause_after_screen "Press Enter to return to HTTPS and Certificates..." ;;
      5) show_cloudflare_checklist; pause_after_screen "Press Enter to return to HTTPS and Certificates..." ;;
      6) show_ssl_mode_guide; pause_after_screen "Press Enter to return to HTTPS and Certificates..." ;;
      b|B|"") return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}

production_ops_support_menu() {
  require_sudo
  while true; do
    ui_box_start "$(production_ops_breadcrumb_title "Support and Diagnostics")"
    echo "1) Doctor"
    echo "2) Doctor JSON"
    echo "3) Production checklist"
    echo "4) Final QA"
    echo "5) Command audit"
    echo "6) Create support bundle"
    echo "7) Show latest support bundle contents"
    echo "8) Storage status"
    echo "9) Port status"
    echo "10) Verify toolkit integrity"
    echo "11) Audit latest support bundle"
    menu_footer
    menu_read_choice support_choice
    case "$support_choice" in
      1) run_doctor_plain; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      2) run_doctor_json; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      3) show_production_checklist; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      4) final_qa_wizard; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      5) show_command_audit; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      6) create_support_bundle; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      7) show_latest_support_bundle_contents; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      8) show_storage_status; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      9) support_bundle_port_status; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      10) verify_toolkit_integrity; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      11) support_bundle_audit_archive; pause_after_screen "Press Enter to return to Support and Diagnostics..." ;;
      b|B|"") return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}

show_latest_support_bundle_contents() {
  require_sudo
  ui_box_start "Latest Support Bundle Contents"
  local latest_bundle
  latest_bundle="$(ls -t /tmp/erpnext-dev-support-bundle-*.tar.gz 2>/dev/null | head -n 1 || true)"
  if [[ -z "$latest_bundle" ]]; then
    status_line "Support bundle" "WARN" "no /tmp/erpnext-dev-support-bundle-*.tar.gz archive found"
    ui_next "$(toolkit_cmd support-bundle)"
    ui_box_end
    return 0
  fi
  status_line "Latest bundle" "OK" "$latest_bundle"
  echo
  tar -tzf "$latest_bundle" || warn "Could not list archive contents"
  ui_box_end
}

support_bundle_audit_archive() {
  local archive="${SUPPORT_BUNDLE_AUDIT_ARCHIVE:-}"
  local tmpdir listing_file hit_file rc=0 file_count=0

  if [[ -z "$archive" ]]; then
    archive="$(ls -t /tmp/erpnext-dev-support-bundle-*.tar.gz 2>/dev/null | head -n 1 || true)"
  fi

  ui_box_start "Support Bundle Audit"

  if [[ -z "$archive" ]]; then
    status_line "Support bundle" "WARN" "no /tmp/erpnext-dev-support-bundle-*.tar.gz archive found"
    ui_next "$(toolkit_cmd support-bundle)"
    ui_box_end
    return 1
  fi

  if [[ ! -f "$archive" ]]; then
    status_line "Archive" "FAIL" "not found: ${archive}"
    ui_box_end
    return 1
  fi

  status_line "Archive" "OK" "$archive"

  tmpdir="$(mktemp -d /tmp/erpnext-support-audit.XXXXXX)"
  listing_file="${tmpdir}/archive-list.txt"
  hit_file="${tmpdir}/audit-hits.txt"

  if ! tar -tzf "$archive" > "$listing_file" 2>"${tmpdir}/tar-list.stderr"; then
    status_line "Archive listing" "FAIL" "tar could not list archive"
    sed -n '1,40p' "${tmpdir}/tar-list.stderr" 2>/dev/null || true
    rm -rf "$tmpdir"
    ui_box_end
    return 1
  fi

  file_count="$(grep -cve '/$' "$listing_file" 2>/dev/null || echo 0)"
  status_line "Archive listing" "OK" "${file_count} file(s)"

  if grep -Ei '(^|/)(site_config\.json|site_config_backup\.json|.*credentials.*|id_rsa|id_ed25519|.*\.pem|.*\.key|.*\.sql(\.gz)?|.*database.*\.gz|.*private-files\.tar)$' "$listing_file" > "$hit_file"; then
    status_line "Forbidden filenames" "FAIL" "potential secret/backup filenames found"
    sed -n '1,80p' "$hit_file"
    rc=1
  else
    status_line "Forbidden filenames" "OK" "none found"
  fi

  if tar -xzf "$archive" -C "$tmpdir" 2>"${tmpdir}/tar-extract.stderr"; then
    if grep -RInE '(-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----|Bearer[[:space:]]+[A-Za-z0-9._~+/=-]+|("?(password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key|authorization|cookie|db_password|admin_password)"?[[:space:]]*[:=][[:space:]]*[^[:space:],;}]+))'       --exclude='archive-list.txt'       --exclude='audit-hits.txt'       "$tmpdir" > "$hit_file" 2>/dev/null; then
      status_line "Secret pattern scan" "FAIL" "possible unredacted secret pattern found"
      sed -n '1,80p' "$hit_file"
      rc=1
    else
      status_line "Secret pattern scan" "OK" "no obvious secret patterns found"
    fi
  else
    status_line "Archive extract" "FAIL" "tar could not extract archive for content scan"
    sed -n '1,40p' "${tmpdir}/tar-extract.stderr" 2>/dev/null || true
    rc=1
  fi

  rm -rf "$tmpdir"

  if [[ "$rc" -eq 0 ]]; then
    status_line "Audit result" "OK" "support bundle passed filename and content checks"
  else
    status_line "Audit result" "FAIL" "review findings before sharing bundle"
  fi

  echo
  echo "Scope: best-effort audit for common secret filenames and obvious token/password/private-key patterns."
  echo "Always manually review support bundles before external sharing."
  ui_box_end
  return "$rc"
}

production_ops_wizard() {
  require_sudo
  while true; do
    ui_box_start "ERPNext Production Operations"
    status_line "Site" "INFO" "$SITE_NAME"
    status_line "Toolkit" "INFO" "v${SCRIPT_VERSION}"
    echo
    echo "Current state"
    production_ops_summary
    echo
    echo "1) System health and readiness"
    echo "2) Services and recovery"
    echo "3) Local backups"
    echo "4) Off-VM backups"
    echo "5) Restore readiness and rehearsal"
    echo "6) Health monitoring"
    echo "7) Security and firewall"
    echo "8) HTTPS and certificates"
    echo "9) Go-live validation"
    echo "10) Support and diagnostics"
    echo "11) Final QA"
    menu_footer quit-only
    menu_read_choice ops_choice
    case "$ops_choice" in
      1) show_release_readiness; pause_after_screen "Press Enter to return to Production Operations..." ;;
      2) production_ops_services_menu ;;
      3) production_ops_backups_menu ;;
      4) off_vm_backup_wizard; pause_after_screen "Press Enter to return to Production Operations..." ;;
      5) production_ops_restore_menu ;;
      6) PRODUCTION_OPS_CONTEXT=1 health_monitoring_wizard; pause_after_screen "Press Enter to return to Production Operations..." ;;
      7) production_ops_security_menu ;;
      8) production_ops_https_menu ;;
      9) show_go_live_status; pause_after_screen "Press Enter to return to Production Operations..." ;;
      10) production_ops_support_menu ;;
      11) final_qa_wizard; pause_after_screen "Press Enter to return to Production Operations..." ;;
      "") continue ;;
      b|B) return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}




show_command_audit() {
  ui_box_start "Command Audit / Key Workflows"
  status_line "Start here" "OK" "first-run, public-vm-guided-setup, public-vm-quickstart, local-dev-quickstart"
  status_line "Preflight" "OK" "install-preflight, environment-preflight"
  status_line "Toolkit CLI" "OK" "where-installed, install-cli, repair-cli, update-toolkit"
  status_line "Config" "OK" "set-domain, show-config, setup-effort-guide"
  status_line "Install/status" "OK" "guided-setup, status, doctor, support-bundle"
  status_line "Credentials" "OK" "credentials-info, credentials-show, credentials-file-status, credentials-secure, credentials-delete, reset-admin-password"
  status_line "Production SSL" "OK" "production-ssl-wizard, production-ssl-status, ssl-mode-status"
  status_line "Cloudflare" "OK" "cloudflare-origin-guide, configure-cloudflare-origin-ssl"
  status_line "Security" "OK" "security-hardening-wizard, vm-firewall-status, fail2ban-status"
  status_line "Firewall" "OK" "firewall-hardening-status, production-firewall-plan"
  status_line "Backups" "OK" "backup-files, backup-status, backup-verify, backup-hardening-wizard"
  status_line "Scheduled backups" "OK" "backup-schedule-plan, configure-backup-schedule, backup-schedule-status, scheduled-backup-status"
  status_line "Backup retention" "OK" "backup-retention-plan, backup-retention-status, cleanup-old-backups"
  status_line "Off-VM backup" "OK" "off-vm-backup-plan, configure-rsync-backup-target, run-off-vm-backup"
  status_line "Health monitoring" "OK" "health-monitoring-wizard, health-check, configure-health-check-timer, health-check-status, health-check-journal"
  status_line "Go-live validation" "OK" "go-live-record, go-live-status, cloud-firewall-checklist, cloudflare-checklist"
  status_line "Restore safety" "OK" "restore-rehearsal-guide, restore-rehearsal-status, restore-rehearsal-record, restore-preflight, restore-db, restore-full"
  status_line "Optional apps" "OK" "app-install-wizard, app-status, app-compatibility, install-payments, install-webshop, install-builder, install-lms, install-education, install-wiki, install-print-designer, install-drive, install-raven, advanced-app-tools"
  ui_box_end
  ui_next "$(toolkit_cmd release-readiness)" "$(toolkit_cmd help)"
}




show_advanced_menu() {
  while true; do
    echo
    echo "============================================================"
    echo "Advanced Options"
    echo "============================================================"
    print_two_column_menu       "1) Install / Reinstall"       "2) Repair Environment"       "3) Uninstall / Reset"       "4) Autostart / Service Manager"       "5) Backup / Maintenance"       "6) App Library"       "7) Optional App Status"       "8) Full Health Report"       "9) VM Network Status"       "10) Environment / location check"       "11) KVM Fixed IP Guide"       "12) Multi-Environment Guide"       "13) Local VM HTTPS / SSL"       "14) Local SSL Status"       "15) Local SSL Guide"       "16) Local SSL Wizard"       "17) Trusted mkcert SSL Guide"       "18) Browser Trust Check Guide"       "19) Install/Replace Local SSL Cert"       "20) Verify Local SSL"       "21) Create Self-Signed Local Cert"       "22) Configure Local SSL"       "23) Disable Local SSL"       "24) Verify SSL Rollback"       "25) Storage Status"       "26) Expand Root Storage"       "27) Verify Storage"       "28) Domain Config"       "29) Production Readiness Preview"       "30) Production Domain Guide"       "31) Production SSL Guide"       "32) Public VM Readiness"       "33) Production SSL Plan"       "34) Production Firewall Plan"       "35) Firewall Hardening Status"       "36) Configure Production SSL"       "37) Production SSL Status"       "38) Disable Production SSL"       "39) Start Bench in Foreground"       "40) Show Service Logs"       "41) Access Submenu"       "42) Next Step"       "43) Verify ERPNext HTTP Access"       "44) App Install Wizard"       "45) App Rollback Guide"       "46) Install Environment Preflight"       "47) Change Local Domain"
    menu_footer
    menu_read_choice advanced_choice

    case "$advanced_choice" in
      1) run_install ;;
      2) run_repair ;;
      3) run_uninstall_menu ;;
      4) show_service_menu ;;
      5) run_backup_maintenance_menu ;;
      6) show_app_library_menu ;;
      7) run_app_status ;;
      8) run_full_status ;;
      9) show_network_status ;;
      10) show_environment_check ;;
      11) show_kvm_fixed_ip_guide ;;
      12) show_multi_environment_guide ;;
      13) show_local_ssl_menu ;;
      14) show_ssl_status ;;
      15) show_local_ssl_guide ;;
      16) run_local_ssl_wizard ;;
      17) show_mkcert_local_ssl_guide ;;
      18) show_browser_trust_check_guide ;;
      19) install_local_ssl_cert ;;
      20) verify_local_ssl ;;
      21) create_self_signed_local_cert ;;
      22) configure_local_ssl ;;
      23) disable_local_ssl ;;
      24) verify_ssl_rollback ;;
      25) show_storage_status ;;
      26) expand_root_storage ;;
      27) verify_storage ;;
      28) show_domain_config ;;
      29) show_production_readiness ;;
      30) show_production_domain_guide ;;
      31) show_production_ssl_guide ;;
      32) show_public_vm_readiness ;;
      33) show_production_ssl_plan ;;
      34) show_production_firewall_plan ;;
      35) show_firewall_hardening_status ;;
      36) configure_production_ssl ;;
      37) show_production_ssl_status ;;
      38) disable_production_ssl ;;
      39) run_foreground_start ;;
      40) show_erpnext_service_logs ;;
      41) show_access_menu ;;
      42) show_next_step ;;
      43) verify_access ;;
      44) run_app_install_wizard ;;
      45) show_app_rollback_guide ;;
      46) run_install_preflight ;;
      47) change_local_domain_wizard ;;
      b|B|"") return 0 ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}

menu_navigation_self_test() {
  # Safe smoke test for interactive menus. It checks navigation input only.
  # It does not choose install, SSL, firewall, backup, app, or destructive actions.
  local script rc out failures=0 tested=0
  local action input
  local invoke=(bash)
  script="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")"

  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      invoke=(sudo -E bash)
    else
      ui_box_start "Menu Navigation Self-Test"
      status_line "Menu navigation" "FAIL" "menu-self-test requires root or sudo"
      ui_box_end
      return 1
    fi
  fi

  ui_box_start "Menu Navigation Self-Test"
  echo "Testing q/Q and b/B handling for non-destructive menu entry points."
  echo

  local quit_actions=(
    menu
    first-run
    advanced
    access
    status-menu
    local-ssl-menu
    local-ssl-wizard
    production-ssl-menu
    app-library
    advanced-app-tools
    backup-menu
    maintenance
    backup-hardening-wizard
    off-vm-backup-wizard
    production-ops-wizard
    health-monitoring-wizard
    security-hardening-wizard
    final-qa-wizard
    uninstall
  )

  for action in "${quit_actions[@]}"; do
    for input in q Q; do
      tested=$((tested + 1))
      out="$(printf '%s\n' "$input" | timeout 5 "${invoke[@]}" "$script" "$action" 2>&1)"
      rc=$?
      if (( rc != 0 )) || printf '%s\n' "$out" | grep -Eqi 'Invalid option|command not found|unbound variable|syntax error'; then
        failures=$((failures + 1))
        status_line "${action} ${input}" "FAIL" "q/Q did not exit cleanly"
      fi
    done
  done

  local back_actions=(
    first-run
    advanced
    access
    status-menu
    local-ssl-menu
    local-ssl-wizard
    production-ssl-menu
    app-library
    advanced-app-tools
    backup-menu
    maintenance
    backup-hardening-wizard
    off-vm-backup-wizard
    production-ops-wizard
    health-monitoring-wizard
    security-hardening-wizard
    final-qa-wizard
  )

  for action in "${back_actions[@]}"; do
    for input in b B; do
      tested=$((tested + 1))
      out="$(printf '%s\nq\n' "$input" | timeout 5 "${invoke[@]}" "$script" "$action" 2>&1)"
      rc=$?
      if (( rc != 0 )) || printf '%s\n' "$out" | grep -Eqi 'Invalid option|command not found|unbound variable|syntax error'; then
        failures=$((failures + 1))
        status_line "${action} ${input}" "FAIL" "b/B did not return cleanly"
      fi
    done
  done

  # Test a few nested submenu paths where prior bugs could drop the user into shell.
  local nested_tests=(
    "advanced|4|q"
    "advanced|5|q"
    "advanced|6|q"
    "advanced|13|q"
    "menu|8|q"
    "menu|9|q"
    "menu|12|q"
    "menu|13|q"
    "health-monitoring-wizard|3|q"
    "production-ops-wizard|6|b"
    "production-ops-wizard|10|b"
  )
  local row root select quit
  for row in "${nested_tests[@]}"; do
    IFS='|' read -r root select quit <<< "$row"
    tested=$((tested + 1))
    out="$(printf '%s\n%s\n' "$select" "$quit" | timeout 5 "${invoke[@]}" "$script" "$root" 2>&1)"
    rc=$?
    if (( rc != 0 )) || printf '%s\n' "$out" | grep -Eqi 'command not found|unbound variable|syntax error'; then
      failures=$((failures + 1))
      status_line "${root}->${select}->${quit}" "FAIL" "nested menu quit failed"
    fi
  done

  status_line "Tests executed" "INFO" "$tested"
  if (( failures == 0 )); then
    status_line "Menu navigation" "OK" "q/Q and b/B handled cleanly in tested menus"
  else
    status_line "Menu navigation" "FAIL" "${failures} failure(s) detected"
    ui_box_end
    return 1
  fi
  ui_box_end
}

show_help() {
  cat <<EOF_HELP
${APP_NAME} v${SCRIPT_VERSION}

Usage:
  $(toolkit_cmd "[command]")

Start here:
  first-run           Pick local VM, public VM, or maintenance flow
  public-vm-guided-setup Guided production VPS setup; domain -> DNS -> install -> HTTPS -> security -> QA
  public-vm-quickstart Public VM manual menu for production tasks
  local-dev-quickstart Local VM setup; prompts for domain, Enter defaults to erp.test
  install-preflight   Check OS, internet, CPU, RAM, disk, and /tmp before installing
  set-domain          Save public domain and site config
  show-config         Show saved toolkit config
  setup-effort-guide  Show commands/input count by setup type
  setup-lifecycle-plan Show recommended local/production setup order

Core:
  version             Print toolkit version
  where-installed     Show active script, stable /opt path, CLI path, and config path
  verify-toolkit      Show installed script SHA256 and compare against SHA256SUMS when available
  install-cli         Install or repair the erpnext-dev command
  repair-cli          Alias for install-cli
  update-toolkit      Download latest erpnext-dev.sh from GitHub and update /opt copy
  menu-self-test      Validate q/Q and b/B handling across interactive menus
  guided-setup        Guided install / repair workflow
  status              Compact ERPNext status
  verify-access       HTTP access checks
  access-info         Show Desk, login, portal, and host access URLs
  education-access-info Show Education portal and ERPNext Desk URLs
  credentials-info    Safe credential overview; does not print passwords
  credentials-show    Show generated passwords after confirmation
  credentials-file-status Check owner/mode/age of the credentials file
  credentials-secure  Set credentials file to root:root 600
  credentials-delete  Delete local plaintext credentials file after secure handoff
  reset-admin-password Reset ERPNext Administrator password safely
  next-step           Recommended next action
  doctor --plain      Safe diagnostics
  support-bundle      Redacted troubleshooting archive
  support-bundle-audit Audit latest support bundle for forbidden filenames and obvious secret patterns
  environment-preflight Alias for install-preflight

Local VM HTTPS / SSL:
  local-ssl-menu       Local VM HTTPS / SSL submenu
  local-ssl-wizard     Guided local HTTPS setup; Back opens main menu when run directly
  trusted-mkcert-setup Guided mkcert setup; installs copied cert/key when available
  change-local-domain  Rename the local VM domain/site and update toolkit config
  local-domain-status  Show dynamic VM IP, local domain, and host mapping status
  local-access-doctor  Diagnose local URL/DNS/firewall/access issues
  local-host-checkpoint Required safe host mapping checkpoint before local HTTPS
  host-dns-guide       Print host-side /etc/hosts commands using the current VM IP
  local-fixed-ip-guide  Print KVM/libvirt DHCP reservation guidance for a stable local VM IP
  local-ssl-guide      Local SSL guide
  ssl-status           Local SSL status
  install-local-ssl-cert Install/replace local certificate from /tmp
  create-self-signed-local-cert Create local self-signed certificate
  verify-local-ssl     Verify local HTTPS access
  disable-local-ssl    Disable local HTTPS config

Production / HTTPS:
  production-readiness    Production-candidate check
  production-ssl-menu     Production HTTPS / SSL submenu
  production-ssl-wizard   Choose Let's Encrypt or Cloudflare Origin CA
  production-ssl-status   HTTPS/Nginx/certificate status
  ssl-mode-status         Recommended SSL mode for current config
  ssl-mode-guide          SSL compatibility matrix
  public-vm-readiness     Public VM DNS/access/listener check

Security:
  security-hardening-wizard  Environment-aware UFW + Fail2Ban workflow
  security-mode-status       Show local vs production hardening context
  local-firewall-profile     Apply local VM profile; keeps 8000/9000 reachable privately
  production-firewall-profile Apply production profile; blocks backend ports
  repair-local-access        Restore local erp.test / port 8000 access after over-hardening
  firewall-rollback-snapshots Show saved UFW rule snapshots
  firewall-hardening-status  Cloud firewall + backend-port guidance
  vm-firewall-status         UFW status
  fail2ban-status            SSH jail status

Backup / Restore:
  backup-files        Database + files backup
  backup-status       Backup inventory and latest-set status
  backup-verify       Verify latest backup files without restoring
  backup-schedule-plan Show scheduled-backup design
  configure-backup-schedule Enable local scheduled backups with systemd
  backup-schedule-status Show scheduled backup timer status
  scheduled-backup-status Alias for backup-schedule-status
  backup-retention-plan Show local backup retention policy
  cleanup-old-backups-dry-run Preview old backup cleanup
  off-vm-backup-plan  Show rsync off-VM backup plan
  off-vm-backup-guided-setup Guided two-server off-VM backup setup
  generate-off-vm-backup-key Create dedicated rsync SSH key on ERPNext VM
  backup-server-setup Prepare a remote Linux server to receive backups
  configure-rsync-backup-target Save off-VM rsync target
  off-vm-backup-dry-run Preview off-VM rsync copy
  run-off-vm-backup   Copy backups to configured off-VM target
  off-vm-backup-status Show off-VM backup configuration/status
  off-vm-backup-guide Commands to copy backups off this VM
  health-monitoring-wizard Guided health timer and monitoring workflow
  health-check       Compact production health check
  health-check-run-now Alias for health-check
  configure-health-check-timer Enable periodic health checks with systemd
  health-check-status Show health check timer and last health status
  health-check-journal Show recent health-check systemd journal output
  service-recovery-plan Manual service recovery checklist
  restore-preflight   Safe restore readiness check
  restore-rehearsal-guide Safe restore test plan
  restore-rehearsal-status Show recorded restore rehearsal status
  restore-rehearsal-record Record completed restore rehearsal evidence on production VM
  restore-rehearsal-report Print restore evidence from a disposable restore VM
  go-live-record    Record snapshot/firewall/Cloudflare go-live validation
  go-live-status    Show recorded external go-live validation status
  cloud-firewall-checklist Show provider firewall checklist
  cloudflare-checklist Show Cloudflare DNS/SSL checklist
  restore-rehearsal-wizard Guided off-VM restore rehearsal workflow
  restore-key-setup   Generate a temporary restore SSH key and exact backup-server command
  pull-off-vm-backup  Pull off-VM backups to this restore VM with rsync
  backup-server-add-restore-key Add a temporary restore key on the backup server
  backup-server-remove-restore-key Remove temporary restore keys from the backup server
  backup-hardening-wizard Backup and restore readiness workflow

Production checklist:
  production-checklist  Go-live readiness checklist
  release-readiness    Compact final QA readiness summary
  final-qa             Final QA / release-readiness wizard
  production-ops-wizard Unified production operations dashboard
  production-ops-dashboard Alias for production-ops-wizard
  backup-retention-plan Backup retention and cleanup plan
  cleanup-old-backups-dry-run Preview old backup cleanup

Apps:
  app-install-wizard  Optional Frappe app installer
  app-status          Optional app status
  app-compatibility   Optional app compatibility matrix
  install-payments    Install Frappe Payments
  install-webshop     Install Frappe Webshop / E-Commerce
  install-builder     Install Frappe Builder
  install-lms         Install Frappe Learning / LMS
  install-education   Install Frappe Education
  install-wiki        Install Frappe Wiki
  install-print-designer Install Frappe Print Designer
  install-drive       Install Frappe Drive
  install-raven       Install Raven Team Chat
  advanced-app-tools Advanced app tools for custom apps and repairs
  install-custom-app Advanced: install trusted custom app from Git URL

Guides:
  production-domain-plan   DNS/domain plan
  production-ssl-plan      SSL plan
  production-firewall-plan Firewall plan
  cloudflare-origin-guide  Cloudflare Origin CA guide
  vm-firewall-plan         UFW plan

Menus:
  menu        Main menu
  advanced    Full advanced menu
  maintenance Backup/maintenance menu

Examples:
  $(toolkit_cmd first-run)
  $(toolkit_cmd public-vm-guided-setup)
  $(toolkit_cmd public-vm-quickstart)
  $(toolkit_cmd local-dev-quickstart)
  $(toolkit_cmd local-ssl-menu)
  $(toolkit_cmd production-ssl-wizard)
  $(toolkit_cmd security-hardening-wizard)
  $(toolkit_cmd final-qa)
  $(toolkit_cmd production-ops-wizard)

Options:
  -y, --yes  Assume yes for supported confirmations

Verified release entry points:
  Public VM:
    VERSION="v${SCRIPT_VERSION}"; curl -fsSLO "https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/\${VERSION}/erpnext-dev.sh"; curl -fsSLO "https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/\${VERSION}/SHA256SUMS"; sha256sum -c SHA256SUMS; chmod +x erpnext-dev.sh; sudo ./erpnext-dev.sh public-vm-guided-setup
  Local VM:
    VERSION="v${SCRIPT_VERSION}"; curl -fsSLO "https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/\${VERSION}/erpnext-dev.sh"; curl -fsSLO "https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/\${VERSION}/SHA256SUMS"; sha256sum -c SHA256SUMS; chmod +x erpnext-dev.sh; sudo ./erpnext-dev.sh local-dev-quickstart

Common environment overrides:
  SITE_NAME=erp.test
  PRODUCTION_DOMAIN=erp.company.com
  LETSENCRYPT_EMAIL=admin@example.com
  LETSENCRYPT_STAGING=true|false
  ADMIN_SSH_SOURCE_IP=68.144.2.171/32
  FAIL2BAN_SSH_BANTIME=1h
  FAIL2BAN_SSH_FINDTIME=10m
  FAIL2BAN_SSH_MAXRETRY=5
  BACKUP_SCHEDULE_ON_CALENDAR=daily
  BACKUP_SCHEDULE_RANDOM_DELAY=30m
  BACKUP_RETENTION_KEEP_COMPLETE=14
  BACKUP_RETENTION_WARN_DISK_PERCENT=80
  ERPNEXT_ALLOW_UNSAFE_INSTALL=false
  OFF_VM_BACKUP_TARGET=backup@example.com:/srv/erpnext-backups/site/
  OFF_VM_BACKUP_SSH_IDENTITY=/root/.ssh/id_ed25519
  OFF_VM_BACKUP_RSYNC_DELETE=false
  PAYMENTS_BRANCH=                # blank = repository default branch
  WEBSHOP_BRANCH=develop
  EDUCATION_BRANCH=version-16
  LMS_BRANCH=                     # blank = repository default branch

Use $(toolkit_cmd advanced) for the complete command menu.
After first run, use the short command: sudo erpnext-dev menu
EOF_HELP
}

show_menu() {
  while true; do
    echo
    echo "============================================================"
    echo "${APP_NAME} v${SCRIPT_VERSION}"
    echo "============================================================"
    print_two_column_menu       "1) Start here / setup wizard"       "2) Public VM quickstart"       "3) Local VM quickstart"       "4) Status"       "5) Start service"       "6) Stop service"       "7) Verify access"       "8) Local VM HTTPS / SSL"       "9) Production HTTPS / SSL"       "10) Security profiles"       "11) Backup / maintenance"       "12) Optional apps"       "13) Advanced"       "14) Final QA"       "15) Production operations"       "16) Help"
    menu_footer quit-only
    menu_read_choice choice

    case "$choice" in
      1) run_first_run_wizard ;;
      2) run_public_vm_guided_setup ;;
      3) run_local_dev_quickstart ;;
      4) show_status_menu ;;
      5) run_start ;;
      6) run_stop ;;
      7) verify_access ;;
      8) show_local_ssl_menu ;;
      9) show_production_ssl_menu ;;
      10) security_hardening_wizard ;;
      11) run_backup_maintenance_menu ;;
      12) show_app_library_menu ;;
      13) show_advanced_menu ;;
      14) final_qa_wizard ;;
      15) production_ops_wizard ;;
      16) show_help ;;
      q|Q) exit 0 ;;
      *) warn "Invalid option" ;;
    esac
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y|--yes)
        ASSUME_YES=1
        shift
        ;;
      --plain)
        DOCTOR_FORMAT="plain"
        shift
        ;;
      --json)
        DOCTOR_FORMAT="json"
        shift
        ;;
      first-run|start-here|quickstart|setup-wizard|public-vm-quickstart|public-setup|public-vm-guided-setup|public-guided-setup|production-guided-setup|local-dev-quickstart|local-setup|install-preflight|environment-preflight|set-domain|show-config|guided-setup|setup|install|repair|status|status-menu|runtime-status|install-status|service-summary|doctor|support-bundle|support|support-bundle-audit|audit-support-bundle|support-bundle-audit-test|full-status|start|stop|uninstall|advanced|access|verify-access|access-info|education-access-info|portal-access-info|desk-url|credentials-info|credentials|login-info|credentials-show|show-credentials|credentials-file-status|credentials-secure|credentials-delete|reset-admin-password|admin-password-reset|next-step|local-ssl-menu|local-https|local-vm-ssl|local-ssl-wizard|ssl-wizard|trusted-mkcert-setup|mkcert-setup|access-menu|access-info|education-access-info|portal-access-info|desk-url|backup-menu|backup|backup-files|backup-status|backup-verify|verify-backups|off-vm-backup-guide|restore-rehearsal-guide|restore-rehearsal-status|restore-rehearsal-record|restore-rehearsal-report|go-live-record|go-live-status|cloud-firewall-checklist|cloudflare-checklist|restore-rehearsal-wizard|restore-key-setup|pull-off-vm-backup|backup-server-add-restore-key|backup-server-remove-restore-key|backup-server-list-restore-keys|production-checklist|release-readiness|final-qa|final-qa-wizard|command-audit|release-notes-guide|backup-hardening-wizard|backup-wizard|backup-schedule-plan|configure-backup-schedule|backup-schedule-status|scheduled-backup-status|disable-backup-schedule|scheduled-backups|backup-retention-plan|backup-retention-status|cleanup-old-backups|cleanup-old-backups-dry-run|backup-cleanup-dry-run|backup-cleanup|off-vm-backup-plan|off-vm-backup-guided-setup|generate-off-vm-backup-key|off-vm-backup-keygen|backup-server-setup|prepare-backup-server|off-vm-backup-server-setup|configure-rsync-backup-target|off-vm-backup-dry-run|run-off-vm-backup|off-vm-backup-status|disable-off-vm-backup|off-vm-backup-wizard|credentials-info|credentials|login-info|credentials-show|show-credentials|credentials-file-status|credentials-secure|credentials-delete|reset-admin-password|admin-password-reset|health-check|health-check-run-now|configure-health-check-timer|health-check-status|health-check-journal|disable-health-check-timer|health-monitoring-wizard|production-monitoring-wizard|service-recovery-plan|restore-preflight|restore-rehearsal-wizard|restore-key-setup|pull-off-vm-backup|backup-server-add-restore-key|backup-server-remove-restore-key|backup-server-list-restore-keys|production-ops-wizard|production-ops-dashboard|operations-wizard|operations-dashboard|ops-wizard|ops-dashboard|list-backups|backups|restore-db|restore-full|maintenance|migrate|build|clear-cache|restart|wait-ready|menu|help|-h|--help|version|--version|where-installed|verify-toolkit|toolkit-verify|verify-install|install-cli|repair-cli|update-toolkit|menu-self-test|menu-navigation-self-test|foreground-start|enable-autostart|disable-autostart|service-start|service-stop|service-restart|service-status|logs|logs-follow|kvm-guide|kvm-identify|network-status|local-domain-status|local-host-checkpoint|host-dns-checkpoint|host-mapping-checkpoint|local-access-doctor|hosts-command|print-hosts-command|host-dns-guide|local-fixed-ip-guide|fixed-ip-guide|kvm-fixed-ip-guide|host-test|ssl-roadmap|ssl-status|local-ssl-guide|mkcert-guide|trusted-local-ssl-guide|browser-trust-guide|trust-check-guide|ssl-rollback-guide|verify-ssl-rollback|verify-local-ssl|install-local-ssl-cert|replace-local-ssl-cert|create-self-signed-local-cert|self-signed-local-cert|configure-local-ssl|disable-local-ssl|environment-check|where-am-i|site-config|domain-config|change-local-domain|local-domain-wizard|rename-local-site|change-site-domain|storage-status|storage-debug|expand-root-storage|verify-storage|production-readiness|production-plan|prod-plan|production-domain-plan|prod-domain-plan|public-vm-readiness|public-readiness|production-ssl-plan|prod-ssl-plan|production-firewall-plan|prod-firewall-plan|firewall-hardening-status|firewall-status|hardening-status|vm-firewall-plan|ufw-plan|configure-vm-firewall|local-firewall-profile|local-security-profile|production-firewall-profile|production-security-profile|repair-local-access|firewall-rollback-snapshots|vm-firewall-status|ufw-status|configure-fail2ban|fail2ban-status|security-hardening-wizard|vm-firewall-wizard|ufw-ssh-admin-only|production-ssl-menu|production-https|production-https-menu|configure-production-ssl|production-ssl-wizard|ssl-provider-wizard|ssl-mode-status|ssl-mode-guide|ssl-compatibility|setup-effort-guide|setup-step-count|setup-lifecycle-plan|setup-order-plan|configure-cloudflare-origin-ssl|install-cloudflare-origin-cert|switch-to-cloudflare-origin-ssl|cloudflare-origin-ssl-status|cloudflare-origin-guide|production-ssl-status|ssl-mode-status|ssl-mode-guide|ssl-compatibility|setup-effort-guide|setup-step-count|disable-production-ssl|production-domain-guide|production-ssl-guide|repair-site-config|site-name-guide|custom-site-guide|multi-env-guide|app-library|apps|list-apps|app-status|app-compatibility|app-compat|app-preflight|install-crm|install-hrms|install-helpdesk|install-telephony|install-insights|install-payments|install-webshop|install-ecommerce|install-builder|install-lms|install-education|install-wiki|install-print-designer|install-drive|install-raven|advanced-app-tools|app-advanced-tools|custom-app-tools|install-custom-app|app-install-wizard|app-wizard|app-install-guide|app-rollback-guide|repair-app-registry)
        ACTION="$1"
        shift
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done

  if [[ -z "${ACTION}" && "${DOCTOR_FORMAT}" != "human" ]]; then
    ACTION="doctor"
  fi
}

main() {
  parse_args "$@"

  if action_requires_lock "${ACTION:-menu}"; then
    acquire_toolkit_lock
  fi

  case "${ACTION:-menu}" in
    ""|menu) show_menu ;;
    version|--version) echo "${APP_NAME} v${SCRIPT_VERSION}" ;;
    where-installed) show_where_installed ;;
    verify-toolkit|toolkit-verify|verify-install) verify_toolkit_integrity ;;
    install-cli) install_toolkit_cli ;;
    repair-cli) repair_toolkit_cli ;;
    update-toolkit) update_toolkit ;;
    menu-self-test|menu-navigation-self-test) menu_navigation_self_test ;;
    first-run|start-here|quickstart|setup-wizard) run_first_run_wizard ;;
    public-vm-guided-setup|public-guided-setup|production-guided-setup) run_public_vm_guided_setup ;;
    public-vm-quickstart|public-setup) run_public_vm_quickstart ;;
    local-dev-quickstart|local-setup) run_local_dev_quickstart ;;
    install-preflight|environment-preflight) run_install_preflight ;;
    set-domain) prompt_and_save_public_domain ;;
    show-config) show_config_summary ;;
    guided-setup) run_guided_setup ;;
    setup|install) run_install ;;
    repair) run_repair ;;
    status) run_status ;;
    status-menu) show_status_menu ;;
    runtime-status) run_runtime_status ;;
    install-status) run_installation_status ;;
    service-summary) run_service_summary ;;
    doctor|full-status)
      case "$DOCTOR_FORMAT" in
        plain) run_doctor_plain ;;
        json) run_doctor_json ;;
        *) run_full_status ;;
      esac
      ;;
    support-bundle|support) create_support_bundle ;;
    support-bundle-audit|audit-support-bundle|support-bundle-audit-test) support_bundle_audit_archive ;;
    start) run_start ;;
    stop) run_stop ;;
    uninstall) run_uninstall_menu ;;
    advanced) show_advanced_menu ;;
    access|access-menu) show_access_menu ;;
    verify-access) verify_access ;;
    access-info|desk-url) show_access_info ;;
    education-access-info|portal-access-info) show_education_access_info ;;
    credentials-info|credentials|login-info) show_credentials_info ;;
    credentials-show|show-credentials) credentials_show ;;
    credentials-file-status) show_credentials_file_status ;;
    credentials-secure) credentials_secure ;;
    credentials-delete) credentials_delete ;;
    reset-admin-password|admin-password-reset) reset_admin_password ;;
    next-step) show_next_step ;;
    local-ssl-menu|local-https|local-vm-ssl) show_local_ssl_menu main ;;
    local-ssl-wizard|ssl-wizard) run_local_ssl_wizard main ;;
    backup-menu) run_backup_maintenance_menu ;;
    app-library|apps) show_app_library_menu ;;
    app-install-wizard|app-wizard) run_app_install_wizard ;;
    app-install-guide) show_app_install_guide ;;
    app-rollback-guide) show_app_rollback_guide ;;
    advanced-app-tools|app-advanced-tools|custom-app-tools) show_advanced_app_tools_menu ;;
    list-apps) show_installed_apps ;;
    app-status) run_app_status ;;
    app-compatibility|app-compat|app-preflight) show_app_compatibility_matrix ;;
    install-crm) install_app_profile crm ;;
    install-hrms) install_app_profile hrms ;;
    install-helpdesk) install_app_profile helpdesk ;;
    install-telephony) install_app_profile telephony ;;
    install-insights) install_app_profile insights ;;
    install-payments) install_app_profile payments ;;
    install-webshop|install-ecommerce) install_app_profile webshop ;;
    install-builder) install_app_profile builder ;;
    install-lms) install_app_profile lms ;;
    install-education) install_app_profile education ;;
    install-wiki) install_app_profile wiki ;;
    install-print-designer) install_app_profile print_designer ;;
    install-drive) install_app_profile drive ;;
    install-raven) install_app_profile raven ;;
    install-custom-app) install_custom_app_interactive ;;
    repair-app-registry) repair_app_registry ;;
    backup) create_site_backup false ;;
    backup-files) create_site_backup true ;;
    backup-status) show_backup_status ;;
    backup-verify|verify-backups) verify_latest_backup_set ;;
    off-vm-backup-guide) show_off_vm_backup_guide ;;
    restore-rehearsal-guide) show_restore_rehearsal_guide ;;
    restore-rehearsal-status) show_restore_rehearsal_status ;;
    restore-rehearsal-record) record_restore_rehearsal ;;
    restore-rehearsal-report) show_restore_rehearsal_report ;;
    go-live-record) record_go_live_validation ;;
    go-live-status) show_go_live_status ;;
    cloud-firewall-checklist) show_cloud_firewall_checklist ;;
    cloudflare-checklist) show_cloudflare_checklist ;;
    production-checklist) show_production_checklist ;;
    release-readiness) show_release_readiness ;;
    command-audit) show_command_audit ;;
    release-notes-guide) show_release_notes_guide ;;
    final-qa|final-qa-wizard) final_qa_wizard ;;
    backup-hardening-wizard|backup-wizard) backup_hardening_wizard ;;
    backup-schedule-plan|scheduled-backups) show_backup_schedule_plan ;;
    configure-backup-schedule) configure_backup_schedule ;;
    backup-schedule-status|scheduled-backup-status) show_backup_schedule_status ;;
    disable-backup-schedule) disable_backup_schedule ;;
    backup-retention-plan) show_backup_retention_plan ;;
    backup-retention-status) show_backup_retention_status ;;
    cleanup-old-backups|backup-cleanup) cleanup_old_backups prompt ;;
    cleanup-old-backups-dry-run|backup-cleanup-dry-run) cleanup_old_backups dry-run ;;
    off-vm-backup-plan) show_off_vm_backup_plan ;;
    off-vm-backup-guided-setup) off_vm_backup_guided_setup ;;
    generate-off-vm-backup-key|off-vm-backup-keygen) generate_off_vm_backup_key ;;
    backup-server-setup|prepare-backup-server|off-vm-backup-server-setup) backup_server_setup ;;
    configure-rsync-backup-target) configure_rsync_backup_target ;;
    off-vm-backup-dry-run) run_off_vm_backup_rsync dry-run ;;
    run-off-vm-backup) run_off_vm_backup_rsync run ;;
    off-vm-backup-status) show_off_vm_backup_status ;;
    disable-off-vm-backup) disable_off_vm_backup ;;
    off-vm-backup-wizard) off_vm_backup_wizard ;;
    health-check|health-check-run-now) run_health_check ;;
    configure-health-check-timer) configure_health_check_timer ;;
    health-check-status) show_health_check_status ;;
    health-check-journal) show_health_check_journal ;;
    disable-health-check-timer) disable_health_check_timer ;;
    health-monitoring-wizard|production-monitoring-wizard) health_monitoring_wizard ;;
    service-recovery-plan) show_service_recovery_plan ;;
    restore-preflight) show_restore_preflight ;;
    restore-rehearsal-wizard) restore_rehearsal_wizard ;;
    restore-key-setup) generate_restore_backup_key ;;
    pull-off-vm-backup) pull_off_vm_backup_to_restore_vm ;;
    backup-server-add-restore-key) backup_server_add_restore_key ;;
    backup-server-remove-restore-key) backup_server_remove_restore_key ;;
    backup-server-list-restore-keys) backup_server_list_restore_keys ;;
    production-ops-wizard|production-ops-dashboard|operations-wizard|operations-dashboard|ops-wizard|ops-dashboard) production_ops_wizard ;;
    list-backups|backups) list_site_backups ;;
    restore-db) restore_site_database ;;
    restore-full) restore_site_full ;;
    maintenance) run_maintenance_menu ;;
    migrate) maintenance_migrate ;;
    build) maintenance_build ;;
    clear-cache) maintenance_clear_cache ;;
    restart) maintenance_restart ;;
    wait-ready) wait_for_erpnext_ready ;;
    foreground-start) run_foreground_start ;;
    enable-autostart) enable_autostart_service ;;
    disable-autostart) disable_autostart_service ;;
    service-start) start_erpnext_service ;;
    service-stop) stop_erpnext_service ;;
    service-restart) restart_erpnext_service ;;
    service-status) show_erpnext_service_status ;;
    logs) show_erpnext_service_logs ;;
    logs-follow) follow_erpnext_service_logs ;;
    kvm-guide|local-fixed-ip-guide|fixed-ip-guide|kvm-fixed-ip-guide) show_kvm_fixed_ip_guide ;;
    kvm-identify) show_kvm_vm_identification_guide ;;
    network-status) show_network_status ;;
    local-domain-status) show_local_domain_status ;;
    local-host-checkpoint|host-dns-checkpoint|host-mapping-checkpoint) show_local_host_mapping_checkpoint ;;
    local-access-doctor) local_access_doctor ;;
    hosts-command|print-hosts-command|host-dns-guide) show_host_hosts_command ;;
    host-test) show_host_access_test_guide ;;
    ssl-roadmap) show_ssl_roadmap_guide ;;
    ssl-status) show_ssl_status ;;
    local-ssl-guide) show_local_ssl_guide ;;
    mkcert-guide|trusted-local-ssl-guide) show_mkcert_local_ssl_guide ;;
    trusted-mkcert-setup|mkcert-setup) run_trusted_mkcert_setup ;;
    browser-trust-guide|trust-check-guide) show_browser_trust_check_guide ;;
    ssl-rollback-guide) show_ssl_rollback_guide ;;
    verify-ssl-rollback) verify_ssl_rollback ;;
    verify-local-ssl) verify_local_ssl ;;
    install-local-ssl-cert|replace-local-ssl-cert) install_local_ssl_cert ;;
    create-self-signed-local-cert|self-signed-local-cert) create_self_signed_local_cert ;;
    configure-local-ssl) configure_local_ssl ;;
    disable-local-ssl) disable_local_ssl ;;
    environment-check|where-am-i) show_environment_check ;;
    site-config) show_site_config ;;
    storage-status) show_storage_status ;;
    storage-debug) storage_debug ;;
    expand-root-storage) expand_root_storage ;;
    verify-storage) verify_storage ;;
    domain-config) show_domain_config ;;
    change-local-domain|local-domain-wizard|rename-local-site|change-site-domain) change_local_domain_wizard ;;
    production-readiness) show_production_readiness ;;
    production-plan|prod-plan) show_production_plan ;;
    production-domain-plan|prod-domain-plan) show_production_domain_plan ;;
    public-vm-readiness|public-readiness) show_public_vm_readiness ;;
    production-ssl-plan|prod-ssl-plan) show_production_ssl_plan ;;
    production-firewall-plan|prod-firewall-plan) show_production_firewall_plan ;;
    firewall-hardening-status|firewall-status|hardening-status) show_firewall_hardening_status ;;
    vm-firewall-plan|ufw-plan) vm_firewall_plan ;;
    security-mode-status) security_mode_status ;;
    configure-vm-firewall) configure_vm_firewall ;;
    local-firewall-profile|local-security-profile) configure_local_vm_firewall ;;
    production-firewall-profile|production-security-profile) configure_production_vm_firewall ;;
    repair-local-access) repair_local_access ;;
    firewall-rollback-snapshots) show_firewall_rollback_snapshots ;;
    vm-firewall-status|ufw-status) show_vm_firewall_status ;;
    configure-fail2ban) configure_fail2ban ;;
    fail2ban-status) show_fail2ban_status ;;
    security-hardening-wizard|vm-firewall-wizard) security_hardening_wizard ;;
    ufw-ssh-admin-only) configure_ufw_ssh_admin_only ;;
    production-ssl-menu|production-https|production-https-menu) show_production_ssl_menu ;;
    production-ssl-wizard|ssl-provider-wizard) production_ssl_wizard ;;
    configure-production-ssl) configure_production_ssl ;;
    configure-cloudflare-origin-ssl|install-cloudflare-origin-cert|switch-to-cloudflare-origin-ssl) configure_cloudflare_origin_ssl ;;
    cloudflare-origin-ssl-status) show_cloudflare_origin_ssl_status ;;
    cloudflare-origin-guide) show_cloudflare_origin_guide ;;
    production-ssl-status) show_production_ssl_status ;;
    ssl-mode-status) show_ssl_mode_status ;;
    ssl-mode-guide|ssl-compatibility) show_ssl_mode_guide ;;
    setup-effort-guide|setup-step-count) show_setup_effort_guide ;;
    setup-lifecycle-plan|setup-order-plan) show_setup_lifecycle_plan ;;
    disable-production-ssl) disable_production_ssl ;;
    production-domain-guide) show_production_domain_guide ;;
    production-ssl-guide) show_production_ssl_guide ;;
    repair-site-config) repair_site_config ;;
    site-name-guide|custom-site-guide) show_site_name_guide ;;
    multi-env-guide) show_multi_environment_guide ;;
    help|-h|--help) show_help ;;
    *) fail "Unknown action: ${ACTION}" ;;
  esac
}

main "$@"
