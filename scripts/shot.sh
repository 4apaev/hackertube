#!/bin/sh
# Launches the app in the simulator on one screen and saves a screenshot.
# Usage: scripts/shot.sh <simulator-id> <screen> <out.png>
# The app must be installed. BUNDLE_ID defaults to the ID in the built app.
set -e
APP=${APP:-build/DerivedData/Build/Products/Debug-appletvsimulator/HackerTube.app}
BUNDLE_ID=${BUNDLE_ID:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")}
xcrun simctl terminate "$1" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$1" "$BUNDLE_ID" -screen "$2" >/dev/null
sleep "${WAIT:-6}"
xcrun simctl io "$1" screenshot --type=png "$3" >/dev/null 2>&1
sips -Z 1600 "$3" >/dev/null
