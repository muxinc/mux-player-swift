#!/bin/bash

set -euo pipefail

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
readonly EXAMPLE_APPLICATION_ARCHIVE_NAME=MuxPlayerSwiftExample
readonly EXAMPLE_APPLICATION_ARCHIVE_PATH="${PWD}/Examples/MuxPlayerSwiftExample/.build/${EXAMPLE_APPLICATION_ARCHIVE_NAME}.xcarchive"
readonly EXAMPLE_APPLICATION_EXPORT_PATH="${PWD}/Examples/MuxPlayerSwiftExample"
readonly EXPORT_OPTIONS_PLIST_NAME="ExportOptions"
readonly EXPORT_OPTIONS_PLIST_PATH="${EXAMPLE_APPLICATION_EXPORT_PATH}/${EXPORT_OPTIONS_PLIST_NAME}.plist"

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


echo "▸ Available Schemes: $(xcodebuild -list -project MuxPlayerSwiftExample.xcodeproj)"

echo "▸ Creating example application archive"

xcodebuild clean archive -project MuxPlayerSwiftExample.xcodeproj \
		  		 	     -scheme $SCHEME \
		  		 	     -destination generic/platform=iOS \
				         -archivePath $EXAMPLE_APPLICATION_ARCHIVE_PATH \
				         -allowProvisioningUpdates \
				         CODE_SIGNING_REQUIRED=YES | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully created archive at ${EXAMPLE_APPLICATION_ARCHIVE_PATH}"
else
    echo -e "\033[1;31m ERROR: Failed to create archive at ${EXAMPLE_APPLICATION_ARCHIVE_PATH} \033[0m"
    exit 1
fi

echo "▸ Creating export options plist"

rm -rf "${EXPORT_OPTIONS_PLIST_PATH}"

plutil -create xml1 "${EXPORT_OPTIONS_PLIST_PATH}"

/usr/libexec/PlistBuddy -c "Add method string debugging" "${EXPORT_OPTIONS_PLIST_PATH}"

/usr/libexec/PlistBuddy -c "Add teamID string XX95P4Y787" "${EXPORT_OPTIONS_PLIST_PATH}"

/usr/libexec/PlistBuddy -c "Add thinning string <none>" "${EXPORT_OPTIONS_PLIST_PATH}"

/usr/libexec/PlistBuddy -c "Add compileBitcode bool false" "${EXPORT_OPTIONS_PLIST_PATH}"

echo "▸ Created export options plist: $(cat $EXPORT_OPTIONS_PLIST_PATH)"

echo "▸ Exporting example application archive to ${EXAMPLE_APPLICATION_EXPORT_PATH}"

# If exportArchive is failing and rvm is installed locally then run: rvm use system
# Xcode 15 ipatool requires system ruby to export an archive.
# To confirm this: run xcodebuild with -verbose flag and check IDEDistribution 
# distribution logs (.xcdistributionlogs) to see if there is a sqlite installation error.

xcodebuild -exportArchive \
		   -archivePath $EXAMPLE_APPLICATION_ARCHIVE_PATH \
		   -exportPath $EXAMPLE_APPLICATION_EXPORT_PATH \
		   -exportOptionsPlist $EXPORT_OPTIONS_PLIST_PATH | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully exported archive at ${EXAMPLE_APPLICATION_EXPORT_PATH}"
else
    echo -e "\033[1;31m ERROR: Failed to export archive to ${EXAMPLE_APPLICATION_EXPORT_PATH} \033[0m"
    exit 1
fi

echo "▸ Creating example application test runner archive"

xcodebuild build-for-testing  -project MuxPlayerSwiftExample.xcodeproj \
							  -scheme MuxPlayerSwiftExample \
							  -destination generic/platform=iOS \
							  -derivedDataPath $PWD/Build | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully created test runner archive."
else
    echo -e "\033[1;31m ERROR: Failed to create test runner archive. \033[0m"
    exit 1
fi

mkdir -p $PWD/Payload

cp -r "$(find $PWD/Build -name 'MuxPlayerSwiftExampleUITests-Runner.app')" $PWD/Payload

zip -ry MuxPlayerSwiftExampleUITests-Runner.ipa Payload

ls -la



