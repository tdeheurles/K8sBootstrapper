#!/usr/bin/env bash

set -euo pipefail

(
    cd crossplane
    ./01_setup_crossplane.sh
    ./02_install_providers.sh
)

# kubectl apply -f ./composition

# echo "build"
# kubectl crossplane build configuration \
#     -f ./package/crossplane-quickstart-part3 \
#     --name="tdeheurles-crossplane-database-0.0"

# echo "push"
# kubectl crossplane push configuration \
#     --package="./package/crossplane-quickstart-part3/tdeheurles-crossplane-database-0.0.xpkg" \
#     tdeheurles/crossplane-database:0.0.0
