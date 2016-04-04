#!/bin/bash

set -x
{

StartTimestamp="`date +%s`"

# confirm permission
if [ "$(id -u)" != "0" ]; then
   echo "Please give me root permission" 1>&2
   exit 1
fi

# binary PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# determinate ubuntu version
if [ -r /etc/apt/sources.list.d/official-package-repositories.list ]; then
    apt_source_list=/etc/apt/sources.list.d/official-package-repositories.list
else
    apt_source_list=/etc/apt/sources.list
fi
ubuntu_version="`grep ^deb $apt_source_list | grep ubuntu --color=never | awk '{print $3}' |  sed -E 's/(-[a-z]+)//g' | sort | uniq -c | sort -r | head -n 1 | awk '{print $2}'`"

# setup apt source
echo "deb http://deb.torproject.org/torproject.org $ubuntu_version main" > /etc/apt/sources.list.d/tor.list

apt-key adv --keyserver keyserver.ubuntu.com --recv 74A941BA219EC810

# update apt meta info
apt-get update

# upgrade system first
apt-get --force-yes -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
apt-get --force-yes -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

# now install packages
apt-get --force-yes -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install tor tor-arm deb.torproject.org-keyring

# apt clean up
apt-get clean

# enable 80/443 ports (ufw)
ufw allow 80
ufw allow 443

if [ ! -z "$1" ]; then
    user="$1"
    contact="$2"
else
    user="anonymousByPDH"
    contact="anonymous@ubuntu-tor-simply-setup.script.by.PeterDaveHello"
fi

cat <<TORRC > /etc/tor/torrc
# Port for tor
# ORPort 443
ORPort 80

# as a tor relay
Exitpolicy reject *:*

# as a tor exit
# ExitPolicy accept *:80,accept *:443,accept *:22,accept *:21,accept *:110,accept *:143,accept *:873,accept *:993,accept *:995,accept *:9418,reject *:*

# contact info
Nickname $user
ContactInfo $contact

# bandwidth limit
RelayBandwidthRate 1 MBytes
RelayBandwidthBurst 2 MBytes

TORRC

service tor restart

echo "Now sleep for 10 seconds to wait tor bootstraping ..."
sleep 10

echo "Try to grab success message"
grep 'Self-testing indicates your ORPort is reachable from the outside. Excellent.' /var/log/tor/log &> /dev/null

if [ "$?" = "0" ]; then
    echo "Congratulations! Your tor relay was setup with success!"
else
    echo "I'm not sure if everything okay, please check the log file by yourself!"
    cat /var/log/tor/log
fi

EndTimestamp="`date +%s`"

echo -e "\nTotal time spent for this setup is $(($EndTimestamp - $StartTimestamp)) second(s)"
}