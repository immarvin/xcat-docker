#! /bin/bash

# This script will be run as the ENTRYPOINT of xCAT docker image
# to start xcatd and depended services

# Export the xCAT default Env variables
. /etc/profile.d/xcat.sh

mkdir -p /install/postscripts/

mount -o bind /opt/xcat/postscripts/ /install/postscripts/

service apache2 start

service ssh start

service isc-dhcp-server start

service rsyslog start

service xcatd start


MYIP=$(ip -o -4 addr show dev eth0 |grep eth0|awk -F' ' '{print $4}'|sed -e 's/\/.*//')
MYHOSTNAME=$(hostname)

([ -n "$MYIP" ] && [ -n "$MYHOSTNAME" ]) && echo "$MYHOSTNAME  $MYIP" >> /etc/hosts


xcatconfig -d

tabprune networks -a 

makenetworks

bash
