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
check submodules/AuthorizationUI/Sources/AuthorizationSequenceSplashController.swift 'ENTER THE GRIT · DAY'
check build-system/grit-configuration.json '"bundle_id": "org.grit.telegram"'
check build-system/grit-configuration.json '"app_specific_url_scheme": "grit"'
check build-system/Make/Make.py 'bazel_command_line.disable_provisioning_profiles = True'
check build-system/Make/Make.py "os.getenv('GRIT_DISABLE_EXTENSIONS') == '1'"
check .github/workflows/device-ipa.yml 'GRIT_DISABLE_EXTENSIONS:'
check .github/workflows/device-ipa.yml 'Telegram.mobileprovision'
check .github/workflows/signed-build.yml 'GRIT_P12_BASE64'
check .github/workflows/grit-build.yml 'GRIT-TG-simulator.ipa'
check .github/workflows/grit-build.yml 'find -L bazel-bin'
check submodules/TelegramUIPreferences/Sources/PresentationThemeSettings.swift 'theme: .builtin(.night)'
check submodules/SettingsUI/Sources/Themes/ThemeColorPresets.swift 'GRIT ACID (night)'
check submodules/SettingsUI/Sources/Themes/ThemeSettingsAppIconItem.swift 'name = "GRIT ACID"'
check Telegram/BUILD '"GRIT",'
check Telegram/BUILD '"GRITVOID",'
[ -f Telegram/Telegram-iOS/GRIT.alticon/GRITIcon@3x.png ] || fail 'missing GRIT alternate icon'
check submodules/TelegramPresentationData/Sources/DefaultDarkPresentationTheme.swift 'GRIT FILTH'
check submodules/AuthorizationUI/Sources/AuthorizationSequenceSplashController.swift 'GRIT THUMP'
check submodules/SettingsUI/Sources/Themes/ThemeColorPresets.swift 'GRIT VOID (night)'
check submodules/SettingsUI/Sources/Themes/ThemeSettingsAppIconItem.swift 'name = "GRIT VOID"'
[ -f Telegram/Telegram-iOS/GRITVOID.alticon/GRITVOIDIcon@3x.png ] || fail 'missing GRIT VOID alternate icon'
check submodules/TelegramPresentationData/Sources/MakePresentationTheme.swift 'gritShouldAnimateBubbles'
check submodules/TelegramPresentationData/Sources/GritProgress.swift 'GRIT.streak'
check submodules/AuthorizationUI/Sources/AuthorizationSequenceSplashController.swift 'ENTER THE GRIT · DAY'
check submodules/AuthorizationUI/Sources/AuthorizationSequenceSplashController.swift 'GRIT GLITCH'
check submodules/TelegramUI/Sources/ServiceSoundManager.swift 'grit_send.mp3'
check submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift 'GRIT SECRET'
check submodules/TelegramUI/Sources/ChatControllerNode.swift 'gritScanlinePatternImage'
[ -f submodules/TelegramUI/Sounds/grit_send.mp3 ] || fail 'missing GRIT send sound'
[ -f submodules/TelegramUI/Sounds/grit_notify.mp3 ] || fail 'missing GRIT notify sound'

python3 -c 'import json; json.load(open("Telegram/Telegram-iOS/Telegram.icon/icon.json")); json.load(open("build-system/grit-configuration.json"))' \
    || fail 'invalid JSON in mod assets'

echo "GRIT verify: OK"
