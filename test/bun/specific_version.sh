#!/bin/bash

# This test file will be executed against the 'specific_version' scenario
# that includes the 'bun' feature with version "1.2.23" specified.

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "bun version is 1.2.23" bash -c "bun --version | grep '1.2.23'"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
