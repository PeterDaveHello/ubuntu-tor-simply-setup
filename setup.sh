#!/bin/bash

set -x
{

StartTimestamp="$(date +%s)"

# confirm permission
if [ "$(id -u)" != "0" ]; then
  echo "Please give me root permission" 1>&2
  exit 1
fi

# binary PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

TorLogPath="${TorLogPath:-/var/log/tor/notices.log}"
user="${user:-anonymous}"
contact="${contact:-anonymous@anonymous}"

# determinate ubuntu version
if [ -r /etc/apt/sources.list.d/official-package-repositories.list ]; then
  apt_source_list=/etc/apt/sources.list.d/official-package-repositories.list
else
  apt_source_list=/etc/apt/sources.list
fi
ubuntu_version="$(grep ^deb $apt_source_list | grep ubuntu --color=never | awk '{print $3}' | sed -E 's/(-[a-z]+)//g' | sort | uniq -c | sort -Vr | head -n 1 | awk '{print $2}')"

# setup apt source
echo "deb http://deb.torproject.org/torproject.org $ubuntu_version main" > /etc/apt/sources.list.d/tor.list

apt-key adv --keyserver keyserver.ubuntu.com --recv 74A941BA219EC810

# update apt meta info
apt update

# upgrade system first
apt-get --force-yes -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
apt-get --force-yes -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

# now install packages
apt-get --force-yes -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install tor tor-arm deb.torproject.org-keyring

# apt clean up
apt-get clean

# enable 21, 443 ports (ufw)
ufw allow 21
ufw allow 443

cat << TORRC > /etc/tor/torrc
# Port for tor
# ORPort 25
# ORPort [ipv6:address]:25 # https://trac.torproject.org/projects/tor/wiki/doc/IPv6RelayHowto
# DirPort 465
ORPort 21
DirPort 443

# as a tor relay
Exitpolicy reject *:*
ExitPolicy reject6 *:*
IPv6Exit 1

# as a tor exit
# ExitPolicy accept *:80,accept *:443,accept *:22,accept *:21,accept *:110,accept *:143,accept *:873,accept *:993,accept *:995,accept *:9418,reject *:*

# contact info
Nickname $user
ContactInfo $contact

# bandwidth limit
RelayBandwidthRate 1 MBytes
RelayBandwidthBurst 2 MBytes

Log notice file $TorLogPath
TORRC

service tor restart

echo "Now sleep for 10 seconds to wait tor bootstraping ..."
sleep 10

echo "Try to grab success message"
if grep -q 'Self-testing indicates your ORPort is reachable from the outside. Excellent.' "$TorLogPath" &> /dev/null; then
  echo "Congratulations! Your tor relay was setup with success!"
else
  echo "I'm not sure if everything okay, please check the log file by yourself!"
  tail -n 15 "$TorLogPath"
fi

EndTimestamp="$(date +%s)"

echo -e "\\nTotal time spent for this setup is $((EndTimestamp - StartTimestamp)) second(s)"
}
