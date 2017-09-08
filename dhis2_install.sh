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

echo Modifying postgresql.conf
if [ ! -f /etc/postgresql/9.5/main/postgresql.conf.BAK ]; then
    # Create a backup
    sudo cp /etc/postgresql/9.5/main/postgresql.conf \
       /etc/postgresql/9.5/main/postgresql.conf.BAK
    # Substitute in the appropriate strings in the envfile using sed
    # syntax sed -i "s/ORIGINAL/REPLACEMENT/"
    # replaces only the first instance of ORIGINAL with REPLACEMENT

    sudo sed -i "s/max_connections*/max_connections = 200#/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "s/shared_buffers*/shared_buffers = 3200MB#/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "s/maintenance_work_mem*/maintenance_work_mem = 512MB#/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "s/effective_cache_size*/effective_cache_size = 800MB#/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "s/checkpoint_completion_target*/checkpoint_completion_target = 0.8#/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "s/synchronous_commit*/synchronous_commit = off#/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "s/wal_writer_delay*/wal_writer_delay = 10000ms#/" /etc/postgresql/9.5/main/postgresql.conf
    
else echo looks like postgresql.conf has already been modified
fi

echo restarting postgres
sudo /etc/init.d/postgresql restart


