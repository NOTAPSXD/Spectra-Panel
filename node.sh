#!/bin/bash
set -e

# --- Configuration ---
NODE_USER="hvmnode"
NODE_HOME="/home/${NODE_USER}"
PANEL_URL=""
SETUP_KEY=""
NODE_NAME=$(hostname)

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --url) PANEL_URL="$2"; shift 2 ;;
    --key) SETUP_KEY="$2"; shift 2 ;;
    --name) NODE_NAME="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo "------------------------------------------------"
echo "   VEXANODE HYPERVISOR AGENT INITIALIZATION"
echo "------------------------------------------------"

echo "[*] Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq

echo "[*] Installing LXD Engine..."
if ! command -v lxd &>/dev/null; then
    apt-get install -y snapd
    snap install lxd
    # Basic LXD initialization
    /snap/bin/lxd init --auto
fi

echo "[*] Initializing system user..."
id -u ${NODE_USER} &>/dev/null || useradd -m -s /bin/bash ${NODE_USER}
usermod -aG lxd ${NODE_USER}

echo "[*] Hardening SSH environment..."
mkdir -p ${NODE_HOME}/.ssh
chmod 700 ${NODE_HOME}/.ssh

echo "[*] Fetching dependencies (tmate, openssh, ufw)..."
apt-get install -y -qq curl wget tmate openssh-server ufw jq

echo "[*] Synchronizing firewall policies..."
ufw allow ssh
ufw allow 2375/tcp
ufw --force enable

echo "[*] Bootstrapping LXD daemon..."
systemctl enable snap.lxd.daemon
systemctl start snap.lxd.daemon

# --- Automated Registration ---
if [[ -n "$PANEL_URL" && -n "$SETUP_KEY" ]]; then
    echo "[*] Orchestrating automated registration with panel..."
    REG_DATA=$(jq -n \
                  --arg sk "$SETUP_KEY" \
                  --arg nm "$NODE_NAME" \
                  --arg us "$NODE_USER" \
                  '{setup_key: $sk, name: $nm, ssh_user: $us}')
    
    RESPONSE=$(curl -s -X POST "${PANEL_URL}/api/node/register" \
         -H "Content-Type: application/json" \
         -d "$REG_DATA")
         
    if echo "$RESPONSE" | grep -q "success"; then
        echo "[+] Node authenticated and registered successfully!"
    else
        echo "[!] Registration failed: $RESPONSE"
    fi
fi

echo "------------------------------------------------"
echo " AGENT INITIALIZATION COMPLETE"
echo " Node Identity: ${NODE_NAME}"
echo " Remote User:   ${NODE_USER}"
echo "------------------------------------------------"
