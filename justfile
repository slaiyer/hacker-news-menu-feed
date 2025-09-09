run: build
    open 'build/Build/Products/Release/Hacker News Menu Feed.app'

build:
    rm -rf build

    xcrun xcodebuild \
        -project 'Hacker News Menu Feed.xcodeproj' \
        -scheme 'Hacker News Menu Feed' \
        -configuration Release \
        -derivedDataPath build \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY='' \
        DEVELOPMENT_TEAM='' \
        -arch arm64
