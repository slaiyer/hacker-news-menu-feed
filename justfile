run: build
    @-killall 'Hacker News Menu Feed' && sleep 1
    open 'build/Build/Products/Release/Hacker News Menu Feed.app'

build:
    @xcrun xcodebuild clean build analyze \
        -project 'Hacker News Menu Feed.xcodeproj' \
        -scheme 'Hacker News Menu Feed' \
        -configuration Release \
        -derivedDataPath build \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY='' \
        DEVELOPMENT_TEAM='' \
        -arch arm64

    @du -hs 'build/Build/Products/Release/Hacker News Menu Feed.app'
