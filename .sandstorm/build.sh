#!/bin/bash
set -euo pipefail
cd /opt/app
mkdir build
cd build
cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release
sudo make install


set +e

# add rserver user account
sudo /usr/sbin/useradd -r rstudio-server
sudo /usr/sbin/groupadd -r rstudio-server

# create softlink to admin script in /usr/sbin
sudo ln -f -s /usr/local/lib/rstudio-server/bin/rstudio-server /usr/sbin/rstudio-server

# create config directory and default config files
sudo mkdir -p /etc/rstudio
if ! test -f /etc/rstudio/rserver.conf
then
  sudo sh -c "printf '# Server Configuration File\n\n' > /etc/rstudio/rserver.conf"
fi
if ! test -f /etc/rstudio/rsession.conf
then
  sudo sh -c "echo '# R Session Configuration File\n\n' > /etc/rstudio/rsession.conf"
fi

# create var directories
sudo mkdir -p /var/run/rstudio-server
sudo mkdir -p /var/lock/rstudio-server
sudo mkdir -p /var/log/rstudio-server
sudo mkdir -p /var/lib/rstudio-server
sudo mkdir -p /var/lib/rstudio-server/conf
sudo mkdir -p /var/lib/rstudio-server/body
sudo mkdir -p /var/lib/rstudio-server/proxy

# suspend all sessions
sudo /usr/sbin/rstudio-server force-suspend-all

# check lsb release and init system
LSB_RELEASE=`lsb_release --id --short`
INIT_SYSTEM=`cat /proc/1/comm 2>/dev/null`

# add apparmor profile (but don't for systemd as this borks up process management)
if test $LSB_RELEASE = "Ubuntu" && test -d /etc/apparmor.d/ && ! test $INIT_SYSTEM = "systemd"
then
   sudo cp /usr/local/lib/rstudio-server/extras/apparmor/rstudio-server /etc/apparmor.d/
   sudo apparmor_parser -r /etc/apparmor.d/rstudio-server 2>/dev/null
elif test -e /etc/apparmor.d/rstudio-server
then
   sudo rm -f /etc/apparmor.d/rstudio-server
   sudo /usr/sbin/invoke-rc.d apparmor reload 2>/dev/null
fi

# add systemd, upstart, or init.d script and start the server
if test "$INIT_SYSTEM" = "systemd"
then
   sudo systemctl stop rstudio-server.service 2>/dev/null
   sudo systemctl disable rstudio-server.service 2>/dev/null
   sudo cp /usr/local/lib/rstudio-server/extras/systemd/rstudio-server.service /etc/systemd/system/rstudio-server.service
   sudo systemctl daemon-reload
   sudo systemctl enable rstudio-server.service
   sudo systemctl start rstudio-server.service
   sleep 1
   sudo systemctl --no-pager status rstudio-server.service
elif test $LSB_RELEASE = "Ubuntu" && test -d /etc/init/
then
   sudo cp /usr/local/lib/rstudio-server/extras/upstart/rstudio-server.conf /etc/init/
   sudo initctl reload-configuration
   sudo initctl stop rstudio-server 2>/dev/null
   sudo initctl start rstudio-server
else
   sudo cp /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /etc/init.d/
   sudo chmod +x /etc/init.d/rstudio-server
   sudo /usr/sbin/update-rc.d rstudio-server defaults
   sudo /etc/init.d/rstudio-server stop  2>/dev/null
   sudo /etc/init.d/rstudio-server start
fi

set -e


exit 0
