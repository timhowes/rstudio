#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

cd /opt/app/dependencies/linux
./install-dependencies-debian --exclude-qt-sdk

exit 0
