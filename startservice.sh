#! /bin/bash

# This script will be run as the ENTRYPOINT of xCAT docker image
# to start xcatd and depended services

# Export the xCAT default Env variables
. /etc/profile.d/xcat.sh

#verify whether $DST is bind mount from $SRC
function isBINDMOUNT {
    local SRC=$1
    local DST=$2
    SRC=$(echo "$SRC" | sed -r 's/\/$//')
    findmnt -n $DST | awk -F' ' '{print $2}' | grep -E "\[.*$SRC\]" >/dev/null 2>&1 && return 0
    return 1
}


mkdir -p /install/postscripts/ && \
     isBINDMOUNT /opt/xcat/postscripts/  /install/postscripts/ || \
     mount -o bind /opt/xcat/postscripts/ /install/postscripts/


mkdir -p /install/prescripts/ && \
     isBINDMOUNT /opt/xcat/prescripts/  /install/prescripts/ || \
     mount -o bind /opt/xcat/prescripts/ /install/prescripts/


#mkdir -p /install/winpostscripts/ && \
#     isBINDMOUNT opt/xcat/winpostscripts/  /install/winpostscripts/ && \
#     mount -o bind /opt/xcat/winpostscripts/ /install/winpostscripts/

service apache2 start

service ssh start

service isc-dhcp-server start

service rsyslog start

service xcatd start


MYIP=$(ip -o -4 addr show dev eth0 2>/dev/null |grep eth0|awk -F' ' '{print $4}'|sed -e 's/\/.*//')
MYHOSTNAME=$(hostname)

([ -n "$MYIP" ] && [ -n "$MYHOSTNAME" ]) && echo "$MYHOSTNAME  $MYIP" >> /etc/hosts


xcatconfig -d

tabprune networks -a 

makenetworks

bash
