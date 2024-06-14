#!/bin/bash

LOGFILE="/var/tmp/harden.txt"
USERNAME=""
ALL_OPTIONS=false

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Log function to record script execution steps
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOGFILE
}

# Detect the operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
    log "Operating System: $OS $VERSION"
else
    log "Cannot determine the operating system. Exiting."
    exit 1
fi

# Determine the correct SSH service name
if systemctl list-units --full -all | grep -Fq 'ssh.service'; then
    SSH_SERVICE="ssh"
else
    SSH_SERVICE="sshd"
fi

# Function to display usage information
usage() {
    echo "Usage: $0 [-u username] [-a]"
    exit 1
}

# Parse command-line arguments
while getopts ":u:a" opt; do
    case $opt in
        u)
            USERNAME=$OPTARG
            ;;
        a)
            ALL_OPTIONS=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Function to display the main menu and get the user's choice
main_menu() {
    echo "Please choose an option:"
    echo "1. System Hardening"
    echo "2. Apache Hardening"
    echo "3. Choose Specific Section"
    echo "4. Exit"
    read -p "Enter your choice (1, 2, 3 or 4): " main_choice
    case $main_choice in
        1)
            log "Selected System Hardening"
            system_hardening
            ;;
        2)
            log "Selected Apache Hardening"
            apache_hardening
            ;;
        3)
            log "Selected Specific Section"
            specific_section_menu
            ;;
        4)
            log "Exiting"
            exit 0
            ;;
        *)
            log "Invalid choice, exiting"
            exit 1
            ;;
    esac
}

# Function to display the specific section menu and get the user's choice
specific_section_menu() {
    while true; do
        echo "Please choose a section to harden:"
        echo "1. Update and Upgrade System Packages"
        echo "2. Install Essential Security Packages"
        echo "3. Configure Firewall"
        echo "4. Secure SSH"
        echo "5. Disable Unnecessary Services"
        echo "6. Setup Fail2Ban"
        echo "7. Setup Auditd"
        echo "8. Setup Automatic Updates"
        echo "9. Harden Kernel Parameters"
        echo "10. Secure Apache Configuration"
        echo "11. Disable Unnecessary Apache Modules"
        echo "12. Setup Apache Log Rotation"
        echo "13. Exit"
        read -p "Enter your choice (1-13): " section_choice
        case $section_choice in
            1)
                log "Selected Update and Upgrade System Packages"
                update_and_upgrade
                ;;
            2)
                log "Selected Install Essential Security Packages"
                install_security_packages
                ;;
            3)
                log "Selected Configure Firewall"
                configure_firewall
                ;;
            4)
                log "Selected Secure SSH"
                secure_ssh
                ;;
            5)
                log "Selected Disable Unnecessary Services"
                disable_unnecessary_services
                ;;
            6)
                log "Selected Setup Fail2Ban"
                setup_fail2ban
                ;;
            7)
                log "Selected Setup Auditd"
                setup_auditd
                ;;
            8)
                log "Selected Setup Automatic Updates"
                setup_unattended_upgrades
                ;;
            9)
                log "Selected Harden Kernel Parameters"
                harden_kernel_parameters
                ;;
            10)
                log "Selected Secure Apache Configuration"
                secure_apache_config
                ;;
            11)
                log "Selected Disable Unnecessary Apache Modules"
                disable_unnecessary_apache_modules
                ;;
            12)
                log "Selected Setup Apache Log Rotation"
                setup_apache_log_rotation
                ;;
            13)
                log "Exiting Specific Section Menu"
                break
                ;;
            *)
                log "Invalid choice, please try again"
                ;;
        esac
    done
}

# Function for system hardening
system_hardening() {
    update_and_upgrade
    install_security_packages
    configure_firewall
    secure_ssh
    disable_unnecessary_services
    setup_fail2ban
    setup_auditd
    setup_unattended_upgrades
    harden_kernel_parameters
    log "System hardening completed. Please review the configuration and make any additional changes as needed."
}

# Function for updating and upgrading system packages
update_and_upgrade() {
    if $ALL_OPTIONS || ask_user "Updating and upgrading system packages"; then
        case $OS in
            ubuntu|debian)
                apt-get update && apt-get upgrade -y | tee -a $LOGFILE
                ;;
            rhel|rocky)
                yum update -y | tee -a $LOGFILE
                ;;
            *)
                log "Unsupported OS. Exiting."
                exit 1
                ;;
        esac
    fi
}

# Function to install essential security packages
install_security_packages() {
    if $ALL_OPTIONS || ask_user "Installing essential security packages"; then
        case $OS in
            ubuntu|debian)
                apt-get install -y ufw fail2ban auditd | tee -a $LOGFILE
                ;;
            rhel|rocky)
                yum install -y firewalld fail2ban audit dnf-automatic | tee -a $LOGFILE
                ;;
            *)
                log "Unsupported OS. Exiting."
                exit 1
                ;;
        esac
    fi
}

# Function to configure the firewall
configure_firewall() {
    if $ALL_OPTIONS || ask_user "Configuring the firewall"; then
        case $OS in
            ubuntu|debian)
                yes | ufw default deny incoming | tee -a $LOGFILE
                yes | ufw default allow outgoing | tee -a $LOGFILE
                yes | ufw allow ssh | tee -a $LOGFILE
                yes | ufw enable | tee -a $LOGFILE
                ;;
            rhel|rocky)
                systemctl start firewalld | tee -a $LOGFILE
                systemctl enable firewalld | tee -a $LOGFILE
                firewall-cmd --permanent --set-default-zone=drop | tee -a $LOGFILE
                firewall-cmd --permanent --zone=drop --add-service=ssh | tee -a $LOGFILE
                firewall-cmd --reload | tee -a $LOGFILE
                ;;
            *)
                log "Unsupported OS. Exiting."
                exit 1
                ;;
        esac
    fi
}

# Function to add user to sudo or wheel group
add_user_to_sudo() {
    if [ -z "$USERNAME" ]; then
        read -p "Enter the username you want to add to the sudo/wheel group: " USERNAME
    fi
    if id "$USERNAME" &>/dev/null; then
        case $OS in
            ubuntu|debian)
                usermod -aG sudo "$USERNAME"
                log "Added $USERNAME to sudo group."
                ;;
            rhel|rocky)
                usermod -aG wheel "$USERNAME"
                log "Added $USERNAME to wheel group."
                ;;
            *)
                log "Unsupported OS. Exiting."
                exit 1
                ;;
        esac
    else
        log "User $USERNAME does not exist. Exiting."
        exit 1
    fi
}

# Function to secure SSH
secure_ssh() {
    if $ALL_OPTIONS || ask_user "Disabling root login and securing SSH"; then
        add_user_to_sudo
        sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        systemctl restart $SSH_SERVICE | tee -a $LOGFILE
    fi
}

# Function to disable unnecessary services
disable_unnecessary_services() {
    if $ALL_OPTIONS || ask_user "Disabling unnecessary services"; then
        case $OS in
            ubuntu|debian)
                systemctl disable avahi-daemon | tee -a $LOGFILE
                systemctl disable cups | tee -a $LOGFILE
                systemctl disable bluetooth | tee -a $LOGFILE
                ;;
            rhel|rocky)
                systemctl disable avahi-daemon | tee -a $LOGFILE
                systemctl disable cups | tee -a $LOGFILE
                systemctl disable bluetooth | tee -a $LOGFILE
                ;;
            *)
                log "Unsupported OS. Exiting."
                exit 1
                ;;
        esac
    fi
}

# Function to set up Fail2Ban
setup_fail2ban() {
    if $ALL_OPTIONS || ask_user "Setting up fail2ban"; then
        cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
        systemctl enable fail2ban | tee -a $LOGFILE
        systemctl start fail2ban | tee -a $LOGFILE
    fi
}

# Function to set up Auditd
setup_auditd() {
    if $ALL_OPTIONS || ask_user "Setting up auditd"; then
        cat <<EOF > /etc/audit/audit.rules
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
EOF
        systemctl enable auditd | tee -a $LOGFILE
        systemctl start auditd | tee -a $LOGFILE
    fi
}

# Function to set up automatic updates
setup_unattended_upgrades() {
    if $ALL_OPTIONS || ask_user "Setting up automatic updates"; then
        case $OS in
            ubuntu|debian)
                echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
                apt-get install -y unattended-upgrades | tee -a $LOGFILE
                dpkg-reconfigure -f noninteractive unattended-upgrades | tee -a $LOGFILE
                ;;
            rhel|rocky)
                log "Configuring automatic updates with dnf-automatic..."
                cat <<EOF > /etc/dnf/automatic.conf
[commands]
upgrade_type = security
random_sleep = 360

[emitters]
emit_via = motd

[email]
email_from = root@localhost
email_to = root
email_host = localhost

[base]
debuglevel = 1
# skip_broken = True
# mdpolicy = group:main
# assumeyes = True

[main]
enabled = True
EOF
                systemctl enable --now dnf-automatic.timer | tee -a $LOGFILE
                ;;
            *)
                log "Unsupported OS. Exiting."
                exit 1
                ;;
        esac
    fi
}

# Function to harden kernel parameters
harden_kernel_parameters() {
    if $ALL_OPTIONS || ask_user "Hardening kernel parameters"; then
        cat <<EOF > /etc/sysctl.d/99-sysctl.conf
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 1
net.ipv4.conf.default.secure_redirects = 1
EOF

        sysctl -p /etc/sysctl.d/99-sysctl.conf | tee -a $LOGFILE
    fi
}

# Function to perform Apache hardening
apache_hardening() {
    log "Starting Apache hardening process..."
    verify_apache_installed
    secure_apache_config
    disable_unnecessary_apache_modules
    setup_apache_log_rotation
    log "Apache hardening completed. Please review the configuration and make any additional changes as needed."
}

# Function to verify if Apache is installed
verify_apache_installed() {
    if [ "$(which apache2 2>/dev/null)" ] || [ "$(which httpd 2>/dev/null)" ]; then
        log "Apache is installed."
    else
        log "Apache is not installed. Exiting."
        exit 1
    fi
}

# Function to secure Apache configuration
secure_apache_config() {
    if ask_user "Securing Apache configuration"; then
        APACHE_CONF="/etc/apache2/apache2.conf"
        if [ -f "/etc/httpd/conf/httpd.conf" ]; then
            APACHE_CONF="/etc/httpd/conf/httpd.conf"
        fi
        
        cat <<EOF >> $APACHE_CONF
# Disable directory listing
<Directory /var/www/>
    Options -Indexes
</Directory>

# Disable server signature
ServerSignature Off
ServerTokens Prod

# Disable TRACE HTTP method
TraceEnable Off
EOF
        systemctl restart apache2 2>/dev/null || systemctl restart httpd
        log "Apache configuration secured."
    fi
}

# Function to disable unnecessary Apache modules
disable_unnecessary_apache_modules() {
    if ask_user "Disabling unnecessary Apache modules"; then
        a2dismod autoindex 2>/dev/null || echo "autoindex module not found" | tee -a $LOGFILE
        a2dismod status 2>/dev/null || echo "status module not found" | tee -a $LOGFILE
        systemctl restart apache2 2>/dev/null || systemctl restart httpd
        log "Unnecessary Apache modules disabled."
    fi
}

# Function to set up Apache log rotation
setup_apache_log_rotation() {
    if ask_user "Setting up Apache log rotation"; then
        LOGROTATE_CONF="/etc/logrotate.d/apache2"
        if [ -f "/etc/logrotate.d/httpd" ]; then
            LOGROTATE_CONF="/etc/logrotate.d/httpd"
        fi
        
        cat <<EOF > $LOGROTATE_CONF
/var/log/apache2/*.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        /etc/init.d/apache2 reload > /dev/null
    endscript
}
EOF
        log "Apache log rotation setup completed."
    fi
}

# Function to prompt the user for choices for each hardening task
ask_user() {
    log "Please choose an option for $1:"
    echo "1. Enable"
    echo "2. Leave alone"
    read -p "Enter your choice (1 or 2): " choice
    case $choice in
        1)
            log "Enabled $1"
            return 0
            ;;
        2)
            log "Left $1 alone"
            return 1
            ;;
        *)
            log "Invalid choice, leaving $1 alone"
            return 1
            ;;
    esac
}

# Start the main script
log "Starting hardening script..."

# Display the main menu and proceed based on the user's choice
if $ALL_OPTIONS; then
    log "All options enabled for system hardening."
    system_hardening
else
    main_menu
fi

# End the script
log "Script execution completed. Please check the log file at $LOGFILE for details."
