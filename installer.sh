#!/bin/bash

# Spectra Panel Automated Installer
# Professional Edition
# (C) 2026 Spectra Cloud

set -e

# --- Configuration ---
INSTALL_DIR="/opt/spectra-panel"
BIN_URL="https://github.com/NOTAPSXD/Spectra-Panel/raw/main/spectra.bin"
SERVICE_NAME="spectra-panel"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ____                      _                ____                  _ "
echo " / ___| _ __   ___  ___| |_ _ __ __ _  |  _ \ __ _ _ __   ___| |"
echo " \___ \| '_ \ / _ \/ __| __| '__/ _\` | | |_) / _\` | '_ \ / _ \ |"
echo "  ___) | |_) |  __/ (__| |_| | | (_| | |  __/ (_| | | | |  __/ |"
echo " |____/| .__/ \___|\___|\__|_|  \__,_| |_|   \__,_|_| |_|\___|_|"
echo "       |_|                                                       "
echo -e "${NC}"
echo -e "${BLUE}Professional Infrastructure Orchestrator${NC}\n"

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[!] Please run this script as root.${NC}"
  exit 1
fi

# 1. System Prep
echo -e "${YELLOW}[1/6] Preparing system environment...${NC}"
apt-get update -qq
apt-get install -y -qq curl wget snapd ufw python3 > /dev/null

# 2. Virtualization Layer
echo -e "${YELLOW}[2/6] Initializing LXD Hypervisor...${NC}"
if ! command -v lxd &>/dev/null; then
    snap install lxd
    lxd init --auto
fi

# 3. Deployment
echo -e "${YELLOW}[3/6] Downloading Spectra Engine...${NC}"
mkdir -p $INSTALL_DIR
wget -q $BIN_URL -O $INSTALL_DIR/spectra.bin
chmod +x $INSTALL_DIR/spectra.bin

# 4. First-Run Configuration
echo -e "${YELLOW}[4/6] Configuring instance...${NC}"
if [ ! -f "$INSTALL_DIR/.env" ]; then
    SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
    echo "SECRET_KEY=$SECRET_KEY" > $INSTALL_DIR/.env
    echo "SERVER_PORT=3000" >> $INSTALL_DIR/.env
fi

# 5. User Creation
echo -e "${CYAN}[5/6] Creating Administrator Account${NC}"
cd $INSTALL_DIR
./spectra.bin --create-admin

# 6. Service Management
echo -e "${YELLOW}[6/6] Establishing system persistence...${NC}"
cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Spectra Panel Core
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/spectra.bin
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

echo -e "\n${GREEN}################################################"
echo -e "#        INSTALLATION SUCCESSFUL               #"
echo -e "################################################${NC}"
echo -e "Panel is now running on port 3000."
echo -e "Visit: ${CYAN}http://$(curl -s https://ifconfig.me):3000${NC} to activate."
echo -e "------------------------------------------------\n"
