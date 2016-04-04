FROM ubuntu:trusty

MAINTAINER yangsbj@cn.ibm.com

ENV xcatcoreurl "http://xcat.org/files/xcat/repos/apt/devel/core-snap trusty main"
ENV xcatdepurl  "http://xcat.org/files/xcat/repos/apt/xcat-dep trusty main"

VOLUME ["/install","/var/log/xcat/"]
COPY startservice.sh /bin/startservice.sh 
COPY patch.bin.stop /sbin/stop
COPY motd /etc/motd

RUN apt-get update && apt-get install -y \
            wget \
            openssh-server ; \  
            wget -O - \
            "http://sourceforge.net/projects/xcat/files/ubuntu/apt.key/download" \
            | apt-key add - ; \
            echo  \
            "deb ${xcatcoreurl}" \    
             > /etc/apt/sources.list.d/xcat-core.list ; \
            echo \
            "deb ${xcatdepurl}"  \
            > /etc/apt/sources.list.d/xcat-dep.list ; \
            apt-get update && apt-get -y install \
            xcat \
            && apt-get clean \ 
            && rm -rf /var/lib/apt/lists/*; \
            cp -rf  /install/postscripts  /opt/xcat/ \
            && rm -rf /install/postscripts ; \
            cp -rf  /install/prescripts  /opt/xcat/ \
            && rm -rf /install/prescripts; \
            service xcatd stop  ; \
            chmod +x /bin/startservice.sh; \
            chmod +x /sbin/stop; \
            sudo a2enmod ssl; \
            ln -s ../sites-available/default-ssl.conf  /etc/apache2/sites-enabled/ssl.conf; \
            [ -e "/etc/ssh/sshd_config" ] \
            && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config ;\
            echo "root:cluster" | chpasswd ; \
            touch /etc/NEEDINIT 
    

ENTRYPOINT ["/bin/startservice.sh"]
