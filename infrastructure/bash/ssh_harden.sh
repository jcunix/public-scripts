#!/bin/bash

# This script hardens SSH on various Linux distributions following CISA standards.
# It includes steps such as disabling root login, changing the default SSH port,
# enforcing key-based authentication, setting idle session timeouts, and enabling logging.
# Additionally, it modifies the MOTD to display a security warning and information about pending updates and reboot status.
# Supported OS:
# - Ubuntu 20.04, 22.04, 24.04
# - RHEL 8, RHEL 9
# - Rocky Linux 8, 9
# - Arch Linux
#
# Infrastructure Bash Script - JW 4.12.24
# NOTES:
# Update the NEW_SSH_PORT and ALLOWED_USERS variables with appropriate values for your environment.
# Ensure that the new SSH port is not blocked by your firewall and that it's allowed in your security groups if you're using a cloud provider.
# Once enforced, no password authentication will be possibe.  Ensure you have your ssh_key has been added.

# Define variables
SSH_CONFIG="/etc/ssh/sshd_config"
NEW_SSH_PORT=2222  # Change the SSH port from 22 to your preferred port
ALLOWED_USERS="your_username"  # Replace with the username(s) allowed to access SSH
BACKUP_FILE="/etc/ssh/sshd_config.bak"
MOTD_FILE="/etc/motd"
UPDATE_CMD=""
REBOOT_CMD=""

# Backup the original SSH configuration
echo "Backing up SSH configuration to $BACKUP_FILE"
cp $SSH_CONFIG $BACKUP_FILE

# Function to update SSH configuration
update_ssh_config() {
    local key=$1
    local value=$2
    if grep -q "^#*$key" $SSH_CONFIG; then
        sed -i "s|^#*$key.*|$key $value|" $SSH_CONFIG
    else
        echo "$key $value" >> $SSH_CONFIG
    fi
}

# Function to apply general SSH hardening
apply_ssh_hardening() {
    echo "Disabling root login..."
    update_ssh_config "PermitRootLogin" "no"

    echo "Changing SSH port to $NEW_SSH_PORT..."
    update_ssh_config "Port" "$NEW_SSH_PORT"

    echo "Enforcing key-based authentication..."
    update_ssh_config "PasswordAuthentication" "no"
    update_ssh_config "ChallengeResponseAuthentication" "no"
    update_ssh_config "UsePAM" "yes"
    update_ssh_config "PermitEmptyPasswords" "no"

    echo "Restricting SSH access to specific users..."
    update_ssh_config "AllowUsers" "$ALLOWED_USERS"

    echo "Disabling X11 forwarding..."
    update_ssh_config "X11Forwarding" "no"

    echo "Disabling unused authentication methods..."
    update_ssh_config "UseDNS" "no"
    update_ssh_config "GSSAPIAuthentication" "no"

    echo "Enabling strict modes..."
    update_ssh_config "StrictModes" "yes"

    echo "Enabling verbose logging..."
    update_ssh_config "LogLevel" "VERBOSE"

    echo "Setting idle session timeout..."
    update_ssh_config "ClientAliveInterval" "300"
    update_ssh_config "ClientAliveCountMax" "0"

    echo "Limiting authentication attempts..."
    update_ssh_config "MaxAuthTries" "3"
    update_ssh_config "MaxSessions" "2"

    echo "Disabling SSH protocol 1..."
    update_ssh_config "Protocol" "2"

    echo "Enabling rate limiting..."
    update_ssh_config "MaxStartups" "10:30:60"

    echo "Restarting SSH service..."
    if [[ -f /etc/debian_version ]]; then
        systemctl restart ssh
    else
        systemctl restart sshd
    fi

    echo "Updated SSH configuration:"
    grep -E "^(Port|PermitRootLogin|PasswordAuthentication|ChallengeResponseAuthentication|UsePAM|PermitEmptyPasswords|AllowUsers|X11Forwarding|UseDNS|GSSAPIAuthentication|StrictModes|LogLevel|ClientAliveInterval|ClientAliveCountMax|MaxAuthTries|MaxSessions|Protocol|MaxStartups)" $SSH_CONFIG

    echo "SSH hardening completed successfully."
}

# Function to update MOTD
update_motd() {
    local updates_pending=""
    local reboot_required=""

    if [[ -n "$UPDATE_CMD" ]]; then
        updates_pending=$($UPDATE_CMD)
    fi

    if [[ -n "$REBOOT_CMD" ]]; then
        if $REBOOT_CMD; then
            reboot_required="*** A reboot is required to complete the installation of updates. ***"
        fi
    fi

    cat << EOF > $MOTD_FILE
************************************************************
* NOTICE TO USERS                                           *
* This computer system is the private property of the owner.*
* It is for authorized use only. Users (authorized or      *
* unauthorized) have no explicit or implicit expectation   *
* of privacy.                                               *
*                                                          *
* Any or all uses of this system and all files on this     *
* system may be intercepted, monitored, recorded, copied,  *
* audited, inspected, and disclosed to authorized site,    *
* and law enforcement personnel, as well as authorized     *
* officials of other agencies, both domestic and foreign.  *
* By using this system, the user consents to such          *
* interception, monitoring, recording, copying, auditing,  *
* inspection, and disclosure at the discretion of          *
* authorized site or local personnel.                      *
*                                                          *
* Unauthorized or improper use of this system may result   *
* in disciplinary action and civil and criminal penalties. *
* By continuing to use this system you indicate your       *
* awareness of and consent to these terms and conditions   *
* of use. LOG OFF IMMEDIATELY if you do not agree to the   *
* conditions stated in this warning.                       *
************************************************************

$updates_pending
$reboot_required
EOF

    echo "MOTD updated successfully."
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
                20.04|22.04|24.04)
                    echo "Applying SSH hardening for Ubuntu $VERSION..."
                    UPDATE_CMD="apt list --upgradable 2>/dev/null | grep -v 'Listing' | wc -l"
                    REBOOT_CMD="test -f /var/run/reboot-required"
                    apply_ssh_hardening
                    update_motd
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
                    echo "Applying SSH hardening for $PRETTY_NAME..."
                    UPDATE_CMD="yum check-update | grep -v '^Last metadata expiration check:' | wc -l"
                    REBOOT_CMD="needs-restarting -r"
                    apply_ssh_hardening
                    update_motd
                    ;;
                *)
                    echo "Unsupported RHEL/Rocky Linux version. Exiting."
                    exit 1
                    ;;
            esac
            ;;
        arch)
            echo "Detected OS: Arch Linux"
            echo "Applying SSH hardening for Arch Linux..."
            UPDATE_CMD="checkupdates | wc -l"
            REBOOT_CMD="false"  # Arch Linux doesn't typically require reboots after updates
            apply_ssh_hardening
            update_motd
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
