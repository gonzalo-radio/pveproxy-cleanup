#!/bin/sh
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BINARY_NAME="pveproxy-cleanup"

printf '%bchecking prerequisites...%b\n' "${GREEN}" "${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    printf '%berror: this script must be run as root%b\n' "${RED}" "${NC}" >&2
    exit 1
fi

# Check if binary exists
if [ ! -f "${BINARY_NAME}" ]; then
    printf '%berror: %s binary not found%b\n' "${RED}" "${BINARY_NAME}" "${NC}" >&2
    printf '%bhint: extract the tarball first or run build.sh%b\n' "${YELLOW}" "${NC}" >&2
    exit 1
fi

# Check if systemd files exist
if [ ! -f "pveproxy-cleanup.service" ]; then
    printf '%berror: pveproxy-cleanup.service not found%b\n' "${RED}" "${NC}" >&2
    exit 1
fi

if [ ! -f "pveproxy-cleanup.timer" ]; then
    printf '%berror: pveproxy-cleanup.timer not found%b\n' "${RED}" "${NC}" >&2
    exit 1
fi

printf '%binstalling binary to /usr/local/bin...%b\n' "${GREEN}" "${NC}"
install -m 755 "${BINARY_NAME}" /usr/local/bin/"${BINARY_NAME}"

printf '%binstalling systemd service and timer...%b\n' "${GREEN}" "${NC}"
install -m 644 pveproxy-cleanup.service /etc/systemd/system/pveproxy-cleanup.service
install -m 644 pveproxy-cleanup.timer /etc/systemd/system/pveproxy-cleanup.timer

printf '%breloading systemd daemon...%b\n' "${GREEN}" "${NC}"
systemctl daemon-reload

printf '%benabling and starting timer...%b\n' "${GREEN}" "${NC}"
systemctl enable pveproxy-cleanup.timer
systemctl start pveproxy-cleanup.timer

printf '%binstallation complete!%b\n\n' "${GREEN}" "${NC}"
printf "status: "
systemctl status pveproxy-cleanup.timer --no-pager | head -n 3

printf '\n%buseful commands:%b\n' "${YELLOW}" "${NC}"
printf "  systemctl status pveproxy-cleanup.timer  - check timer status\n"
printf "  systemctl status pveproxy-cleanup        - check service status\n"
printf "  journalctl -u pveproxy-cleanup           - view logs\n"
printf "  systemctl stop pveproxy-cleanup.timer    - stop timer\n"
printf "  systemctl disable pveproxy-cleanup.timer - disable timer\n"
