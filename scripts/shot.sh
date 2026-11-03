#!/bin/sh
# Launches the app in the simulator on one screen and saves a screenshot.
# Usage: scripts/shot.sh <simulator-id> <screen> <out.png>
set -e
xcrun simctl terminate "$1" dev.michael.HackerTube 2>/dev/null || true
xcrun simctl launch "$1" dev.michael.HackerTube -screen "$2" >/dev/null
sleep "${WAIT:-6}"
xcrun simctl io "$1" screenshot --type=png "$3" >/dev/null 2>&1
sips -Z 1600 "$3" >/dev/null
