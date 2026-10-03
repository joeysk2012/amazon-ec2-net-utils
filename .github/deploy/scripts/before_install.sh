#!/bin/bash
set -euo pipefail

PKG_NAME="amazon-ec2-net-utils"

if rpm -q "${PKG_NAME}" >/dev/null 2>&1; then
  echo "Removing existing ${PKG_NAME} package"
  rpm -e "${PKG_NAME}"
else
  echo "${PKG_NAME} not currently installed, skipping removal"
fi
