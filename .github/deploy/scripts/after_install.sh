#!/bin/bash
set -euo pipefail

echo "Installing new RPM package"
rpm -Uvh /tmp/deploy/*.rpm
