#!/bin/bash

# Save this script to a file, for example, install_node_exporter.sh, 
# make it executable with chmod +x install_node_exporter.sh, 
# and then run it with ./install_node_exporter.sh. 
# This script will perform all the specified tasks step-by-step.
# Minor configuration necessary, including Filename and Version.  Script should work from there.

set -e

LOG_FILE="/var/tmp/node_install_log.txt"
FILENAME="node_exporter-1.8.1.linux-amd64"
VERSION="v1.8.1"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/${VERSION}/${FILENAME}.tar.gz"

# Function to log the output of a command
log_and_run() {
    echo "$@" | tee -a "$LOG_FILE"
    "$@" | tee -a "$LOG_FILE"
}

# Change to /var/tmp/
log_and_run cd /var/tmp/

# Download node_exporter tar.gz file
log_and_run wget "$DOWNLOAD_URL"

# Extract the tar.gz file
log_and_run tar xvf "${FILENAME}.tar.gz"

# Change to the extracted directory
log_and_run cd "$FILENAME"

# Copy node_exporter to /usr/local/bin
log_and_run sudo cp /var/tmp/${FILENAME}/node_exporter /usr/local/bin

# Change to the parent directory
log_and_run cd ..

# Remove the extracted directory
log_and_run rm -Rf "$FILENAME"

# Remove the tar file
log_and_run rm -Rf "$FILENAME".tar.gz

# Create the node_exporter user
log_and_run sudo useradd --no-create-home --shell /bin/false node_exporter

# Change ownership of the node_exporter binary
log_and_run sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create the node_exporter.service file
log_and_run sudo bash -c 'cat <<EOL > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL'

# Reload systemd manager configuration
log_and_run sudo systemctl daemon-reload

# Enable node_exporter service to start on boot
log_and_run sudo systemctl enable node_exporter

# Start node_exporter service
log_and_run sudo systemctl start node_exporter

# Display the status of the node_exporter service
log_and_run sudo systemctl status node_exporter.service
