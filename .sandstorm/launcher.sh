#!/bin/bash
set -euo pipefail
# This script is run every time an instance of our app - aka grain - starts up.
# This is the entry point for your application both when a grain is first launched
# and when a grain resumes after being previously shut down.
#
# This script is responsible for launching everything your app needs to run.  The
# thing it should do *last* is:
#
#   * Start a process in the foreground listening on port 8000 for HTTP requests.
#
# This is how you indicate to the platform that your application is up and
# ready to receive requests.  Often, this will be something like nginx serving
# static files and reverse proxying for some other dynamic backend service.
#
# Other things you probably want to do in this script include:
#
#   * Building folder structures in /var.  /var is the only non-tmpfs folder
#     mounted read-write in the sandbox, and when a grain is first launched, it
#     will start out empty.  It will persist between runs of the same grain, but
#     be unique per app instance.  That is, two instances of the same app have
#     separate instances of /var.
#   * Preparing a database and running migrations.  As your package changes
#     over time and you release updates, you will need to deal with migrating
#     data from previous schema versions to new ones, since users should not have
#     to think about such things.
#   * Launching other daemons your app needs (e.g. mysqld, redis-server, etc.)

# By default, this script does nothing.  You'll have to modify it as
# appropriate for your application.
cd /opt/app

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
    sudo sh -c "printf 'www-port=8000\n' >> /etc/rstudio/rserver.conf"
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
