#!/bin/sh
set -e

if [ -z "$VERSION" ]; then
  curl -fsSL https://bun.sh/install | sudo BUN_INSTALL=/usr/local bash
else
  # Strip leading 'v' if present
  VERSION=$(echo "$VERSION" | sed 's/^v//')

  # Validate version format (basic semver: x.y.z with optional prerelease/build metadata)
  if ! echo "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'; then
    echo "Error: Invalid version format '$VERSION'. Expected format: x.y.z (e.g., 1.3.0)" >&2
    exit 1
  fi

  curl -fsSL https://bun.sh/install | sudo BUN_INSTALL=/usr/local bash -s "bun-v$VERSION"
fi
