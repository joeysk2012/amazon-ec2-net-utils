#!/bin/bash
set -euo pipefail

echo "Restarting udev to pick up new rules"
udevadm control --reload-rules
udevadm trigger

echo "Restarting set-hostname-imds service"
systemctl restart set-hostname-imds.service || true

# Publish the deployed version on the ALB health/landing page (httpd is
# installed by the launch template user data; skip quietly if it isn't).
if [ -d /var/www/html ]; then
  echo "$(rpm -q amazon-ec2-net-utils) on $(. /etc/os-release && echo "${PRETTY_NAME}") $(uname -m)" \
    > /var/www/html/index.html
fi
