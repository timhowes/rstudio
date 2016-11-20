#!/bin/bash
set -euo pipefail

cd /opt/app
mkdir build
cd build
cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release
sudo make install

exit 0

