app := 'Hacker Menu'

run: build
    #!/usr/bin/env bash
    set -eEuo pipefail

    kill_wait() {
        while pgrep "${1}" >/dev/null; do
            killall "${1}"
            sleep 1
        done
    }
    export -f kill_wait

    echo 'Restarting {{app}}...'
    timeout 5 bash -c "kill_wait '{{app}}'" \
        && open 'build/Build/Products/Release/{{app}}.app'

@trace: sign
  xcrun xctrace record \
    --template 'Leaks' \
    --launch \
    -- \
    'build/Build/Products/Release/{{app}}.app'

@sign: build
  codesign -s - -f \
    --entitlements get-task-allow.plist \
    'build/Build/Products/Release/{{app}}.app'

@build:
    xcrun xcodebuild build analyze \
        -project '{{app}}.xcodeproj' \
        -scheme '{{app}}' \
        -arch arm64 \
        -configuration Release \
        -derivedDataPath build \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY='' \
        DEVELOPMENT_TEAM=''

    du -hs 'build/Build/Products/Release/{{app}}.app'

@clean:
  rm -rf build
  xcrun xcodebuild clean
