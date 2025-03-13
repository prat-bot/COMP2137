#!/bin/bash

username="ladokha"

if grep -q "$username" /etc/passwd; then
    echo "User $username already exists."
else
    echo "Adding user $username."
    sudo adduser $username
    sudo adduser $username sudo
fi
