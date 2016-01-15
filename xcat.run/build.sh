#!/bin/bash


MYARCH=$(uname -i)

MYARCH=$(echo $MYARCH | tr [A-Z] [a-z])

DOCKFILE=""
IMAGENAME=""

[ "$MYARCH" = "ppc64le" ] && { DOCKFILE="dockerfile.xcat.ppc64le.run";IMAGENAME="xcat/xcat-ubuntu-ppc64le:2.11"; }

[ "$MYARCH" = "x86_64" ] && { DOCKFILE="dockerfile.xcat.x86_64.run";IMAGENAME="xcat/xcat-ubuntu-x86_64:2.11"; }


[ -n "$DOCKFILE"  ] && [ -n "$IMAGENAME" ] && sudo docker build -t $IMAGENAME -f $DOCKFILE  .


echo "*********************************************"

echo "Docker Image: $IMAGENAME Created!"

echo "*********************************************"
