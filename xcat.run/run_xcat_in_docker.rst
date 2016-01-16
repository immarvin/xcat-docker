Run xCAT in Docker Container
============================

`Docker<https://www.docker.com/>`_ is a popular application containment environment. With Docker, applications/Services are shipped as `Docker images` and run in `Docker containers`. `Docker containers` include the application and all of its dependencies, but share the kernel with other containers. They run as an isolated process in userspace on the host operating system. The server on which  `Docker containers` run are called `Docker host`.

When running xCAT in Docker container, you do not have to worry about the xCAT installation and configuration on different OS and hardware platforms, just focus on the cluster management work with xCAT features.


Prerequisite: setup Docker host
--------------------------------

You can select a baremental or virtual server with the Operating Systems which docker supports as a docker host,then install Docker on it. Please refer to `Docker Docs<https://docs.docker.com/>`_ for the details of system requirements and Docker installation.

**Note:** Running xCAT in Docker requires x86_64 or ppc64le Docker hosts, since a `Docker image` can only run on the `Docker host` with the same archtecture, and xCAT currently only ships x86_64 and ppc64le Docker images. 


An example configuration in the documentation
--------------------------------------------- 

To demonstrate the steps to run xCAT in a Docker container, take a cluster with the following configuration as an example ::

    Docker host: dockerhost1
    The Docker host network interface facing the compute nodes: eth0
    The IP address of eth0: 10.5.106.1/24
    The customized docker bridge: br0
    The docker container name running xCAT: xcat2-11mn 
    The hostname of container xcat2-11mn: xcat2-11mn
    The IP address of container xcat2-11mn: 10.5.106.101
    The name server of container xcat2-11mn: 10.5.106.1
    The dns domain of container xcat2-11mn: clusters.com 


Create a customized bridge on the Docker host
---------------------------------------------

`Docker containers` connect to the Docker host network via a network bridge. To run xCAT in Docker, you should create a customized bridge according to the cluster network plan, instead of the default bridge "docker0".

As an example, you create a bridge "br0" and attach the network interface "eth0" to it ::   

    brctl addbr br0
    brctl setfd br0 0
    ip addr del dev eth0 10.5.106.1/24
    brctl addif br0 eth0
    ip link set br0 up
    ip addr add dev br0 10.5.106.1/24


Pull the xCAT Docker image from DockerHub:
------------------------------------------

Now xCAT ships xCAT 2.11 Docker images(x86_64 and ppc64le) on the `DockerHub<https://hub.docker.com/u/xcat/>`_:

To pull the xCAT 2.11 Docker for x86_64, run ::

    [root@dockerhost1 ~]# sudo docker pull xcat/xcat-ubuntu-x86_64
    Using default tag: latest
    latest: Pulling from xcat/xcat-ubuntu-x86_64
    27fd83569599: Pull complete 
    89706b056337: Pull complete 
    3285add8133c: Pull complete 
    1f5976d786ae: Downloading [=====================>                             ] 70.81 MB/163.8 MB
    1f5976d786ae: Pull complete 
    d0442ae1ac04: Pull complete 
    9c0a9f718574: Pull complete 
    be5d9994870b: Pull complete 
    9be4d0394b0d: Pull complete 
    78dd691f50bf: Pull complete 
    Digest: sha256:a7b5cc6157b7fd6837752d43c298d1a031d371752c18b312c54fe5c45366cb12
    Status: Downloaded newer image for xcat/xcat-ubuntu-x86_64:latest


On success, you will see the pulled Docker image on Docker host ::

     [root@dockerhost1 ~]# sudo docker images
     REPOSITORY                 TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
     xcat/xcat-ubuntu-x86_64    latest              78dd691f50bf        5 hours ago         630.6 MB


Create the Docker container
---------------------------

Now create the xCAT Docker container with the Docker image "xcat/xcat-ubuntu-x86_64" ::

    [root@dockerhost1 ~]# sudo docker create -it --privileged=true  --dns=10.5.106.1  --dns-search=clusters.com --hostname=xcat2-11mn --name=xcat2-11mn --add-host=xcat2-11mn:10.5.106.101 --add-host c910f05c01bc06:10.5.106.1 --net=none xcat/xcat-ubuntu-x86_64:2.11

* use "--privileged=true" to give extended privileges to this container
* use "--dns" and "--dns-search" to specify the name server and dns domain for the container,which will be written to "/etc/resolv.conf" of the container
* use "--hostname" to specify the hostname of the container, which is available inside the container
* use "--name" to assign a name to the container 
* use "--add-host" to write the "/etc/hosts" entries of Docker host and Docker container to "/etc/hosts" in the container
* use "--net=none" not to create networking for the container


Start the Docker container
--------------------------

Start the pre-created container "xcat2-11mn" with ::

   sudo docker start xcat2-11mn


Setup the network for the Docker container
------------------------------------------     

Now you need to assign a static IP address for Docker container and attach it to the customized network bridge.Since Docker does not provide native support on this, `pipeworks<https://github.com/jpetazzo/pipework>`_ can be used to simplify the work.

First, download the "pipework" ::
    
    git clone https://github.com/jpetazzo/pipework.git
 
install "pipework" by copying the script "pipework" to "/usr/local/bin/pipework" ::
   
    cp ./pipework /usr/local/bin/pipework

Assign a static IP address for Docker container and attach it to the customized network bridge with ::
  
    pipework <bridge name> <container name> <IP address/netmask for the container>@<gateway>

As an example, run ::

    pipework br0 xcat2-11mn 10.5.106.101/24@10.5.106.1


Attach to the Docker container
------------------------------
   
You can attach to the container :: 
    
    sudo docker attach xcat2-11mn

Besides the terminal opened by ``docker  attach``, you can also enable the ssh inside the container and login the Docker container via "ssh". For ubuntu, you can enable the ssh by:
  
* change the "PermitRootLogin" to "yes" in "/etc/ssh/sshd_config"      
* set the password for "root" with ``passwd root``
* restart the sshd service with ``service ssh restart``


Play with xCAT
--------------

Once you attach or ssh to the container, you will find that xCAT is running and has already been well configured, you can play with xCAT and manage your cluster now. 

Due to the features of Docker container, there are some differences from the xCAT documentation:

* The "/install/sources" in the container is a data volume from Docker host to prevent the growth of the Docker container size. You should specify "-p /install/sources/<osver>/<arch>", for example ::

   copycds -p /install/sources/rhels7.2/x86_64/  RHEL-7.2-Server-x86_64-dvd.iso


Known Issues
------------

Since Docker is still in the maturing process, there are some issues which cause some problem for xCAT :

* copycds might hang due to all the loop devices(/dev/loop1,/dev/loop2) in the Docker host are busy. You can run ``losetup -f`` to get the first available loop device, if it fails, you might need to make add several loop devices with ::

   # mknod /dev/loop3 -m0660 b 7 3
   # mknod /dev/loop4 -m0660 b 7 4
   ...
   # mknod /dev/loop9 -m0660 b 7 9 








