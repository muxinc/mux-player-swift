#!/bin/bash

set -euo pipefail

# Package.swift does not declare official tvOS support. Set the deployment
# target explicitly to model a tvOS consumer and catch source-level regressions.
xcodebuild -quiet build \
    -scheme MuxPlayerSwift \
    -destination "generic/platform=tvOS Simulator" \
    TVOS_DEPLOYMENT_TARGET=15.0 \
    CODE_SIGNING_ALLOWED=NO
