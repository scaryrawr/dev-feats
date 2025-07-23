#!/bin/bash

# Test for opencode_with_options scenario
# This tests that the configuration options are properly applied

set -e

source dev-container-features-test-lib

# Check that opencode is installed and working
check "opencode binary exists" test -f ~/.opencode/bin/opencode
check "opencode binary is executable" test -x ~/.opencode/bin/opencode
check "opencode is in PATH" which opencode

# Check configuration file exists and is valid
check "config directory exists" test -d ~/.opencode
check "config file exists" test -f ~/.opencode/config.json
check "config file is valid JSON" jq '.' ~/.opencode/config.json > /dev/null

# Check specific configuration values from the scenario
check "config has theme mocha" test "$(jq -r '.theme' ~/.opencode/config.json)" = "mocha"
check "config has specified model" test "$(jq -r '.model' ~/.opencode/config.json)" = "anthropic/claude-3-5-sonnet-20241022"
check "config has specified small model" test "$(jq -r '.small_model' ~/.opencode/config.json)" = "anthropic/claude-3-haiku-20240307"
check "config has specified username" test "$(jq -r '.username' ~/.opencode/config.json)" = "testuser"
check "config has autoupdate false" test "$(jq -r '.autoupdate' ~/.opencode/config.json)" = "false"
check "config has share disabled" test "$(jq -r '.share' ~/.opencode/config.json)" = "disabled"
check "config has custom leader key" test "$(jq -r '.keybinds.leader' ~/.opencode/config.json)" = "ctrl+a"

# Display the config for debugging
echo "Configuration file contents:"
cat ~/.opencode/config.json

reportResults
