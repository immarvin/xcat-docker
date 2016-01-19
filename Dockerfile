FROM ubuntu:trusty

MAINTAINER yangsbj@cn.ibm.com

RUN apt-get update && apt-get install -y \
            wget \
            openssh-server 

RUN wget -O - \
    "http://sourceforge.net/projects/xcat/files/ubuntu/apt.key/download" \
    | apt-key add - ; \
    echo  \
    "deb http://xcat.org/files/xcat/repos/apt/2.11/xcat-core trusty main" \    
     > /etc/apt/sources.list.d/xcat-core.list ; \
    echo \
    "deb http://xcat.org/files/xcat/repos/apt/xcat-dep trusty main"  \
    > /etc/apt/sources.list.d/xcat-dep.list

RUN apt-get update && apt-get -y install \
            xcat \
            && apt-get clean \ 
            && rm -rf /var/lib/apt/lists/* 

RUN cp -rf  /install/postscripts  /opt/xcat/ \
            && rm -rf /install/postscripts 
RUN    cp -rf  /install/prescripts  /opt/xcat/ \
            && rm -rf /install/prescripts 

RUN    cp -rf  /install/winpostscripts  /opt/xcat/ \
            && rm -rf /install/winpostscripts 
                           

VOLUME ["/install"]

COPY startservice.sh /bin/startservice.sh 
COPY patch.bin.stop /sbin/stop

RUN chmod +x /bin/startservice.sh; \
    chmod +x /sbin/stop

ENTRYPOINT ["/bin/startservice.sh"]
