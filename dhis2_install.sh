#!/bin/bash

# Setup DHIS on a fresh install of Ubuntu 16.04
# Assumes you are already a user called dhis with sudo privileges

echo creating configuration folder
mkdir /home/dhis/config

echo setting time zone to server location
sudo dpkg-reconfigure tzdata
locale -a
sudo locale-gen nb_NO.UTF-8




