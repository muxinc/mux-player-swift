#!/bin/bash

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "▸ Usage: $0 SCHEME"
    exit 1
fi

readonly SCHEME="$1"

if ! command -v xcbeautify &> /dev/null
then
    echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Resolve Package Dependencies"

xcodebuild -resolvePackageDependencies

echo "▸ Available Schemes"

xcodebuild -list -json

echo "▸ Test ${SCHEME}"

xcodebuild clean test \
	-scheme $SCHEME \
	-destination 'platform=iOS Simulator,OS=18.3,name=iPhone 16' \
	-sdk iphonesimulator18.3 \
  | xcbeautify
