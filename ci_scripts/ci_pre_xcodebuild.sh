#!/bin/bash
#
# Xcode Cloud: runs after ci_post_clone.sh (which generates the .xcodeproj) and
# before xcodebuild. Materialises the gitignored Config/Secrets.xcconfig from the
# PROD_API_SECRET_KEY environment secret so Production builds carry the API secret.
# The "Check required build settings" phase (project.yml) fails the build if the
# value is still empty, instead of the app crashing at its first request.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -n "${PROD_API_SECRET_KEY:-}" ]; then
  printf '// Written by ci_scripts/ci_pre_xcodebuild.sh — not committed.\nAPI_SECRET_KEY = %s\n' "$PROD_API_SECRET_KEY" > Config/Secrets.xcconfig
  echo "Config/Secrets.xcconfig written from PROD_API_SECRET_KEY."
else
  echo "warning: PROD_API_SECRET_KEY is not set; Production builds will fail the required-settings check."
fi
