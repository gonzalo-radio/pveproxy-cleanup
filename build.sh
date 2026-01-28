#!/bin/sh
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BINARY_NAME="pveproxy-cleanup"
DIST_DIR="dist"
VERSION="${VERSION:-1.0.0}"

printf '%bchecking prerequisites...%b\n' "${GREEN}" "${NC}"

# Check if go is installed
if ! command -v go >/dev/null 2>&1; then
    printf '%berror: go is not installed%b\n' "${RED}" "${NC}" >&2
    exit 1
fi

# Check if required files exist
if [ ! -f "main.go" ]; then
    printf '%berror: main.go not found%b\n' "${RED}" "${NC}" >&2
    exit 1
fi

if [ ! -f "pveproxy-cleanup.service" ]; then
    printf '%berror: pveproxy-cleanup.service not found%b\n' "${RED}" "${NC}" >&2
    exit 1
fi

if [ ! -f "pveproxy-cleanup.timer" ]; then
    printf '%berror: pveproxy-cleanup.timer not found%b\n' "${RED}" "${NC}" >&2
    exit 1
fi

printf '%bcleaning previous builds...%b\n' "${GREEN}" "${NC}"
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

printf '%bbuilding %s...%b\n' "${GREEN}" "${BINARY_NAME}" "${NC}"
go build -o "${DIST_DIR}/${BINARY_NAME}" main.go

printf '%bgenerating sha256sum...%b\n' "${GREEN}" "${NC}"
(cd "${DIST_DIR}" && sha256sum "${BINARY_NAME}" > "${BINARY_NAME}.sha256")

printf '%bcopying systemd files...%b\n' "${GREEN}" "${NC}"
cp pveproxy-cleanup.service "${DIST_DIR}/"
cp pveproxy-cleanup.timer "${DIST_DIR}/"
cp install.sh "${DIST_DIR}/"

printf '%bcreating distribution tarball...%b\n' "${GREEN}" "${NC}"
tar -czf "${BINARY_NAME}-${VERSION}.tar.gz" -C "${DIST_DIR}" .

printf '%bbuild complete!%b\n\n' "${GREEN}" "${NC}"
printf "distribution files:\n"
printf "  %s/%s\n" "${DIST_DIR}" "${BINARY_NAME}"
printf "  %s/%s.sha256\n" "${DIST_DIR}" "${BINARY_NAME}"
printf "  %s/pveproxy-cleanup.service\n" "${DIST_DIR}"
printf "  %s/pveproxy-cleanup.timer\n" "${DIST_DIR}"
printf "  %s/install.sh\n" "${DIST_DIR}"
printf "  %s-%s.tar.gz\n" "${BINARY_NAME}" "${VERSION}"
printf '\n%bto install on target system:%b\n' "${YELLOW}" "${NC}"
printf "  1. copy %s-%s.tar.gz to target system\n" "${BINARY_NAME}" "${VERSION}"
printf "  2. extract: tar -xzf %s-%s.tar.gz\n" "${BINARY_NAME}" "${VERSION}"
printf "  3. run: sudo ./install.sh\n"
