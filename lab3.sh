#!/bin/bash
# Server configuration deployment script

# Enable error handling
set -e

verbose_flag=""
if [[ "$1" == "-verbose" ]]; then
    verbose_flag="-verbose"
    echo "Verbose mode enabled"
    shift
fi

# Function to handle errors
exit_on_error() {
    echo "Error: $1"
    exit 1
}

scp configure-host.sh remoteadmin@server1-mgmt:/root
ssh remoteadmin@server1-mgmt "bash /root/configure-host.sh $verbose_flag -name loghost -ip 192.168.16.10 -hostentry webhost 192.168.16.11"
scp configure-host.sh remoteadmin@server2-mgmt:/root
ssh remoteadmin@server2-mgmt "bash /root/configure-host.sh $verbose_flag -name webhost -ip 192.168.16.11 -hostentry loghost 192.168.16.10"
sudo ./configure-host.sh $verbose_flag -hostentry loghost 192.168.16.10
sudo ./configure-host.sh $verbose_flag -hostentry webhost 192.168.16.11

echo "Lab3 Done!!!!!"
