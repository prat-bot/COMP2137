#!/bin/bash

# Ensure the script is executed as root
if [[ $EUID -ne 0 ]]; then
    echo "This script requires root user to execute"
    exit 1
fi

# Configure network interface
ip="192.168.16.21/24"
Netplan_configuration="/etc/netplan/10-lxc.yaml"
interface=eth0

if [ ! -f "$Netplan_configuration" ]; then
    echo "$Netplan_configuration file not found"
    exit 1
fi

if grep -q "addresses:" "$Netplan_configuration"; then
   sed -i "/eth0:/,/nameservers/ { /addresses:/ s|addresses: \[[^]]*\]|addresses: [$ip]| }" "$Netplan_configuration"
else
    cat <<EOF >> "$Netplan_configuration"
network:
    version: 2
    ethernets:
        $interface:
            addresses: [$ip]
            dhcp4: false
EOF
fi

netplan apply
if [ $? -eq 0 ]; then
    echo "Netplan configuration applied successfully."
else
    echo "Error: Failed to apply netplan configuration."
    exit 1
fi

# Ensure /etc/hosts contains the correct entry for server1
echo "Updating /etc/hosts on server 1"

if ! grep -q "192.168.16.21 server1" /etc/hosts; then
    sed -i '/server1/d' /etc/hosts
    echo "192.168.16.21 server1" >> /etc/hosts
    echo "Configuration complete!"
else
    echo "/etc/hosts already updated"
fi

# Install software
apt-get update
if ! dpkg -l | grep -qw apache2; then
    apt-get install -y apache2
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Apache."
        exit 1
    fi
    systemctl enable apache2
    echo "Apache installation is done."
else
    echo "Apache is already installed."
fi

if ! dpkg -l | grep -qw squid; then
    apt-get install -y squid
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Squid."
        exit 1
    fi
    systemctl enable squid
    echo "Squid installation is done."
else
    echo "Squid is already installed."
fi

if systemctl is-enabled ovsdb-server.service &>/dev/null; then
    sudo systemctl mask ovsdb-server.service
    echo "ovsdb-server.service masked."
else
    echo "ovsdb-server.service is already masked."
fi

# Create users and SSH keys
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${users[@]}"; do
    if ! id "$user" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$user"
    else
        echo "User $user already exists."
        if [ ! -d "/home/$user" ]; then
            sudo mkdir -p /home/"$user"
            sudo chown "$user":"$user" /home/"$user"
        fi
    fi

    # Create .ssh directory
    sudo -u "$user" mkdir -p /home/"$user"/.ssh
    sudo -u "$user" chmod 700 /home/"$user"/.ssh

    # Generate SSH keys
    if [ ! -f "/home/$user/.ssh/id_rsa" ]; then
        sudo -u "$user" ssh-keygen -t rsa -N "" -f /home/"$user"/.ssh/id_rsa -q
    fi
    if [ ! -f "/home/$user/.ssh/id_ed25519" ]; then
        sudo -u "$user" ssh-keygen -t ed25519 -N "" -f /home/"$user"/.ssh/id_ed25519 -q
    fi

    # For Dennis, check if the special public key is missing and add it if needed.
    if [ "$user" == "dennis" ]; then
        special_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
        if [ ! -f "/home/dennis/.ssh/authorized_keys" ] || ! grep -qF "$special_key" /home/dennis/.ssh/authorized_keys; then
            echo "$special_key" >> /home/dennis/.ssh/authorized_keys
            echo "Special key added for dennis."
        fi
    fi

    # Merge all public keys into authorized_keys, ensuring no duplicates.
    sudo -u "$user" sh -c 'cat ~/.ssh/*.pub 2>/dev/null | sort -u > ~/.ssh/authorized_keys.tmp && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys'
    sudo -u "$user" chmod 600 /home/"$user"/.ssh/authorized_keys
    echo "Authorized_keys updated for $user."

    # Make sure Dennis is added to the sudo group.
    if [ "$user" == "dennis" ]; then
        if ! groups dennis | grep -qw sudo; then
            usermod -aG sudo dennis
            echo "User dennis added to sudo group."
        fi
    fi
done

echo "System Modification is Done"
