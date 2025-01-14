#! /bin/bash

if [ -z ${BUILDKITE_BUILD} && -z ${BUILDKITE_BUILD} ] 
  then
    readonly BUILD_LABEL="${BUILDKITE_BUILD}-${BUILDKIE_BRANCH}"
  else 
    readonly BUILD_LABEL="Local Build"
fi

scripts/create-example-application-archive.sh MuxPlayerSwiftExample && saucectl run --build ${BUILD_LABEL}

