#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'opencode' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "opencode": {}
#    },
#    "remoteUser": "root"
# }
#
# Thus, the value of all options will fall back to the default value in 
# the Feature's 'devcontainer-feature.json'.
# For the 'opencode' feature, that means the default installation location is OpenCode's default (~/.opencode/bin).
#
# These scripts are run as 'root' by default. Although that can be changed
# with the '--remote-user' flag.
# 
# This test can be run with the following command:
#
#    devcontainer features test \ 
#                   --features opencode   \
#                   --remote-user root \
#                   --skip-scenarios   \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   /path/to/this/repo

set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]

check "opencode binary exists" test -f ~/.opencode/bin/opencode
check "opencode binary is executable" test -x ~/.opencode/bin/opencode
check "opencode is in PATH" which opencode
check "opencode version command works" opencode --version
check "config directory exists" test -d ~/.opencode
check "config file exists" test -f ~/.opencode/config.json
check "config file is valid JSON" jq '.' ~/.opencode/config.json > /dev/null

# Test default configuration values
check "config has autoupdate true by default" test "$(jq -r '.autoupdate' ~/.opencode/config.json)" = "true"
check "config has disabled share by default" test "$(jq -r '.share' ~/.opencode/config.json)" = "disabled"
check "config has default leader key" test "$(jq -r '.keybinds.leader' ~/.opencode/config.json)" = "ctrl+x"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
