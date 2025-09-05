#!/usr/bin/env bash
# Purpose: Deploy apt/Zabbix config from a fixed repo on Debian.
# Output: ONLY colored log lines -> SUCCESS/ERROR | DATE | MESSAGE

set -o pipefail

# -------------------- Fixed configuration --------------------
REPO_URL="https://github.com/pthoelken/apt-zabbix-monitoring.git"   # <-- set your repo URL here
REPO_BRANCH="main"

DEST_ZBX_DIR="/etc/zabbix/zabbix_agent2.d"
DEST_APT_DIR="/etc/apt/apt.conf.d"

SRC_ZBX_REL="zabbix_agentd.d/apt-updates.conf"
SRC_APT_REL="apt.conf.d/02periodic"

# -------------------- Logging --------------------
ts() { date '+%Y-%m-%d %H:%M:%S'; }
ok() { echo -e "\e[32mSUCCESS\e[0m | $(ts) | $*"; }
err(){ echo -e "\e[31mERROR\e[0m   | $(ts) | $*" >&2; }
abort(){ err "$*"; exit 1; }

# -------------------- Pre-checks --------------------
[ "$EUID" -eq 0 ] || abort "Please run as root."
[ -n "$REPO_URL" ] || abort "REPO_URL is empty; set it inside the script."
command -v apt-get >/dev/null 2>&1 || abort "This script requires a Debian/apt-get system."

# Ensure destination directories exist
[ -d "$DEST_ZBX_DIR" ] || abort "Missing destination path: $DEST_ZBX_DIR"
[ -d "$DEST_APT_DIR" ] || abort "Missing destination path: $DEST_APT_DIR"
ok "Destination paths exist."

# -------------------- Ensure git is present --------------------
if ! command -v git >/dev/null 2>&1; then
  ok "git not found – installing silently."
  DEBIAN_FRONTEND=noninteractive apt-get update -qq || abort "apt-get update failed."
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git || abort "Installing git failed."
  ok "git installed."
else
  ok "git is present."
fi

# -------------------- Clone to /tmp --------------------
TMP_DIR="$(mktemp -d -t repo-XXXXXX)" || abort "mktemp failed."
trap 'rm -rf "$TMP_DIR"' EXIT

REPO_DIR="$TMP_DIR/repo"
if git clone --depth=1 --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1; then
  ok "Repository cloned: $REPO_URL (branch: $REPO_BRANCH)"
else
  abort "Cloning repository failed: $REPO_URL (branch: $REPO_BRANCH)"
fi

# -------------------- Validate sources --------------------
SRC_ZBX="$REPO_DIR/$SRC_ZBX_REL"
SRC_APT="$REPO_DIR/$SRC_APT_REL"

[ -f "$SRC_ZBX" ] || abort "Source file missing in repo: $SRC_ZBX_REL"
[ -f "$SRC_APT" ] || abort "Source file missing in repo: $SRC_APT_REL"
ok "Source files found."

# -------------------- Copy files --------------------
# Use 'install' for clean copy and permissions
if install -m 0644 "$SRC_ZBX" "$DEST_ZBX_DIR/apt-updates.conf"; then
  ok "Copied: $SRC_ZBX_REL → $DEST_ZBX_DIR/apt-updates.conf"
else
  abort "Copy failed: $SRC_ZBX_REL → $DEST_ZBX_DIR/apt-updates.conf"
fi

if install -m 0644 "$SRC_APT" "$DEST_APT_DIR/02periodic"; then
  ok "Copied: $SRC_APT_REL → $DEST_APT_DIR/02periodic"
else
  abort "Copy failed: $SRC_APT_REL → $DEST_APT_DIR/02periodic"
fi

# -------------------- Restart Zabbix Agent2 --------------------
if systemctl restart zabbix-agent2.service >/dev/null 2>&1; then
  sleep 1
  if systemctl is-active --quiet zabbix-agent2.service; then
    ok "Zabbix Agent2 restarted successfully."
  else
    abort "Zabbix Agent2 is not active after restart."
  fi
else
  abort "Restarting zabbix-agent2.service failed."
fi

# -------------------- Cleanup (trap removes /tmp) --------------------
ok "Temporary directory removed."
ok "Deployment finished."
