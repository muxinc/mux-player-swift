#!/bin/bash

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)

readonly TOP_DIR=`pwd`
readonly BUILD_DIR="${TOP_DIR}/.build"
readonly DOCUMENTATION_DIR=".build/docs"

readonly SCHEME=MuxPlayerSwift
readonly DOCC_ARCHIVE_NAME="${SCHEME}.doccarchive"
readonly DOCC_ARCHIVE_PATH="${BUILD_DIR}/${DOCC_ARCHIVE_NAME}"

if ! command -v xcbeautify &> /dev/null
then
    echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

set -eu pipefail

rm -rf ${BUILD_DIR}

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Building Documentation Catalog for ${SCHEME}"

mkdir -p $DOCUMENTATION_DIR

xcodebuild docbuild -scheme $SCHEME \
                    -destination 'generic/platform=iOS' \
                    -sdk iphoneos \
                    -derivedDataPath "${DOCUMENTATION_DIR}" \
                    OTHER_DOCC_FLAGS="--transform-for-static-hosting --hosting-base-path mux-player-swift --output-path docs" \
                    | xcbeautify 

echo "▸ Finished building Documentation Archive"

cd $DOCUMENTATION_DIR

echo "▸ Searching for ${DOCC_ARCHIVE_NAME} inside ${DOCUMENTATION_DIR}"
docc_built_archive_path=$(find docs -type d -name "${DOCC_ARCHIVE_NAME}")

if [ -z "${docc_built_archive_path}" ]
then
    echo -e "\033[1;31m ERROR: Failed to locate Documentation Archive \033[0m"
    exit 1
else
    echo "▸ Located documentation archive at ${docc_built_archive_path}"
    cp -r ${docc_built_archive_path} ${BUILD_DIR}
    zip -qry "${DOCC_ARCHIVE_NAME}.zip" "${DOCC_ARCHIVE_NAME}"
fi
