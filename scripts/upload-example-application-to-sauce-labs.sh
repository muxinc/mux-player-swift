#!/bin/bash

set -euo pipefail

if ! command -v saucectl &> /dev/null
then
    echo -e "\033[1;31m ERROR: saucectl could not be found please install it... \033[0m"
    exit 1
fi

readonly APPLICATION_NAME="MuxPlayerSwiftExample.ipa"
# TODO: make this an argument
readonly APPLICATION_PAYLOAD_PATH="Examples/MuxPlayerSwiftExample/${APPLICATION_NAME}"

if [ ! -f $APPLICATION_PAYLOAD_PATH ]; then
    echo -e "\033[1;31m ERROR: application archive not found \033[0m"
fi

# TODO: Fetch these
export SAUCE_USERNAME=""
export SAUCE_ACCESS_KEY=""

echo "▸ Uploading test application to Sauce Labs App Storage"

# This curl command is a dry-run. Remove redirect to localhost after SL credentials are available
# Non-dry-run command
#  curl -u "$SAUCE_USERNAME:$SAUCE_ACCESS_KEY" --location \
# --request POST 'https://api.us-west-1.saucelabs.com/v1/storage/upload' \
# --form "payload=@\"${APPLICATION_PAYLOAD_PATH}\"" \
# --form "name=\"${APPLICATION_NAME}\""

curl --resolve '*:80:127.0.0.1' --resolve '*:443:127.0.0.1' 'https://api.us-west-1.saucelabs.com' \
-u "$SAUCE_USERNAME:$SAUCE_ACCESS_KEY" --location \
--request POST 'https://api.us-west-1.saucelabs.com/v1/storage/upload' \
--form "payload=@\"${APPLICATION_PAYLOAD_PATH}\"" \
--form "name=\"${APPLICATION_NAME}\""

echo "▸ Deploying tests to Sauce Labs"

echo "▸ Sauce Labs config: $(cat $PWD/.sauce/config.yml)"

saucectl run -c "${PWD}/.sauce/config.yml"

if [[ $? == 0 ]]; then
    echo "▸ Successfully deployed Sauce Labs tests"
else
    echo -e "\033[1;31m ERROR: Failed to deploy Sauce Labs tests \033[0m"
    exit 1
fi
