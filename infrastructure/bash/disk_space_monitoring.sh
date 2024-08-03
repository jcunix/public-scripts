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
BODY="Disk space usage has exceeded the threshold of $THRESHOLD%."

# Check disk space
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output;
do
  usage=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
  partition=$(echo $output | awk '{ print $2 }')
  if [ $usage -ge $THRESHOLD ]; then
    echo $BODY | mail -s "$SUBJECT" $EMAIL
  fi
done
