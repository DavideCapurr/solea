#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -ne 1 ]]; then
  cat <<'USAGE'
Usage: scripts/validate-signed-archive.sh <path-to-signed-xcarchive>

Validates the final signed archive before upload to App Store Connect. This
checks bundle metadata, codesigning, embedded targets, and distribution
entitlements that cannot be proven by the unsigned local preflight.
USAGE
  [[ $# -eq 1 ]] || exit 2
  exit 0
fi

ARCHIVE_PATH="$1"
APP_PATH="$ARCHIVE_PATH/Products/Applications/Solea.app"
WIDGET_PATH="$APP_PATH/PlugIns/SoleaWidgets.appex"
WATCH_PATH="$APP_PATH/Watch/SoleaWatch.app"
TMP_DIRS=()

cleanup() {
  local status=$?
  local path
  for path in "${TMP_DIRS[@]:-}"; do
    case "$path" in
      "${TMPDIR:-/tmp}"/solea-signed-archive.*)
        rm -rf "$path"
        ;;
    esac
  done
  exit "$status"
}
trap cleanup EXIT

fail() {
  echo "error: $*" >&2
  exit 1
}

step() {
  echo "==> $*"
}

raw_plist_value() {
  local plist="$1"
  local key="$2"
  local value
  if value="$(plutil -extract "$key" raw -o - "$plist" 2>/dev/null)"; then
    echo "$value"
    return
  fi
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true
}

expect_plist_value() {
  local plist="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(raw_plist_value "$plist" "$key")"
  [[ "$actual" == "$expected" ]] || fail "$plist has $key=$actual, expected $expected"
}

entitlements_plist() {
  local bundle="$1"
  local output="$2"
  codesign -d --entitlements :- "$bundle" >"$output" 2>/dev/null \
    || fail "Could not read entitlements from signed bundle: $bundle"
  plutil -lint "$output" >/dev/null
}

expect_entitlement_value() {
  local entitlements="$1"
  local key="$2"
  local expected="$3"
  expect_plist_value "$entitlements" "$key" "$expected"
}

expect_entitlement_array_contains() {
  local entitlements="$1"
  local key="$2"
  local expected="$3"
  /usr/libexec/PlistBuddy -c "Print :$key" "$entitlements" 2>/dev/null \
    | grep -Fq "$expected" \
    || fail "$entitlements has $key without required value $expected"
}

[[ -d "$ARCHIVE_PATH" ]] || fail "Archive not found: $ARCHIVE_PATH"
[[ -d "$APP_PATH" ]] || fail "App not found in archive: $APP_PATH"
[[ -d "$WIDGET_PATH" ]] || fail "Widget extension missing from archive: $WIDGET_PATH"
[[ -d "$WATCH_PATH" ]] || fail "Watch app missing from archive: $WATCH_PATH"
[[ -x /usr/libexec/PlistBuddy ]] || fail "Missing required tool: /usr/libexec/PlistBuddy"

step "Checking archive metadata"
expect_plist_value "$ARCHIVE_PATH/Info.plist" ApplicationProperties:CFBundleIdentifier com.davidecapurro.Solea
expect_plist_value "$ARCHIVE_PATH/Info.plist" ApplicationProperties:CFBundleShortVersionString 1.0.0
expect_plist_value "$ARCHIVE_PATH/Info.plist" ApplicationProperties:CFBundleVersion 1

step "Checking bundle metadata"
expect_plist_value "$APP_PATH/Info.plist" CFBundleIdentifier com.davidecapurro.Solea
expect_plist_value "$APP_PATH/Info.plist" CFBundleShortVersionString 1.0.0
expect_plist_value "$APP_PATH/Info.plist" CFBundleVersion 1
expect_plist_value "$APP_PATH/Info.plist" ITSAppUsesNonExemptEncryption false
expect_plist_value "$APP_PATH/Info.plist" UIDeviceFamily.0 1
expect_plist_value "$WIDGET_PATH/Info.plist" CFBundleIdentifier com.davidecapurro.Solea.Widgets
expect_plist_value "$WATCH_PATH/Info.plist" CFBundleIdentifier com.davidecapurro.Solea.watchkitapp
expect_plist_value "$WATCH_PATH/Info.plist" WKCompanionAppBundleIdentifier com.davidecapurro.Solea

app_sdk="$(raw_plist_value "$APP_PATH/Info.plist" DTSDKName)"
widget_sdk="$(raw_plist_value "$WIDGET_PATH/Info.plist" DTSDKName)"
watch_sdk="$(raw_plist_value "$WATCH_PATH/Info.plist" DTSDKName)"
[[ "$app_sdk" == iphoneos26* ]] || fail "Expected iOS 26 app SDK, found $app_sdk"
[[ "$widget_sdk" == iphoneos26* ]] || fail "Expected iOS 26 widget SDK, found $widget_sdk"
[[ "$watch_sdk" == watchos26* ]] || fail "Expected watchOS 26 SDK, found $watch_sdk"

[[ -f "$APP_PATH/PrivacyInfo.xcprivacy" ]] || fail "Missing app PrivacyInfo.xcprivacy"
[[ -f "$WIDGET_PATH/PrivacyInfo.xcprivacy" ]] || fail "Missing widget PrivacyInfo.xcprivacy"
[[ -f "$WATCH_PATH/PrivacyInfo.xcprivacy" ]] || fail "Missing Watch PrivacyInfo.xcprivacy"

step "Checking code signatures"
codesign --verify --deep --strict --verbose=2 "$APP_PATH" >/dev/null \
  || fail "codesign verification failed for $APP_PATH"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/solea-signed-archive.XXXXXX")"
TMP_DIRS+=("$tmp_dir")
app_entitlements="$tmp_dir/app.entitlements"
widget_entitlements="$tmp_dir/widget.entitlements"
watch_entitlements="$tmp_dir/watch.entitlements"

entitlements_plist "$APP_PATH" "$app_entitlements"
entitlements_plist "$WIDGET_PATH" "$widget_entitlements"
entitlements_plist "$WATCH_PATH" "$watch_entitlements"

step "Checking signed app entitlements"
expect_entitlement_value "$app_entitlements" aps-environment production
expect_entitlement_value "$app_entitlements" com.apple.developer.weatherkit true
expect_entitlement_value "$app_entitlements" com.apple.developer.healthkit true
expect_entitlement_value "$app_entitlements" com.apple.developer.game-center true
expect_entitlement_array_contains "$app_entitlements" com.apple.security.application-groups group.com.davidecapurro.solea

step "Checking signed widget entitlements"
expect_entitlement_array_contains "$widget_entitlements" com.apple.security.application-groups group.com.davidecapurro.solea

step "Checking signed Watch entitlements"
expect_entitlement_value "$watch_entitlements" com.apple.developer.weatherkit true

echo "Signed archive validation passed. You can validate/upload this archive with Xcode Organizer or xcodebuild -exportArchive."
