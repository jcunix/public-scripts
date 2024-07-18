#!/bin/bash

# This script installs common and necessary Linux applications for system administration.
# It includes Vim and Nano syntax highlighting for all users.
# The script detects the OS and installs applicable packages for RHEL 8 and 9, Rocky Linux 8 and 9, Arch Linux, and Ubuntu 22.04 and 24.04.
# Results of the script execution are logged to /var/tmp/install_admin_tools.log.
# Common admin tools I install on linux systems to assist with administration
# Infrastructure Bash Script - JW 4.12.24

LOG_FILE="/var/tmp/install_admin_tools.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "Starting system administration tools installation..."

# Define common packages for installation
COMMON_PACKAGES="htop wget curl git net-tools lsof"
DEBIAN_PACKAGES="software-properties-common"
RHEL_PACKAGES="epel-release"
ARCH_PACKAGES=""

# Function to install packages on Debian-based systems (Ubuntu)
install_debian_packages() {
    echo "Updating package list..."
    apt update

    echo "Installing common packages..."
    apt install -y $COMMON_PACKAGES $DEBIAN_PACKAGES vim nano

    echo "Installing syntax highlighting for Vim and Nano..."
    apt install -y vim-nox vim-scripts
    echo "syntax on" >> /etc/vim/vimrc
    echo "include \"/usr/share/nano/*.nanorc\"" >> /etc/nanorc
}

# Function to install packages on RHEL-based systems (RHEL, Rocky)
install_rhel_packages() {
    echo "Updating package list..."
    yum update -y

    echo "Installing EPEL repository..."
    yum install -y $RHEL_PACKAGES

    echo "Installing common packages..."
    yum install -y $COMMON_PACKAGES vim-enhanced nano

    echo "Installing syntax highlighting for Vim and Nano..."
    echo "syntax on" >> /etc/vimrc
    echo "include \"/usr/share/nano/*.nanorc\"" >> /etc/nanorc
}

# Function to install packages on Arch Linux
install_arch_packages() {
    echo "Updating package list..."
    pacman -Syu --noconfirm

    echo "Installing common packages..."
    pacman -S --noconfirm $COMMON_PACKAGES vim nano

    echo "Installing syntax highlighting for Vim and Nano..."
    pacman -S --noconfirm vim-syntastic nano-syntax-highlighting
    echo "syntax on" >> /etc/vimrc
    echo "include \"/usr/share/nano/*.nanorc\"" >> /etc/nanorc
}

# Detect OS and version
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID

    case $OS in
        ubuntu)
            echo "Detected OS: Ubuntu $VERSION"
            case $VERSION in
                22.04|24.04)
                    echo "Applying package installation for Ubuntu $VERSION..."
                    install_debian_packages
                    ;;
                *)
                    echo "Unsupported Ubuntu version. Exiting."
                    exit 1
                    ;;
            esac
            ;;
        rhel|rocky)
            echo "Detected OS: $PRETTY_NAME"
            case $VERSION in
                8|9)
                    echo "Applying package installation for $PRETTY_NAME..."
                    install_rhel_packages
                    ;;
                *)
                    echo "Unsupported RHEL/Rocky Linux version. Exiting."
                    exit 1
                    ;;
            esac
            ;;
        arch)
            echo "Detected OS: Arch Linux"
            echo "Applying package installation for Arch Linux..."
            install_arch_packages
            ;;
        *)
            echo "Unsupported OS. Exiting."
            exit 1
            ;;
    esac
else
    echo "Unable to detect OS. Exiting."
    exit 1
fi

echo "System administration tools installation completed successfully."
