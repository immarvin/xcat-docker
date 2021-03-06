#! /bin/bash

# This script will be run as the ENTRYPOINT of xCAT docker image
# to start xcatd and depended services

# Export the xCAT default Env variables

. /etc/profile.d/xcat.sh

#clusterdomain=
#clusterdomain_def="clusters.com"
#while [ "$#" -gt "0" ] ; do
#    case "$1" in
#        "--clusterdomain")
#            shift;
#            [ "${1:0:1}" != "-" ] && echo "$1 llllzzzz"
#            [ -n "$1" ] && [ "${1:0:1}" != "-" ] && clusterdomain="$1" && shift  
#            ;;
#        *)
#            [ -n "$1" ] && [ "${1:0:1}" != "-" ] && break
#            ;;
#    esac
#done
#
#[ -z "$clusterdomain" ] && ( echo "--clusterdomain not specified, default to \"$clusterdomain_def\""; clusterdomain="$clusterdomain_def" )


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

chown -R syslog:adm /var/log/xcat/ 
     
#/dev/loop0 and /dev/loop1 will be occupiered by docker by default
#create a loop device if there is no free loop device inside contanier
losetup -f >/dev/null 2>&1 || (
  maxloopdev=$(losetup -a|awk -F: '{print $1}'|sort -f -r|head -n1);
  maxloopidx=$[${maxloopdev/#\/dev\/loop}];
  mknod /dev/loop$[maxloopidx+1] -m0660 b 7 $[maxloopidx+1] && echo "no free loop device inside container,created a new loop device /dev/loop$[maxloopidx+1]..."
)

#mkdir -p /install/winpostscripts/ && \
#     isBINDMOUNT opt/xcat/winpostscripts/  /install/winpostscripts/ && \
#     mount -o bind /opt/xcat/winpostscripts/ /install/winpostscripts/

echo "restarting apache2 service..."
service apache2 restart

echo "restarting ssh service..."
service ssh restart

echo "restarting isc-dhcp-server service..."
service isc-dhcp-server restart

echo "restarting rsyslog service..."
service rsyslog restart

echo "restarting xcatd service..."
service xcatd restart


#MYIP=$(ip -o -4 addr show dev eth0 2>/dev/null |grep eth0|awk -F' ' '{print $4}'|sed -e 's/\/.*//')
#MYHOSTNAME=$(hostname)
# 
#([ -n "$MYIP" ] && [ -n "$MYHOSTNAME" ]) && sed -i -e "/\<$MYHOSTNAME\>/d" /etc/hosts && echo "$MYHOSTNAME.$clusterdomain $MYHOSTNAME $MYIP" >> /etc/hosts

if [ -e "/etc/NEEDINIT"  ]; then
    echo "initializing xCAT Tables..."
    xcatconfig -d

    #chdef -t site -o clustersite domain="$clusterdomain"
    echo "initializing networks table..."
    tabprune networks -a 
    makenetworks
    
    rm -f /etc/NEEDINIT
fi


#restore the backuped db on container start to resume the service state
if [ -d "/.dbbackup" ]; then   
        echo "xCAT DB backup directory \"/.dbbackup\" detected, restoring xCAT tables from /.dbbackup/..." 
        restorexCATdb -p /.dbbackup/ 
        echo "finished xCAT Tables restore!"
fi

. /etc/profile.d/xcat.sh

cat /etc/motd
HOSTIPS=$(ip -o -4 addr show up|grep -v "\<lo\>"|xargs -I{} expr {} : ".*inet \([0-9.]*\).*")
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "welcome to Dockerized xCAT, please login with"
[ -n "$HOSTIPS"  ] && for i in $HOSTIPS;do echo "   ssh root@$i   ";done && echo "The initial password is \"cluster\""
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"


#read -p "press any key to continue..." 
/bin/bash
