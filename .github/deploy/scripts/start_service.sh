#!/bin/bash
set -euo pipefail

echo "Restarting udev to pick up new rules"
udevadm control --reload-rules
udevadm trigger

echo "Restarting set-hostname-imds service"
systemctl restart set-hostname-imds.service || true
