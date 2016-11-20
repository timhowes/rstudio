#!/usr/bin/env bash

# set motd
cp /opt/app/vagrant/build.motd.tail /etc/motd

# add repo for R
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install apt-transport-https
apt-key adv --keyserver keys.gnupg.net --recv-key 6212B7B7931C4BB16280BA1306F90DE5381BA480
echo "deb https://cran.rstudio.com/bin/linux/debian jessie-cran3/" >> /etc/apt/sources.list

# bring apt database up to date with R packages
apt-get update

# install R
apt-get install -y --force-yes r-base r-base-dev

# install minimal packages needed to run bootstrap scripts
apt-get install -y unzip
apt-get install -y git
apt-get install -y g++
apt-get install -y wget

# install packages needed to build and run devtools
apt-get install -y libssh2-1-dev
apt-get install -y curl 
apt-get install -y libcurl4-openssl-dev

# install GNU debugger and a JDK
apt-get install -y gdb
apt-get install -y openjdk-7-jdk

# create SSH key if needed
if [ ! -f /opt/app/vagrant/vagrant_key_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -C "vagrant ssh" -f /opt/app/vagrant/vagrant_key_rsa
    chmod 0600 /opt/app/vagrant/vagrant_key_rsa.pub
fi

# download and expand pre-built Boost libraries (TODO: should verify that we're
# on a compatible system) 
mkdir -p /opt/rstudio-tools
cd /opt/rstudio-tools
wget https://s3.amazonaws.com/rstudio-buildtools/rstudio-boost/boost-linux-gcc48-x86_64.tar.gz
tar xzvf boost-linux-gcc48-x86_64.tar.gz
rm boost-linux-gcc48-x86_64.tar.gz

# create RStudio config directory
mkdir -p /etc/rstudio

