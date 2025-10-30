#!/bin/sh
set -e

# Store before sourcing os-release
ZIG_VERSION="${VERSION:-master}"

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
    dnf install -y --skip-unavailable --setopt=install_weak_deps=False "$@"
    ;;
  esac
}

export DEBIAN_FRONTEND=noninteractive

# Use correct package name for xz based on distribution
case "${ID}" in
fedora | rhel)
  check_packages curl ca-certificates jq tar xz minisign
  ;;
*)
  check_packages curl ca-certificates jq tar xz-utils minisign
  ;;
esac

# Validate version format (basic semver: x.y.z with optional prerelease/build metadata)
if [ "$ZIG_VERSION" != "master" ] && ! echo "$ZIG_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'; then
  echo "Error: Invalid version format '$ZIG_VERSION'. Expected format: x.y.z (e.g., 1.3.0) or 'master'" >&2
  exit 1
fi

# Get index to determine tarball name and public key
index=$(curl -fsSL https://ziglang.org/download/index.json)
tarball_name=$(echo "$index" | jq -r --arg VERSION "$ZIG_VERSION" --arg ARCH "$(uname -m)" '.[$VERSION].[$ARCH + "-linux"].tarball' | sed 's|.*/||')

# Zig Software Foundation public key for minisign verification
ZIG_PUBKEY="RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U"

# Get community mirrors list
mirrors=$(curl -fsSL https://ziglang.org/download/community-mirrors.txt)

# Shuffle mirrors to distribute load
shuffled_mirrors=$(echo "$mirrors" | shuf)

tarball_file=$(mktemp)
minisig_file=$(mktemp)
trap "rm -f '$tarball_file' '$minisig_file'" EXIT

# Try each mirror until successful
download_success=false
for mirror_url in $shuffled_mirrors; do
  echo "Trying mirror: $mirror_url"

  # Download tarball
  if curl -fsSL "${mirror_url}/${tarball_name}?source=dev-feats-zig" -o "$tarball_file"; then
    # Download minisig signature
    if curl -fsSL "${mirror_url}/${tarball_name}.minisig?source=dev-feats-zig" -o "$minisig_file"; then
      # Verify signature
      if minisign -Vm "$tarball_file" -P "$ZIG_PUBKEY" -x "$minisig_file" >/dev/null 2>&1; then
        echo "Successfully downloaded and verified from $mirror_url"
        download_success=true
        break
      else
        echo "Signature verification failed for $mirror_url, trying next mirror..."
      fi
    else
      echo "Failed to download signature from $mirror_url, trying next mirror..."
    fi
  else
    echo "Failed to download tarball from $mirror_url, trying next mirror..."
  fi
done

# Fallback to ziglang.org if all mirrors fail
if [ "$download_success" = false ]; then
  echo "All mirrors failed, trying ziglang.org as fallback..."
  tarball_url=$(echo "$index" | jq -r --arg VERSION "$ZIG_VERSION" --arg ARCH "$(uname -m)" '.[$VERSION].[$ARCH + "-linux"].tarball')

  if curl -fsSL "$tarball_url" -o "$tarball_file"; then
    if curl -fsSL "${tarball_url}.minisig" -o "$minisig_file"; then
      if minisign -Vm "$tarball_file" -P "$ZIG_PUBKEY" -x "$minisig_file" >/dev/null 2>&1; then
        echo "Successfully downloaded and verified from ziglang.org"
        download_success=true
      else
        echo "Error: Signature verification failed" >&2
        exit 1
      fi
    else
      echo "Error: Failed to download signature from ziglang.org" >&2
      exit 1
    fi
  else
    echo "Error: Failed to download tarball from ziglang.org" >&2
    exit 1
  fi
fi

if [ "$download_success" = false ]; then
  echo "Error: Failed to download Zig from any source" >&2
  exit 1
fi

mkdir -p /usr/local/share/zig
tar -xJ -C /usr/local/share/zig --strip-components=1 -f "$tarball_file"
ln -s /usr/local/share/zig/zig /usr/local/bin/zig

# Install ZLS (Zig Language Server)
echo "Installing ZLS..."

# ZLS public key for minisign verification
ZLS_PUBKEY="RWR+9B91GBZ0zOjh6Lr17+zKf5BoSuFvrx2xSeDE57uIYvnKBGmMjOex"

# Determine ZLS version based on Zig version
if [ "$ZIG_VERSION" = "master" ]; then
  echo "Building ZLS from source for master version of Zig..."

  # Clone ZLS repository
  zls_tmp_dir=$(mktemp -d)
  original_dir=$(pwd)
  check_packages git
  git clone --depth 1 https://github.com/zigtools/zls.git "$zls_tmp_dir"

  # Build ZLS
  cd "$zls_tmp_dir"
  zig build -Doptimize=ReleaseSafe

  # Install ZLS
  mkdir -p /usr/local/share/zls
  cp zig-out/bin/zls /usr/local/share/zls/zls
  ln -s /usr/local/share/zls/zls /usr/local/bin/zls

  # Cleanup
  cd "$original_dir"
  rm -rf "$zls_tmp_dir"

  echo "ZLS built and installed from source"
else
  # Extract major.minor version (ZLS uses x.y.0 format)
  zls_version="${ZIG_VERSION%.*}.0"

  echo "Installing ZLS version $zls_version..."

  # Determine architecture for ZLS
  arch=$(uname -m)
  case "$arch" in
  x86_64)
    zls_arch="x86_64"
    ;;
  aarch64)
    zls_arch="aarch64"
    ;;
  armv7l)
    zls_arch="arm"
    ;;
  *)
    echo "Warning: Unsupported architecture $arch for ZLS prebuilt binaries, skipping ZLS installation" >&2
    exit 0
    ;;
  esac

  zls_tarball_name="zls-${zls_arch}-linux.tar.xz"
  zls_tarball_file=$(mktemp)
  zls_minisig_file=$(mktemp)

  # Try to download ZLS release
  zls_url="https://github.com/zigtools/zls/releases/download/${zls_version}/${zls_tarball_name}"
  zls_minisig_url="${zls_url}.minisig"

  if curl -fsSL "$zls_url" -o "$zls_tarball_file"; then
    if curl -fsSL "$zls_minisig_url" -o "$zls_minisig_file"; then
      if minisign -Vm "$zls_tarball_file" -P "$ZLS_PUBKEY" -x "$zls_minisig_file" >/dev/null 2>&1; then
        echo "Successfully downloaded and verified ZLS $zls_version"

        # Extract and install ZLS
        mkdir -p /usr/local/share/zls
        tar -xJ -C /usr/local/share/zls -f "$zls_tarball_file"
        ln -s /usr/local/share/zls/zls /usr/local/bin/zls

        echo "ZLS installed successfully"
      else
        echo "Warning: ZLS signature verification failed, skipping ZLS installation" >&2
      fi
    else
      echo "Warning: Failed to download ZLS signature, skipping ZLS installation" >&2
    fi
  else
    echo "Warning: Failed to download ZLS $zls_version (may not exist for this Zig version), skipping ZLS installation" >&2
  fi

  # Cleanup ZLS temp files
  rm -f "$zls_tarball_file" "$zls_minisig_file"
fi
