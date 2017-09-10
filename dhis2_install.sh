#!/bin/bash

# Setup DHIS on a fresh install of Ubuntu 16.04
# Script assumes it is being run by a user called dhis with sudo privileges

echo updating
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y autoremove

echo What password do you want for your postgres user?
read postgres_password

if [ ! -d /home/dhis/config ]; then
    echo creating configuration folder
    mkdir /home/dhis/config
else echo configuration folder is already created
fi

# Set the time zone - this requires user input - to be automated
echo setting time zone to server location
sudo dpkg-reconfigure tzdata
locale -a
sudo locale-gen nb_NO.UTF-8

# TODO - check if Postgres 9.5 is already installed
sudo apt-get install -y postgresql-9.5

echo Creating the Postgresql user dhis
sudo su - postgres -c "
createuser -sdr dhis
"

echo Setting the password for the Postgres user dhis
sudo -u postgres psql -c "
ALTER USER dhis WITH PASSWORD 'dhis'
"
#sudo -u postgres psql -c "
#ALTER USER dhis WITH PASSWORD '$postgres_password'
#"

echo creating the database dhis2
sudo su - postgres -c "
createdb -O dhis dhis2
"

echo Modifying postgresql.conf
if [ ! -f /etc/postgresql/9.5/main/postgresql.conf.BAK ]; then
    # Create a backup
    sudo cp /etc/postgresql/9.5/main/postgresql.conf \
       /etc/postgresql/9.5/main/postgresql.conf.BAK
    # Substitute in the appropriate strings in the postgres file using sed
    # syntax sed -i "0,/ORIGINAL/s/ORIGINAL/REPLACEMENT/"
    # replaces only the first instance of ORIGINAL with REPLACEMENT

    sudo sed -i "0,/max_connections/s/max_connections/max_connections = 200 #/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "0,/shared_buffers/s/shared_buffers/shared_buffers = 3200MB #/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "0,/#work_mem/s/#work_mem/work_mem = 20MB #/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "0,/#maintenance_work_mem/s/#maintenance_work_mem/maintenance_work_mem = 512MB #/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "0,/#effective_cache_size/s/#effective_cache_size/effective_cache_size = 800MB #/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "0,/#checkpoint_completion_target/s/#checkpoint_completion_target/checkpoint_completion_target = 0.8 #/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "0,/#synchronous_commit/s/#synchronous_commit/synchronous_commit = off #/" /etc/postgresql/9.5/main/postgresql.conf
    sudo sed -i "0,/#wal_writer_delay/s/#wal_writer_delay/wal_writer_delay = 10000ms #/" /etc/postgresql/9.5/main/postgresql.conf

else echo looks like postgresql.conf has already been modified
fi

echo restarting postgres
sudo /etc/init.d/postgresql restart

sudo apt-get install -y postgresql-9.5 postgresql-9.5-postgis-2.2 postgresql-contrib-9.5

if [ ! -f /home/dhis/config/dhis.conf ]; then
    echo creating dhis.conf
    cat >> /home/dhis/config/dhis.conf <<EOF
# Hibernate SQL dialect
connection.dialect = org.hibernate.dialect.PostgreSQLDialect

# JDBC driver class
connection.driver_class = org.postgresql.Driver

# Database connection URL
connection.url = jdbc:postgresql:dhis2

# Database username
connection.username = dhis

# Database password
connection.password = $postgres_password

# Database schema behavior, can be validate, update, create, create-drop
connection.schema = update

# Encryption password (sensitive)
encryption.password = $postgres_password
EOF
else Looks like dhis.conf has already been created.     
fi

echo Setting permission on dhis.conf file
sudo chmod 0600 /home/dhis/config/dhis.conf

echo silent install of Oracle Java 8
sudo apt-get install -y python-software-properties debconf-utils
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
sudo apt-get install -y oracle-java8-installer

#echo setting up Oracle Java repos and installing Java8
#sudo add-apt-repository -y ppa:webupd8team/java
#sudo apt-get -y update
#sudo apt-get -y install oracle-java8-installer

#sudo apt-get -y install default-jdk

echo installing Tomcat 7
sudo apt-get -y install tomcat7-user
sudo apt-get autoremove

echo creating tomcat instance for DHIS
tomcat7-instance-create /home/dhis/tomcat-dhis

echo adding environment variable setting to tomcat setenv.sh file
sudo cat <<EOT >> /home/dhis/tomcat-dhis/bin/setenv.sh
export JAVA_HOME='/usr/lib/jvm/java-8-oracle/'
export JAVA_OPTS='-Xmx7500m -Xms4000m'
export DHIS2_HOME='/home/dhis/config'
EOT

# TODO make sure we do not need to mess with Tomcat connector port settings

if [ ! -f dhis.war ]; then
    echo fetching the DHIS2 WAR file
    wget https://www.dhis2.org/download/releases/2.27/dhis.war
else echo DHIS2 WAR file has already been downloaded
fi

echo copying the DHIS war file into the tomcat-dhis webapps folder
sudo cp dhis.war /home/dhis/tomcat-dhis/webapps/ROOT.war

echo starting service
/home/dhis/tomcat-dhis/bin/startup.sh
