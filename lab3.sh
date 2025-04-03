#!/bin/bash
# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file
scp configure-host.sh remoteadmin@server1-mgmt:/root
ssh remoteadmin@server1-mgmt "bash /root/configure-host.sh $verbose_flag -name loghost -ip 192.168.16.10 -hostentry webhost 192.168.16.4"
scp configure-host.sh remoteadmin@server2-mgmt:/root
ssh remoteadmin@server2-mgmt "bash /root/configure-host.sh $verbose_flag -name webhost -ip 192.168.16.11 -hostentry loghost 192.168.16.3"
sudo ./configure-host.sh $verbose_flag -hostentry loghost 192.168.16.3
sudo ./configure-host.sh $verbose_flag -hostentry webhost 192.168.16.4

echo "Lab3 Done!!!!!"
