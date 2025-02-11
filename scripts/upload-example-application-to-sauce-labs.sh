#!/bin/bash

set -eo pipefail

if ! command -v saucectl &> /dev/null
then
    echo -e "\033[1;31m ERROR: saucectl could not be found please install it... \033[0m"
    exit 1
fi

if ! command -v jq &> /dev/null
then
    echo -e "\033[1;31m ERROR: jq could not be found please install it... \033[0m"
    exit 1
fi

readonly APPLICATION_NAME="MuxPlayerSwiftExample.ipa"
# TODO: make this an argument
readonly APPLICATION_PAYLOAD_PATH="Examples/MuxPlayerSwiftExample/${APPLICATION_NAME}"

if [ ! -f $APPLICATION_PAYLOAD_PATH ]; then
    echo -e "\033[1;31m ERROR: application archive not found \033[0m"
fi

# re-exported so saucectl CLI can use them
export SAUCE_USERNAME=$BUILDKITE_MAC_STADIUM_SAUCE_USERNAME
export SAUCE_ACCESS_KEY=$BUILDKITE_MAC_STADIUM_SAUCE_ACCESS_KEY

export BUILD_LABEL=$(git rev-parse --short HEAD)

echo "▸ Deploying app and Testing with Sauce"
echo "▸ Sauce Labs config: $(cat $PWD/.sauce/config.yml)"
if [ -z $BUILD_LABEL ]; then
  saucectl run -c "$PWD/.sauce/config.yml" --build "Local build"
else
  saucectl run -c "$PWD/.sauce/config.yml" --build "commit ${BUILD_LABEL}"
fi

if [[ $? == 0 ]]; then
    echo "▸ Successfully deployed Sauce Labs tests"
else
    echo -e "\033[1;31m ERROR: Failed to deploy Sauce Labs tests \033[0m"
    exit 1
fi
