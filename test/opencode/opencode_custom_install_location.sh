#!/bin/bash

# Test for opencode_custom_install_location scenario
# This tests that opencode is installed to a custom location

set -e

source dev-container-features-test-lib

# Check that opencode is installed in the custom location
check "opencode binary exists in custom location" test -f /opt/bin/opencode
check "opencode binary is executable" test -x /opt/bin/opencode
check "opencode is in PATH" which opencode

# Verify the binary is actually the one from the custom location
check "which points to custom location" test "$(which opencode)" = "/opt/bin/opencode"

# Check that opencode works
check "opencode version command works" opencode --version

# Check configuration file exists (should be in default location regardless of install path)
check "config directory exists" test -d ~/.opencode
check "config file exists" test -f ~/.opencode/config.json
check "config file is valid JSON" jq '.' ~/.opencode/config.json > /dev/null

# Check that default config values are applied
check "config has default autoupdate" test "$(jq -r '.autoupdate' ~/.opencode/config.json)" = "true"
check "config has default share" test "$(jq -r '.share' ~/.opencode/config.json)" = "disabled"
check "config has default leader key" test "$(jq -r '.keybinds.leader' ~/.opencode/config.json)" = "ctrl+x"

reportResults
