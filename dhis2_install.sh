#!/bin/bash

# Setup DHIS on a fresh install of Ubuntu 16.04
# Assumes you are already a user called dhis with sudo privileges

echo What password do you want for your postgres user?
read postgres_password

if [ ! -d /home/dhis/config ]; then
    echo creating configuration folder
    mkdir /home/dhis/config
fi

# Set the time zone - this requires user input - to be automated
#echo setting time zone to server location
#sudo dpkg-reconfigure tzdata
#locale -a
#sudo locale-gen nb_NO.UTF-8

# TODO - check if Postgres 9.5 is already installed
sudo apt-get install -y postgresql-9.5

echo Creating the user dhis
# This requires a password response from the user
sudo su - postgres -c "
createuser -SDRP dhis
"

# TODO: change this to read from the config file
sudo -u postgres psql -c '
ALTER USER dhis WITH PASSWORD $postgres_password
'

echo creating the database dhis2
sudo su - postgres -c "
createdb -O dhis dhis2
"
