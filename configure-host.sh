#!/bin/bash

# Prevent the script from being interrupted accidentally
trap '' TERM HUP INT

verbose_mode=0
desired_name=""
desired_ip=""
add_host_name=""
add_host_ip=""

# Read user instructions from command line
while [[ $# -gt 0 ]]; do
    case $1 in
        -verbose)
            verbose_mode=1
            ;;
        -name)
            desired_name=$2
            shift
            ;;
        -ip)
            desired_ip=$2
            shift
            ;;
        -hostentry)
            add_host_name=$2
            add_host_ip=$3
            shift 2
            ;;
        *)
            echo "Didn't recognize the option: $1"
            exit 1
            ;;
    esac
    shift
done

# Helper function to show messages and record them
show_message() {
    if [ $verbose_mode -eq 1 ]; then
        echo "$1"
    fi
    logger "Server Setup: $1"
}
#Update Computer Name
if [ ! -z "$desired_name" ]; then
    current_name=$(hostname)
    if [ "$current_name" != "$desired_name" ]; then
        show_message "Changing computer name from '$current_name' to '$desired_name'"
        
        # Update name configuration files
        echo "$desired_name" > /etc/hostname
        # Fix the hosts file entry
        sed -i "s/127.0.1.1.*/127.0.1.1\t$desired_name/" /etc/hosts
        # Apply the new name immediately
        hostnamectl set-hostname "$desired_name"
    else
        show_message "Computer name is already '$desired_name'"
    fi
fi


# Update IP address if specified
if [ -n "$new_ip" ]; then
    current_ip=$(hostname -I | awk '{print $1}')
    if [ "$current_ip" != "$new_ip" ]; then
        log_message "Changing IP address from $current_ip to $new_ip"

        #Configure eth0 with static IP, gateway, and DNS via nmcli
        nmcli connection modify eth0 ipv4.addresses "$new_ip/24" ipv4.gateway "192.168.16.1" ipv4.dns "8.8.8.8" ipv4.method manual
        nmcli connection up eth0

        # Update hosts file with new IP
        sed -i "s/$current_ip/$new_ip/" /etc/hosts
    else
        log_message "IP address already set to $new_ip"
    fi
fi

# Add Hosts File Entry
if [ ! -z "$add_host_name" ] && [ ! -z "$add_host_ip" ]; then
    if ! grep -q "$add_host_ip[[:space:]]$add_host_name" /etc/hosts; then
        show_message "Adding $add_host_name ($add_host_ip) to network lookup file"
        echo "$add_host_ip $add_host_name" >> /etc/hosts
    else
        show_message "$add_host_name is already in the network lookup file"
    fi
fi
