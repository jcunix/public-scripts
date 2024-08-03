#!/bin/bash

# In no event shall the author or copyright holder be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise..
# The software is provided 'as is', without warranty of any kind, express or implied
# This was developed by Jonathan Wilson, 03-AUG-2024
# More scripts available at https://www.jonathancw.com/projects/
#

# Email settings
EMAIL="admin@example.com"
SUBJECT="System Health Check Report"
EMAIL_BODY=""

# Check if -v variable is set
VERBOSE=false
if [ "$1" = "-v" ]; then
  VERBOSE=true
fi

# Function to append output to email body and optionally print to screen
append_to_body() {
  local output="$1"
  EMAIL_BODY="${EMAIL_BODY}${output}\n"
  if [ "$VERBOSE" = true ]; then
    printf "%s\n" "$output"
  fi
}

# Run system health checks
append_to_body "Running system health checks..."

# Check uptime
UPTIME_OUTPUT=$(uptime -p)
append_to_body "Uptime: $UPTIME_OUTPUT"

# Check disk space
append_to_body "Disk Space Usage:"
DISK_SPACE_OUTPUT=$(df -h)
append_to_body "$DISK_SPACE_OUTPUT"

# Check memory usage
append_to_body "Memory Usage:"
MEMORY_USAGE_OUTPUT=$(free -m)
append_to_body "$MEMORY_USAGE_OUTPUT"

# Check load average
append_to_body "Load Average:"
LOAD_AVERAGE_OUTPUT=$(uptime)
append_to_body "$LOAD_AVERAGE_OUTPUT"

# Check top 5 memory-consuming processes
append_to_body "Top 5 Memory-consuming processes:"
TOP_PROCESSES_OUTPUT=$(ps aux --sort=-%mem | head -n 6)
append_to_body "$TOP_PROCESSES_OUTPUT"

# Check for pending reboot
REBOOT_PENDING=false
if [ -f /var/run/reboot-required ]; then
  REBOOT_PENDING=true
  append_to_body "Reboot is pending."
else
  append_to_body "No reboot is pending."
fi

append_to_body "System health checks completed."

# Send email if not in verbose mode
if [ "$VERBOSE" != true ]; then
  printf "%b" "$EMAIL_BODY" | mail -s "$SUBJECT" "$EMAIL"
fi
