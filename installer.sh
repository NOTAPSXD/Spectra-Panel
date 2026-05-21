#!/bin/bash

# Spectra Panel Professional Installer
# (C) 2026 Spectra Cloud Orchestration
# Designed for Ubuntu 20.04/22.04/24.04

# --- Configuration ---
INSTALL_DIR="/opt/spectra-panel"
BIN_URL="https://github.com/NOTAPSXD/Spectra-Panel/raw/main/spectra-engine.tar.gz"
SERVICE_NAME="spectra-panel"

# --- Colors & Styles ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- UI Functions ---
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ██████  ██████  ███████  ██████ ████████ ██████   █████  "
    echo " ██      ██   ██ ██      ██         ██    ██   ██ ██   ██ "
    echo "  █████  ██████  █████   ██         ██    ██████  ███████ "
    echo "      ██ ██      ██      ██         ██    ██   ██ ██   ██ "
    echo "  ██████  ██      ███████  ██████    ██    ██   ██ ██   ██ "
    echo -e "${NC}"
    echo -e "${BLUE}     Professional Infrastructure Orchestration Engine${NC}"
    echo -e "${CYAN}------------------------------------------------------------${NC}\n"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}${BOLD}[!] ERROR:${NC} This script must be run as root."
        exit 1
    fi
}

# --- Action: Install ---
run_install() {
    print_banner
    echo -e "${BOLD}INITIALIZING INSTALLATION SEQUENCE${NC}\n"

    # 1. System Environment
    echo -ne "${YELLOW}» Preparing system environment...${NC}"
    (apt-get update -qq && apt-get install -y -qq curl wget snapd ufw python3 > /dev/null) &
    spinner $!
    echo -e " ${GREEN}[COMPLETE]${NC}"

    # 2. Virtualization Layer
    echo -ne "${YELLOW}» Synchronizing LXD Hypervisor...${NC}"
    if ! command -v lxd &>/dev/null; then
        (snap install lxd && lxd init --auto) &
        spinner $!
    fi
    echo -e " ${GREEN}[READY]${NC}"

    # 3. Download & Extract
    echo -ne "${YELLOW}» Deploying Spectra Engine Core...${NC}"
    mkdir -p $INSTALL_DIR
    (wget -q $BIN_URL -O /tmp/spectra-engine.tar.gz && \
     tar -xzf /tmp/spectra-engine.tar.gz -C $INSTALL_DIR --strip-components=1 && \
     chmod +x $INSTALL_DIR/spectra.bin) &
    spinner $!
    echo -e " ${GREEN}[DEPLOYED]${NC}"

    # 4. Configuration
    echo -ne "${YELLOW}» Configuring instance parameters...${NC}"
    if [ ! -f "$INSTALL_DIR/.env" ]; then
        SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
        echo "SECRET_KEY=$SECRET_KEY" > $INSTALL_DIR/.env
        echo "SERVER_PORT=3000" >> $INSTALL_DIR/.env
    fi
    echo -e " ${GREEN}[CONFIGURED]${NC}"

    # 5. Admin Creation
    echo -e "\n${MAGENTA}${BOLD}[USER SETUP]${NC} Creating Administrator Identity..."
    echo -e "${CYAN}------------------------------------------------------------${NC}"
    cd $INSTALL_DIR
    LD_LIBRARY_PATH=$INSTALL_DIR ./spectra.bin --create-admin
    echo -e "${CYAN}------------------------------------------------------------${NC}"

    # 6. Persistence
    echo -ne "${YELLOW}» Establishing system persistence...${NC}"
    (cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Spectra Panel Core
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment="LD_LIBRARY_PATH=$INSTALL_DIR"
ExecStart=$INSTALL_DIR/spectra.bin
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl start $SERVICE_NAME) &
    spinner $!
    echo -e " ${GREEN}[ACTIVE]${NC}"

    echo -e "\n${GREEN}${BOLD}SUCCESS:${NC} Spectra Panel has been successfully installed."
    echo -e "Access your dashboard at: ${CYAN}${BOLD}http://$(curl -s https://ifconfig.me):3000${NC}"
    echo -e "------------------------------------------------------------\n"
}

# --- Action: Uninstall ---
run_uninstall() {
    print_banner
    echo -e "${RED}${BOLD}INITIALIZING DECOMMISSIONING SEQUENCE${NC}\n"
    
    read -p "Are you sure you want to remove Spectra Panel? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "\n${YELLOW}Operation cancelled.${NC}"
        exit 0
    fi

    echo -ne "${YELLOW}» Terminating active services...${NC}"
    (systemctl stop $SERVICE_NAME && systemctl disable $SERVICE_NAME && rm /etc/systemd/system/$SERVICE_NAME.service && systemctl daemon-reload) &
    spinner $!
    echo -e " ${GREEN}[STOPPED]${NC}"

    echo -ne "${YELLOW}» Removing engine components...${NC}"
    # We keep the database and .env for safety unless deep purge
    read -p "Would you also like to delete ALL data (Database & Settings)? (y/N): " purge
    if [[ $purge =~ ^[Yy]$ ]]; then
        (rm -rf $INSTALL_DIR) &
        spinner $!
        echo -e " ${GREEN}[PURGED]${NC}"
    else
        (find $INSTALL_DIR -maxdepth 1 ! -name 'spectra_panel.db' ! -name '.env' ! -name '/opt/spectra-panel' -exec rm -rf {} +) &
        spinner $!
        echo -e " ${GREEN}[REMOVED]${NC}"
    fi

    echo -e "\n${GREEN}${BOLD}SUCCESS:${NC} Spectra Panel has been decommissioned."
    echo -e "------------------------------------------------------------\n"
}

# --- Main Entry Point ---
check_root
print_banner

echo -e "${BOLD}Select an action to proceed:${NC}"
echo -e "  ${CYAN}[1]${NC} Install Spectra Panel"
echo -e "  ${CYAN}[2]${NC} Uninstall Spectra Panel"
echo -e "  ${CYAN}[3]${NC} Exit\n"
read -p "Selection: " choice

case $choice in
    1) run_install ;;
    2) run_uninstall ;;
    3) exit 0 ;;
    *) echo -e "${RED}Invalid selection.${NC}"; exit 1 ;;
esac
