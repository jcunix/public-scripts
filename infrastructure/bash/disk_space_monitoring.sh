#!/bin/bash

# In no event shall the author or copyright holder be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise..
# The software is provided 'as is', without warranty of any kind, express or implied
# This was developed by Jonathan Wilson, 16-JUN-2024
# More scripts available at https://www.jonathancw.com/projects/
#

# Threshold percentage
THRESHOLD=80

# Email settings
EMAIL="admin@example.com"
SUBJECT="Disk Space Alert"
BODY="Disk space usage report:"

# Filesystems to ignore (space-separated list)
IGNORE_FILESYSTEMS="tmpfs cdrom"

# Check if -v variable is set
VERBOSE=false
if [ "$1" = "-v" ]; then
  VERBOSE=true
fi

# Function to check if a filesystem is in the ignore list
is_ignored() {
  local fs=$1
  for ignore in $IGNORE_FILESYSTEMS; do
    if [ "$fs" = "$ignore" ]; then
      return 0
    fi
  done
  return 1
}

# Initialize email body
EMAIL_BODY="Disk space usage report:\n\n"

# Check disk space
df -H | grep -vE '^Filesystem' | while read -r output;
do
  usage=$(echo "$output" | awk '{ print $5}' | cut -d'%' -f1)
  partition=$(echo "$output" | awk '{ print $1 }')

  if is_ignored "$partition"; then
    continue
  fi

  if [ "$usage" -ge "$THRESHOLD" ]; then
    EMAIL_BODY="${EMAIL_BODY}* $partition: $usage% (EXCEEDS THRESHOLD)\n"
  else
    EMAIL_BODY="${EMAIL_BODY}$partition: $usage%\n"
  fi

  if [ "$VERBOSE" = true ]; then
    if [ "$usage" -ge "$THRESHOLD" ]; then
      echo "Would send email to $EMAIL with subject \"$SUBJECT\""
      echo "Current usage of $partition is $usage% (EXCEEDS THRESHOLD)"
    else
      echo "Current usage of $partition is $usage%"
    fi
  fi
done

if [ "$VERBOSE" != true ]; then
  echo -e "$EMAIL_BODY" | mail -s "$SUBJECT" "$EMAIL"
fi
