#! /bin/bash

# TODO - Add this section to the mac mini buildkite env
readonly SAUCE_USERNAME=${BUILDKITE_MAC_STADIUM_SAUCE_USERNAME}
readonly SAUCE_ACCESS_KEY=${BUILDKITE_MAC_STADIUM_SAUCE_ACCESS_KEY}

brew tap saucelabs/saucectl
brew install saucectl

if [ -z ${BUILDKITE_BUILD} && -z ${BUILDKITE_BUILD} ] 
  then
    readonly BUILD_LABEL="${BUILDKITE_BUILD}-${BUILDKIE_BRANCH}"
  else 
    readonly BUILD_LABEL="dev"
fi

scripts/create-example-application-archive.sh MuxPlayerSwiftExample && saucectl run --build "${BUILD_LABEL}"

