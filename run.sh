#!/bin/sh

echo -n "Wipe existing puppet client installation? (y/n) " ; read wipe
if [ $wipe = 'y' ]; then
  rm -rf /opt/puppet /etc/puppet /var/lib/puppet /var/log/puppet /var/run/puppet
else
  exit 3
fi

export ftp_proxy=www-proxy.ericsson.se:8080
export http_proxy=www-proxy.ericsson.se:8080
export https_proxy=www-proxy.ericsson.se:8080

./bin/build.pl -osver $1

if [ -f /etc/rc.d/init.d/puppet ]; then
  init_s=/etc/rc.d/init.d/puppet
else
  init_s=/etc/init.d/puppet
fi
echo DEBUG: tar czvf /proj/sekirepo/puppet/packages/eispuppet-3.7.4-1_`hostname -s`-`date +%Y%m%d%H%M`.tgz /opt/puppet /etc/puppet /var/log/puppet /var/run/puppet /var/lib/puppet $init_s
