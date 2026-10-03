#!/bin/bash
set -euo pipefail

PKG_NAME="amazon-ec2-net-utils"

if ! rpm -q "${PKG_NAME}" >/dev/null 2>&1; then
  echo "ERROR: ${PKG_NAME} is not installed after deployment"
  exit 1
fi
echo "${PKG_NAME} is installed: $(rpm -q "${PKG_NAME}")"

# Identify the primary interface by matching its MAC address against
# the instance's top-level IMDS "mac" field (same method lib.sh uses).
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
PRIMARY_MAC=$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" \
  "http://169.254.169.254/latest/meta-data/mac")

PRIMARY_IFACE=""
for iface in /sys/class/net/*; do
  name=$(basename "${iface}")
  [ "${name}" = "lo" ] && continue
  mac=$(cat "${iface}/address" 2>/dev/null || true)
  if [ "${mac,,}" = "${PRIMARY_MAC,,}" ]; then
    PRIMARY_IFACE="${name}"
    break
  fi
done

if [ -z "${PRIMARY_IFACE}" ]; then
  echo "ERROR: could not determine primary interface via IMDS mac ${PRIMARY_MAC}"
  exit 1
fi
echo "Primary interface identified as ${PRIMARY_IFACE}"

# 1. Primary interface must be up
OPER_STATE=$(cat "/sys/class/net/${PRIMARY_IFACE}/operstate" 2>/dev/null || echo "unknown")
if [ "${OPER_STATE}" != "up" ]; then
  echo "ERROR: primary interface ${PRIMARY_IFACE} is not up (operstate=${OPER_STATE})"
  exit 1
fi
echo "OK: ${PRIMARY_IFACE} is up"

# 2. setup-policy-routes (policy-routes@<iface>.service) must have succeeded
if ! systemctl is-active --quiet "policy-routes@${PRIMARY_IFACE}.service"; then
  echo "ERROR: policy-routes@${PRIMARY_IFACE}.service is not active"
  systemctl status "policy-routes@${PRIMARY_IFACE}.service" --no-pager || true
  exit 1
fi
echo "OK: policy-routes@${PRIMARY_IFACE}.service is active"

# 3. refresh-policy-routes (refresh-policy-routes@<iface>.service via its timer) must be healthy
if ! systemctl is-active --quiet "refresh-policy-routes@${PRIMARY_IFACE}.timer"; then
  echo "ERROR: refresh-policy-routes@${PRIMARY_IFACE}.timer is not active"
  systemctl status "refresh-policy-routes@${PRIMARY_IFACE}.timer" --no-pager || true
  exit 1
fi
echo "OK: refresh-policy-routes@${PRIMARY_IFACE}.timer is active"

echo "Validation passed"
exit 0
