#!/usr/bin/env bash
# Fast sanity check: makes sure the GRIT patches are still present in the tree.
set -euo pipefail

fail() {
    echo "GRIT verify: FAIL - $1" >&2
    exit 1
}

check() {
    local file="$1"
    local needle="$2"
    [ -f "$file" ] || fail "missing file $file"
    grep -Fq "$needle" "$file" || fail "$file does not contain: $needle"
}

check Telegram/BUILD '<string>GRIT TG</string>'
check Telegram/Telegram-iOS/Telegram.icon/icon.json 'display-p3:0.58000,1.00000,0.12000,1.00000'
check submodules/TelegramPresentationData/Sources/DefaultDarkPresentationTheme.swift 'UIColor(rgb: 0x9eff00)'
check submodules/TelegramPresentationData/Sources/MakePresentationTheme.swift 'neutralNightAccentColor = UIColor(rgb: 0x9eff00)'
check submodules/TelegramPresentationData/Sources/DefaultDayPresentationTheme.swift 'defaultDayAccentColor = UIColor(rgb: 0x14a33c)'
check submodules/AuthorizationUI/Sources/AuthorizationSequenceSplashController.swift '"ENTER THE GRIT"'
check build-system/grit-configuration.json '"app_specific_url_scheme": "grit"'

python3 -c 'import json; json.load(open("Telegram/Telegram-iOS/Telegram.icon/icon.json")); json.load(open("build-system/grit-configuration.json"))' \
    || fail 'invalid JSON in mod assets'

echo "GRIT verify: OK"
