#!/usr/bin/env bash
#
# Bumps the version in pubspec.yaml.
# Usage: bump-version.sh [major|minor|patch]
# Outputs the new version string (MAJOR.MINOR.PATCH+BUILD_NUMBER).
#
set -euo pipefail

BUMP_TYPE="${1:-patch}"
PUBSPEC="pubspec.yaml"

if [ ! -f "$PUBSPEC" ]; then
  echo "Error: $PUBSPEC not found in current directory." >&2
  exit 1
fi

if [[ "$BUMP_TYPE" != "major" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "patch" ]]; then
  echo "Usage: $0 [major|minor|patch]" >&2
  exit 1
fi

# Extract current version line: version: MAJOR.MINOR.PATCH+BUILD
CURRENT_VERSION=$(grep -E '^version:\s+' "$PUBSPEC" | head -1 | sed 's/version:\s*//')

if [ -z "$CURRENT_VERSION" ]; then
  echo "Error: No version found in $PUBSPEC." >&2
  exit 1
fi

# Split into semver and build number
SEMVER="${CURRENT_VERSION%%+*}"
BUILD="${CURRENT_VERSION#*+}"

# If no build number separator was found, default to 0
if [ "$BUILD" = "$SEMVER" ]; then
  BUILD=0
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$SEMVER"

# Validate parsed components are numbers
if ! [[ "$MAJOR" =~ ^[0-9]+$ && "$MINOR" =~ ^[0-9]+$ && "$PATCH" =~ ^[0-9]+$ && "$BUILD" =~ ^[0-9]+$ ]]; then
  echo "Error: Could not parse version '$CURRENT_VERSION'. Expected format MAJOR.MINOR.PATCH+BUILD." >&2
  exit 1
fi

case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

BUILD=$((BUILD + 1))

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}+${BUILD}"

# Replace the version line in pubspec.yaml
sed -i "s/^version:.*$/version: ${NEW_VERSION}/" "$PUBSPEC"

echo "$NEW_VERSION"
