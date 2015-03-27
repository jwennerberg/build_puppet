#!/bin/sh

eispuppet_version="3.7.5-1"

echo -n "Wipe existing puppet client installation? (y/n) " ; read wipe
if [ $wipe = 'y' ]; then
  rm -rf /opt/puppet /etc/puppet /var/lib/puppet /var/log/puppet /var/run/puppet
else
  exit 3
fi

export ftp_proxy=www-proxy.ericsson.se:8080
export http_proxy=www-proxy.ericsson.se:8080
export https_proxy=www-proxy.ericsson.se:8080
export no_proxy="ericsson.se"

./bin/build.pl -osver $1

if [ -f /etc/rc.d/init.d/puppet ]; then
  init_s=/etc/rc.d/init.d/puppet
else
  init_s=/etc/init.d/puppet
fi
echo DEBUG: tar czvf /proj/sekirepo/puppet/packages/eispuppet-${eispuppet_version}_`hostname -s`-`date +%Y%m%d%H%M`.tgz /opt/puppet /etc/puppet /var/log/puppet /var/run/puppet /var/lib/puppet $init_s
