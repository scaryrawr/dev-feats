#!/bin/sh
set -e

# Store before sourcing os-release
BUN_VERSION="$VERSION"

. /etc/os-release
apt_get_update() {
  case "${ID}" in
  debian | ubuntu)
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
      echo "Running apt-get update..."
      apt-get update -y
    fi
    ;;
  fedora | rhel)
    dnf update -y
    ;;
  esac
}

# Checks if packages are installed and installs them if not
check_packages() {
  case "${ID}" in
  debian | ubuntu)
    if ! dpkg -s "$@" >/dev/null 2>&1; then
      apt_get_update
      apt-get -y install --no-install-recommends "$@"
    fi
    ;;
  alpine)
    if ! apk -e info "$@" >/dev/null 2>&1; then
      apk add --no-cache "$@"
    fi
    ;;
  fedora | rhel)
    dnf install -y --setopt=install_weak_deps=False "$@"
    ;;
  esac
}

export DEBIAN_FRONTEND=noninteractive

check_packages curl ca-certificates unzip bash

if [ -z "$BUN_VERSION" ]; then
  curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash
else
  # Strip leading 'v' if present
  BUN_VERSION=$(echo "$BUN_VERSION" | sed 's/^v//')

  # Validate version format (basic semver: x.y.z with optional prerelease/build metadata)
  if ! echo "$BUN_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'; then
    echo "Error: Invalid version format '$BUN_VERSION'. Expected format: x.y.z (e.g., 1.3.0)" >&2
    exit 1
  fi

  curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash -s "bun-v$BUN_VERSION"
fi
