#!/bin/bash

readonly DOCUMENTATION_HOMEPAGE_SLUG=mux-player-swift

echo "▸ Creating docc static archive"
./scripts/create-docc-archive.sh

echo "▸ Preparing docc static archive for deployment"
./scripts/post-process-docc-archive.sh $DOCUMENTATION_HOMEPAGE_SLUG $DOCUMENTATION_HOMEPAGE_SLUG
