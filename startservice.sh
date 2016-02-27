#! /bin/bash

# This script will be run as the ENTRYPOINT of xCAT docker image
# to start xcatd and depended services

# Export the xCAT default Env variables

. /etc/profile.d/xcat.sh

clusterdomain=
clusterdomain_def="clusters.com"
while [ "$#" -gt "0" ] ; do
    case "$1" in
        "--clusterdomain")
            shift;
            [ "${1:0:1}" != "-" ] && echo "$1 llllzzzz"
            [ -n "$1" ] && [ "${1:0:1}" != "-" ] && clusterdomain="$1" && shift  
            ;;
        *)
            [ -n "$1" ] && [ "${1:0:1}" != "-" ] && break
            ;;
    esac
done

[ -z "$clusterdomain" ] && ( echo "--clusterdomain not specified, default to \"$clusterdomain_def\""; clusterdomain="$clusterdomain_def" )


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

chdef -t site -o clustersite domain="$clusterdomain"

tabprune networks -a 

makenetworks

cat /etc/motd
bash
