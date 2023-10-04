#!/bin/bash

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)

readonly TOP_DIR=`pwd`
readonly SCHEME="MuxAVPlayerSDK"

set -euo pipefail

if ! command -v xcbeautify &> /dev/null
then
    echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

echo "▸ Selecting Xcode 15"

sudo xcode-select -s /Applications/Xcode_15.0.app/Contents/Developer

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Test ${SCHEME}"

xcodebuild clean test \
	-scheme $SCHEME \
	-destination 'platform=iOS Simulator,OS=17.0,name=iPhone 15' \
	-sdk iphonesimulator17.0 \
  | xcbeautify