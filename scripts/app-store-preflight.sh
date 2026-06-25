#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Solea.xcodeproj"
SCHEME="Solea"
CONFIGURATION="Release"
SKIP_ICON_CHECK=0
TEMP_ROOT="${TMPDIR:-/tmp}"
TEMP_ROOT="${TEMP_ROOT%/}"
TEMP_PATHS=()

cleanup() {
  local status=$?
  local path
  for path in "${TEMP_PATHS[@]:-}"; do
    case "$path" in
      "$TEMP_ROOT"/solea-app-store-preflight.*|"$TEMP_ROOT"/solea-app-store-preflight-derived-data.*|"$TEMP_ROOT"/solea-app-store-preflight-home.*|"$TEMP_ROOT"/solea-app-store-preflight-packages.*)
        rm -rf "$path"
        ;;
    esac
  done
  exit "$status"
}
trap cleanup EXIT

for arg in "$@"; do
  case "$arg" in
    --skip-icon-check)
      SKIP_ICON_CHECK=1
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: scripts/app-store-preflight.sh [--skip-icon-check]

Runs local App Store submission checks: Xcode SDK, generated project,
privacy manifests, app icon, Release device build, and bundle metadata.

The default mode is strict and requires AppIcon to be present. Use
--skip-icon-check only while the final icon is still being prepared.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

fail() {
  echo "error: $*" >&2
  exit 1
}

step() {
  echo "==> $*"
}

run_xcodebuild() {
  HOME="$xcode_home_path" \
    CFFIXED_USER_HOME="$xcode_home_path" \
    XDG_CACHE_HOME="$xcode_home_path/.cache" \
    CLANG_MODULE_CACHE_PATH="$xcode_home_path/.cache/clang/ModuleCache" \
    SWIFTPM_MODULECACHE_PATH="$xcode_home_path/.cache/clang/ModuleCache" \
    xcodebuild "$@"
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required tool: $1"
}

require_available_space() {
  local path="$1"
  local required_kb="$2"
  local available_kb
  available_kb="$(df -Pk "$path" | awk 'NR == 2 { print $4 }')"
  [[ -n "$available_kb" ]] || fail "Could not determine available disk space for $path"
  if (( available_kb < required_kb )); then
    fail "At least $((required_kb / 1024)) MiB free disk space required for preflight; found $((available_kb / 1024)) MiB"
  fi
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

check_app_bundle_metadata() {
  local app_path="$1"
  [[ -d "$app_path" ]] || fail "Built app not found at $app_path"

  expect_plist_value "$app_path/Info.plist" CFBundleIdentifier com.davidecapurro.Solea
  expect_plist_value "$app_path/Info.plist" CFBundleShortVersionString 1.0.0
  expect_plist_value "$app_path/Info.plist" CFBundleVersion 1
  expect_plist_value "$app_path/Info.plist" ITSAppUsesNonExemptEncryption false
  expect_plist_value "$app_path/Info.plist" UIDeviceFamily.0 1

  local sdk_name
  sdk_name="$(raw_plist_value "$app_path/Info.plist" DTSDKName)"
  [[ "$sdk_name" == iphoneos26* ]] || fail "Expected iOS 26 SDK build, found DTSDKName=$sdk_name"

  [[ -f "$app_path/PrivacyInfo.xcprivacy" ]] || fail "Missing app PrivacyInfo.xcprivacy in built bundle"
  [[ -d "$app_path/PlugIns/SoleaWidgets.appex" ]] || fail "Missing embedded widget extension"
  [[ -f "$app_path/PlugIns/SoleaWidgets.appex/PrivacyInfo.xcprivacy" ]] || fail "Missing widget PrivacyInfo.xcprivacy in built bundle"
  [[ -d "$app_path/Watch/SoleaWatch.app" ]] || fail "Missing embedded Watch app"
  [[ -f "$app_path/Watch/SoleaWatch.app/PrivacyInfo.xcprivacy" ]] || fail "Missing Watch PrivacyInfo.xcprivacy in built bundle"

  expect_plist_value "$app_path/PlugIns/SoleaWidgets.appex/Info.plist" CFBundleIdentifier com.davidecapurro.Solea.Widgets
  expect_plist_value "$app_path/Watch/SoleaWatch.app/Info.plist" CFBundleIdentifier com.davidecapurro.Solea.watchkitapp
  expect_plist_value "$app_path/Watch/SoleaWatch.app/Info.plist" WKCompanionAppBundleIdentifier com.davidecapurro.Solea

  local widget_sdk_name
  widget_sdk_name="$(raw_plist_value "$app_path/PlugIns/SoleaWidgets.appex/Info.plist" DTSDKName)"
  [[ "$widget_sdk_name" == iphoneos26* ]] || fail "Expected iOS 26 SDK widget build, found DTSDKName=$widget_sdk_name"

  local watch_sdk_name
  watch_sdk_name="$(raw_plist_value "$app_path/Watch/SoleaWatch.app/Info.plist" DTSDKName)"
  [[ "$watch_sdk_name" == watchos26* ]] || fail "Expected watchOS 26 SDK build, found DTSDKName=$watch_sdk_name"
}

cd "$ROOT_DIR"

step "Checking tools"
require_tool xcodebuild
require_tool xcodegen
require_tool ruby
require_tool python3
require_tool plutil
require_tool rg
require_tool sips
[[ -x /usr/libexec/PlistBuddy ]] || fail "Missing required tool: /usr/libexec/PlistBuddy"

xcode_version="$(xcodebuild -version | awk '/^Xcode / { version=$2 } END { print version }')"
xcode_major="${xcode_version%%.*}"
[[ -n "$xcode_major" && "$xcode_major" -ge 26 ]] || fail "Xcode 26+ required, found Xcode ${xcode_version:-unknown}"
require_available_space "$ROOT_DIR" 2097152

step "Validating project spec and generated files"
ruby -ryaml -e 'YAML.load_file("project.yml")' >/dev/null
xcodegen generate >/dev/null

plutil -lint \
  App/Info.plist \
  Widgets/Info.plist \
  WatchApp/Info.plist \
  App/Solea.entitlements \
  Widgets/SoleaWidgets.entitlements \
  WatchApp/SoleaWatch.entitlements \
  App/PrivacyInfo.xcprivacy \
  Widgets/PrivacyInfo.xcprivacy \
  WatchApp/PrivacyInfo.xcprivacy \
  AppStore/ExportOptions-AppStoreConnect.plist >/dev/null

python3 - <<'PY'
import json
from pathlib import Path

for path in [Path("App/Resources/Localizable.xcstrings")]:
    try:
        json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"{path} is not valid JSON: {error}")
PY

step "Checking App Store export options"
expect_plist_value AppStore/ExportOptions-AppStoreConnect.plist method app-store-connect
expect_plist_value AppStore/ExportOptions-AppStoreConnect.plist destination upload
expect_plist_value AppStore/ExportOptions-AppStoreConnect.plist distributionBundleIdentifier com.davidecapurro.Solea
expect_plist_value AppStore/ExportOptions-AppStoreConnect.plist manageAppVersionAndBuildNumber false
expect_plist_value AppStore/ExportOptions-AppStoreConnect.plist signingStyle automatic
expect_plist_value AppStore/ExportOptions-AppStoreConnect.plist stripSwiftSymbols true
expect_plist_value AppStore/ExportOptions-AppStoreConnect.plist uploadSymbols true

step "Checking privacy manifests"
python3 - <<'PY'
import plistlib
import re
from pathlib import Path

targets = [
    ("app", [Path("App"), Path("Shared")], Path("App/PrivacyInfo.xcprivacy")),
    ("widget", [Path("Widgets"), Path("Shared")], Path("Widgets/PrivacyInfo.xcprivacy")),
    ("watch", [Path("WatchApp")], Path("WatchApp/PrivacyInfo.xcprivacy")),
]

required_reason_patterns = {
    "NSPrivacyAccessedAPICategoryUserDefaults": [
        re.compile(r"\bUserDefaults\b"),
        re.compile(r"@AppStorage\b"),
    ],
    "NSPrivacyAccessedAPICategoryFileTimestamp": [
        re.compile(r"\battributesOfItem\b"),
        re.compile(r"\bcontentModificationDate\b"),
        re.compile(r"\bcreationDate\b"),
        re.compile(r"\bmodificationDate\b"),
        re.compile(r"\bfileModificationDate\b"),
    ],
    "NSPrivacyAccessedAPICategorySystemBootTime": [
        re.compile(r"\bsystemUptime\b"),
        re.compile(r"\bmach_absolute_time\b"),
        re.compile(r"\bclock_gettime\b"),
    ],
    "NSPrivacyAccessedAPICategoryDiskSpace": [
        re.compile(r"\battributesOfFileSystem\b"),
        re.compile(r"\bvolumeAvailableCapacity\b"),
        re.compile(r"\bstatfs\b"),
        re.compile(r"\bstatvfs\b"),
    ],
    "NSPrivacyAccessedAPICategoryActiveKeyboards": [
        re.compile(r"\bactiveInputModes\b"),
    ],
}

def swift_text(paths):
    chunks = []
    for root in paths:
        if not root.exists():
            continue
        for file in root.rglob("*.swift"):
            chunks.append(file.read_text(encoding="utf-8"))
    return "\n".join(chunks)

def manifest_api_types(path):
    with path.open("rb") as handle:
        manifest = plistlib.load(handle)
    if manifest.get("NSPrivacyTracking") is not False:
        raise SystemExit(f"{path} must set NSPrivacyTracking to false")
    if "NSPrivacyCollectedDataTypes" not in manifest:
        raise SystemExit(f"{path} is missing NSPrivacyCollectedDataTypes")
    entries = manifest.get("NSPrivacyAccessedAPITypes", [])
    return {
        entry.get("NSPrivacyAccessedAPIType")
        for entry in entries
        if entry.get("NSPrivacyAccessedAPIType")
    }

for name, source_roots, manifest_path in targets:
    text = swift_text(source_roots)
    declared = manifest_api_types(manifest_path)
    used = {
        api_type
        for api_type, patterns in required_reason_patterns.items()
        if any(pattern.search(text) for pattern in patterns)
    }
    missing = used - declared
    if missing:
        formatted = ", ".join(sorted(missing))
        raise SystemExit(f"{name} privacy manifest is missing required-reason API declarations: {formatted}")
PY

step "Checking capability metadata"
if rg -q 'import WeatherKit' App; then
  expect_plist_value App/Solea.entitlements com.apple.developer.weatherkit true
fi
if rg -q 'import WeatherKit' WatchApp; then
  expect_plist_value WatchApp/SoleaWatch.entitlements com.apple.developer.weatherkit true
fi
if rg -q 'import HealthKit' App; then
  expect_plist_value App/Solea.entitlements com.apple.developer.healthkit true
  expect_plist_value App/Info.plist NSHealthUpdateUsageDescription "Solea salva su Salute il tempo trascorso alla luce del giorno durante le tue sessioni."
  expect_plist_value App/Info.plist NSHealthShareUsageDescription "Solea non legge dati da Salute; il permesso serve solo per la scrittura delle sessioni."
  if rg -q 'dietaryVitaminD' App SoleaCore; then
    fail "Do not write synthesized sun-exposure vitamin D into HealthKit dietaryVitaminD; keep vitamin D as an in-app estimate only"
  fi
  python3 - <<'PY'
import re
from pathlib import Path

source = Path("App/Services/HealthKitService.swift").read_text(encoding="utf-8")
if ".timeInDaylight" not in source:
    raise SystemExit("HealthKitService must write only HKQuantityType(.timeInDaylight) for the current App Store privacy copy")
authorization = re.search(r"requestAuthorization\s*\((.*?)\)", source, flags=re.DOTALL)
if not authorization:
    raise SystemExit("HealthKitService requestAuthorization call not found")
compact = re.sub(r"\s+", "", authorization.group(1))
if "read:[]" not in compact:
    raise SystemExit("HealthKitService must not request HealthKit read access for the current App Store privacy copy")
if "toShare:[daylightType]" not in compact:
    raise SystemExit("HealthKitService must request write access only for daylightType")
PY
fi
[[ "$(raw_plist_value App/Info.plist SoleaPrivacyPolicyURL)" != "" ]] || echo "warning: SoleaPrivacyPolicyURL is empty until the final Privacy Policy URL is published"
[[ "$(raw_plist_value App/Info.plist SoleaSupportURL)" != "" ]] || echo "warning: SoleaSupportURL is empty until the final Support URL is published"
if rg -q 'import GameKit' App; then
  expect_plist_value App/Solea.entitlements com.apple.developer.game-center true
  expect_plist_value App/Info.plist GKGameCenterEnabled true
  scripts/validate-game-center-config.sh >/dev/null
fi
if rg -q 'import ActivityKit' App Widgets Shared; then
  expect_plist_value App/Info.plist NSSupportsLiveActivities true
  expect_plist_value App/Solea.entitlements aps-environment '$(APS_ENVIRONMENT)'
  ruby -ryaml -e '
project = YAML.load_file("project.yml")
configs = project.fetch("targets").fetch("Solea").fetch("settings").fetch("configs")
expected = { "Debug" => "development", "Release" => "production" }
expected.each do |configuration, value|
  actual = configs.dig(configuration, "APS_ENVIRONMENT")
  abort("Solea #{configuration} APS_ENVIRONMENT=#{actual.inspect}, expected #{value}") unless actual == value
end
'
fi
if rg -q 'import CoreLocation' App; then
  [[ -n "$(raw_plist_value App/Info.plist NSLocationWhenInUseUsageDescription)" ]] || fail "App/Info.plist is missing NSLocationWhenInUseUsageDescription"
fi
if rg -q 'import CoreLocation' WatchApp; then
  [[ -n "$(raw_plist_value WatchApp/Info.plist NSLocationWhenInUseUsageDescription)" ]] || fail "WatchApp/Info.plist is missing NSLocationWhenInUseUsageDescription"
fi
if rg -q 'import PhotosUI' App; then
  [[ -n "$(raw_plist_value App/Info.plist NSPhotoLibraryUsageDescription)" ]] || fail "App/Info.plist is missing NSPhotoLibraryUsageDescription"
fi

step "Checking App Store privacy assumptions"
if rg -q 'proxyURL = nil|proxyURL`.*nil' docs/APP_STORE_METADATA.md docs/APP_STORE_CONNECT_ANSWERS.md docs/PRIVACY_POLICY_DRAFT.md; then
  python3 - <<'PY'
import re
from pathlib import Path

source = Path("App/Services/Coach/CoachRouter.swift").read_text(encoding="utf-8")
if not re.search(r"static\s+let\s+proxyURL\s*:\s*URL\?\s*=\s*nil\b", source):
    raise SystemExit("App Store privacy copy says the coach cloud is disabled; keep CoachConfiguration.proxyURL nil or update privacy metadata before submission")
PY
fi

step "Checking Critical Alerts configuration"
if rg -q 'defaultCritical|criticalAlert' App; then
  expect_plist_value App/Solea.entitlements com.apple.developer.usernotifications.critical-alerts true
  echo "warning: Critical Alerts require Apple approval and a provisioning profile that includes com.apple.developer.usernotifications.critical-alerts"
fi

step "Checking submission documents"
scripts/validate-app-store-metadata.sh
scripts/export-app-store-metadata.sh >/dev/null
scripts/validate-app-store-external-fields.sh

step "Checking App Store screenshots"
if [[ "$SKIP_ICON_CHECK" -eq 1 ]]; then
  scripts/validate-app-store-screenshots.sh
else
  scripts/validate-app-store-screenshots.sh --required
fi

step "Checking AppIcon"
if [[ "$SKIP_ICON_CHECK" -eq 1 ]]; then
  echo "warning: skipping AppIcon check"
else
  python3 - <<'PY'
import json
from pathlib import Path

path = Path("App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json")
contents = json.loads(path.read_text())
filenames = [item.get("filename") for item in contents.get("images", []) if item.get("filename")]
if not filenames:
    raise SystemExit("AppIcon Contents.json has no image filename. Run scripts/install-app-icon.sh <1024-png> first.")
for filename in filenames:
    icon = path.parent / filename
    if not icon.exists():
        raise SystemExit(f"AppIcon file is missing: {icon}")
    if icon.suffix.lower() != ".png":
        raise SystemExit(f"AppIcon must be PNG: {icon}")
PY

  while IFS= read -r icon; do
    width="$(sips -g pixelWidth "$icon" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
    height="$(sips -g pixelHeight "$icon" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"
    alpha="$(sips -g hasAlpha "$icon" 2>/dev/null | awk '/hasAlpha/ { print $2 }')"
    [[ "$width" == "1024" && "$height" == "1024" ]] || fail "$icon must be 1024x1024, found ${width}x${height}"
    [[ "$alpha" == "no" ]] || fail "$icon must not contain alpha"
  done < <(python3 - <<'PY'
import json
from pathlib import Path
path = Path("App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json")
contents = json.loads(path.read_text())
for item in contents.get("images", []):
    filename = item.get("filename")
    if filename:
        print(path.parent / filename)
PY
)
fi

step "Building Release for generic iOS device"
derived_data_path="$(mktemp -d "$TEMP_ROOT/solea-app-store-preflight-derived-data.XXXXXX")"
TEMP_PATHS+=("$derived_data_path")
xcode_home_path="$(mktemp -d "$TEMP_ROOT/solea-app-store-preflight-home.XXXXXX")"
TEMP_PATHS+=("$xcode_home_path")
cloned_packages_path="$(mktemp -d "$TEMP_ROOT/solea-app-store-preflight-packages.XXXXXX")"
TEMP_PATHS+=("$cloned_packages_path")
mkdir -p "$xcode_home_path/.cache/clang/ModuleCache" "$xcode_home_path/Library/Caches/org.swift.swiftpm" "$xcode_home_path/Library/Logs"
run_xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_data_path" \
  -clonedSourcePackagesDirPath "$cloned_packages_path" \
  CODE_SIGNING_ALLOWED=NO \
  build >/tmp/solea-app-store-preflight-build.log

step "Checking built bundle metadata"
build_settings="$(run_xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" -destination 'generic/platform=iOS' -derivedDataPath "$derived_data_path" -clonedSourcePackagesDirPath "$cloned_packages_path" -showBuildSettings)"
aps_environment="$(awk -F'= ' '/ APS_ENVIRONMENT =/ { print $2; exit }' <<<"$build_settings")"
[[ "$aps_environment" == "production" ]] || fail "Release APS_ENVIRONMENT must be production, found ${aps_environment:-unset}"
target_build_dir="$(awk -F'= ' '/ TARGET_BUILD_DIR =/ { print $2; exit }' <<<"$build_settings")"
wrapper_name="$(awk -F'= ' '/ WRAPPER_NAME =/ { print $2; exit }' <<<"$build_settings")"
app_path="$target_build_dir/$wrapper_name"
check_app_bundle_metadata "$app_path"

step "Checking unsigned archive packaging"
archive_root="$(mktemp -d "$TEMP_ROOT/solea-app-store-preflight.XXXXXX")"
TEMP_PATHS+=("$archive_root")
archive_path="$archive_root/Solea.xcarchive"
run_xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_data_path" \
  -clonedSourcePackagesDirPath "$cloned_packages_path" \
  -archivePath "$archive_path" \
  CODE_SIGNING_ALLOWED=NO \
  archive >/tmp/solea-app-store-preflight-archive.log

expect_plist_value "$archive_path/Info.plist" ApplicationProperties:CFBundleIdentifier com.davidecapurro.Solea
expect_plist_value "$archive_path/Info.plist" ApplicationProperties:CFBundleShortVersionString 1.0.0
expect_plist_value "$archive_path/Info.plist" ApplicationProperties:CFBundleVersion 1
check_app_bundle_metadata "$archive_path/Products/Applications/Solea.app"

echo "Preflight passed. Signing, provisioning profiles, App Store metadata, and Apple portal capabilities still need to be validated in Xcode/App Store Connect."
