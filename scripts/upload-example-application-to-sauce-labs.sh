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
if [ -z $BUILDKITE_MAC_STADIUM_SAUCE_USERNAME ]; then
  export SAUCE_USERNAME=$BUILDKITE_MAC_STADIUM_SAUCE_USERNAME
fi
if [ -z $BUILDKITE_MAC_STADIUM_SAUCE_ACCESS_KEY ]; then
  export SAUCE_ACCESS_KEY=$BUILDKITE_MAC_STADIUM_SAUCE_ACCESS_KEY
fi

export BUILD_LABEL=${BUILDKITE_BRANCH}

echo "▸ Deploying app and Testing with Sauce"
echo "▸ Sauce Labs config: $(cat $PWD/.sauce/config.yml)"
if [ -z $BUILDKITE_BUILD ]; then
  saucectl run -c "$PWD/.sauce/config.yml" --build "Local build"
else
  saucectl run -c "$PWD/.sauce/config.yml" --build "build #${BUILD_LABEL}"
fi

if [[ $? == 0 ]]; then
    echo "▸ Successfully deployed Sauce Labs tests"
else
    echo -e "\033[1;31m ERROR: Failed to deploy Sauce Labs tests \033[0m"
    exit 1
fi
