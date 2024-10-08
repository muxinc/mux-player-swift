#!/bin/bash

set -euo pipefail

readonly APPLICATION_PAYLOAD_PATH="${PWD}/Examples/MuxPlayerSwiftExample/MuxPlayerSwiftExample.ipa"
readonly APPLICATION_NAME="MuxPlayerSwiftExample.ipa"

# TODO: Fetch these
export SAUCE_USERNAME=""
export SAUCE_ACCESS_KEY=""

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
