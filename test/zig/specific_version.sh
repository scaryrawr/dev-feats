#!/bin/bash

# This test file will be executed against the 'specific_version' scenario
# that includes the 'zig' feature with version "0.14.1" specified.

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "zig version is 0.14.1" bash -c "zig version | grep '0.14.1'"
check "zls is installed" bash -c "zls --version"
check "zls version matches zig" bash -c "zls --version | grep '0.14.0'"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
