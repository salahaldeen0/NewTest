#!/bin/bash
# Exit on error
set -e
# File where the version is stored
VERSION_FILE="version.txt"
# Check if version.txt exists
if [ ! -f "$VERSION_FILE" ]; then
  echo ":x: Error: $VERSION_FILE not found."
  exit 1
fi
# Read current version from version.txt
CURRENT_VERSION=$(cat "$VERSION_FILE")
echo ":package: Current version: $CURRENT_VERSION"
# Function to increment version
increment_version() {
  local version=$1
  local type=$2
  # Split the version into major, minor, patch
  IFS='.' read -r -a version_parts <<< "$version"
  major=${version_parts[0]}
  minor=${version_parts[1]}
  patch=${version_parts[2]}
  # Increment based on the type (major, minor, patch)
  if [ "$type" == "major" ]; then
    ((major++))
    minor=0
    patch=0
  elif [ "$type" == "minor" ]; then
    ((minor++))
    patch=0
  elif [ "$type" == "patch" ]; then
    ((patch++))
  else
    echo ":x: Invalid version bump type: $type. Use 'major', 'minor', or 'patch'."
    exit 1
  fi
  # Return new version
  echo "$major.$minor.$patch"
}
# Function to determine the version bump based on commit messages
determine_version_bump() {
  # Check if tags exist
  LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
  # If no tags exist, fallback to first commit
  if [ -z "$LAST_TAG" ]; then
    echo "no_tags"
    return
  fi
  # Get commit messages since the last tag, skipping hashes
  COMMITS=$(git log $LAST_TAG..HEAD --pretty=format:%s)
  # If there are no new commits, return 'nochange' bump type
  if [ -z "$COMMITS" ]; then
    echo "nochange"
    return
  fi
  # Initialize bump type
  bump_type="patch"
  # Look for breaking changes (major bump)
  if echo "$COMMITS" | grep -q "BREAKING CHANGE"; then
    bump_type="major"
  # Look for feature commits (minor bump)
  elif echo "$COMMITS" | grep -q "^feat"; then
    bump_type="minor"
  # Look for fix commits (patch bump)
  elif echo "$COMMITS" | grep -q "^fix"; then
    bump_type="patch"
  fi
  # Return the bump type
  echo "$bump_type"
}
# Determine the version bump type based on commit messages
BUMP_TYPE=$(determine_version_bump)
echo ":bump type found: $BUMP_TYPE";
# If there are no changes (no new commits), exit the script
if [ "$BUMP_TYPE" == "nochange" ]; then
  echo ":mag: No new commits since last tag. Skipping version bump."
  exit 0
fi
# If no tags exist (first run), start with version 0.1.0 or your preferred base version
if [ "$BUMP_TYPE" == "no_tags" ]; then
  NEW_VERSION="0.0.1"
  echo ":mag: No tags found. Starting version at $NEW_VERSION"
else
  # Bump version based on commit messages
  NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$BUMP_TYPE")
  echo ":arrows_counterclockwise: Bumping version to $NEW_VERSION"
fi
# Update version.txt with the new version
echo "$NEW_VERSION" > "$VERSION_FILE"
# Commit and tag the new version
echo ":bookmark: Committing new version and tagging Git..."
git add "$VERSION_FILE"
git commit -m "chore: bump version to $NEW_VERSION"
git tag "v$NEW_VERSION"
# Push changes and tags to Git
echo ":outbox_tray: Pushing changes and tags to Git..."
git push && git push --tags
echo ":white_check_mark: Release complete! New version: $NEW_VERSION"





