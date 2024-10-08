#!/bin/bash

set -euo pipefail

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
readonly BUILD_DIR=$PWD/.build
readonly EXAMPLE_APPLICATION_ARCHIVE_NAME=MuxPlayerSwiftExample

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

cd Examples/MuxPlayerSwiftExample

rm -Rf $BUILD_DIR

echo "▸ Available Schemes: $(xcodebuild -list -project FrameworkProject/MuxStatsGoogleIMAPlugin/MuxStatsGoogleIMAPlugin.xcodeproj)"

echo "▸ Creating build directory at ${BUILD_DIR}"

mkdir -p $BUILD_DIR

echo "▸ Creating example application archive"

xcodebuild clean archive -project MuxPlayerSwiftExample.xcodeproj \
		  		 	     -scheme $SCHEME \
		  		 	     -destination generic/platform=iOS \
				         -archivePath "$BUILD_DIR/${EXAMPLE_APPLICATION_ARCHIVE_NAME}.archive" | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${EXAMPLE_APPLICATION_ARCHIVE_NAME} archive at ${BUILD_DIR}"
else
    echo -e "\033[1;31m ERROR: Failed to create ${EXAMPLE_APPLICATION_ARCHIVE_NAME} archive \033[0m"
    exit 1
fi

echo "▸ Creating export options plist"

plutil -create xml1 ExportOptions.plist

/usr/libexec/PlistBuddy -c "Add method string ad-hoc" ExportOptions.plist 

/usr/libexec/PlistBuddy -c "Add teamID string XX95P4Y787" ExportOptions.plist

echo "▸ Created export options plist: $(cat ExportOptions.plist)"

echo "▸ Exporting example application archive"

xcodebuild -exportArchive \
		   -archivePath "$BUILD_DIR/${EXAMPLE_APPLICATION_ARCHIVE_NAME}.archive" \
		   -exportPath "$PWD" \
		   -exportOptionsPlist "$PWD/ExportOptions.plist"

