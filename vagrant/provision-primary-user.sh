#!/usr/bin/env bash

# install dependencies
export QT_SDK_DIR=/home/vagrant/Qt5.4.0
cd /opt/app/dependencies/linux

LINUX_SYS=debian
if [ -f /etc/redhat-release ]; then
    LINUX_SYS=yum
fi

./install-dependencies-$LINUX_SYS --exclude-qt-sdk

# resiliency
./install-dependencies-$LINUX_SYS --exclude-qt-sdk

# run overlay script if present
if [ -f ./install-overlay-$LINUX_SYS ]; then
    ./install-overlay-$LINUX_SYS
fi 

cd /opt/app/vagrant

# configure a basic c/c++ editing experience inside the VM 
#./provision-editor.sh

# run common user provisioning script
./provision-common-user.sh

