#!/bin/bash

# Setup DHIS on a fresh install of Ubuntu 16.04
# Assumes you are already a user called dhis with sudo privileges

if [ ! -d /home/dhis/config ]; then
    echo creating configuration folder
    mkdir /home/dhis/config
fi

# Set the time zone - this requires user input - to be automated
#echo setting time zone to server location
#sudo dpkg-reconfigure tzdata
#locale -a
#sudo locale-gen nb_NO.UTF-8

# TODO - check if Postgres 9.4 is already installed
sudo apt-get install postgresql-9.4

sudo su - postgres -c "
psql -U postgres -f 
"

