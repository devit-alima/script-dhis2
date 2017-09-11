#!/bin/bash

# Setup DHIS on a fresh install of Ubuntu 16.04
# Script assumes it is being run by a user called dhis with sudo privileges
# on a Raspberry Pi 3 B running Debian Stretch Lite

echo updating
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y autoremove

echo *************************************************
echo
echo *************************************************
echo
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
ALTER USER dhis WITH PASSWORD '$postgres_password'
"

echo creating the database dhis2
sudo su - postgres -c "
createdb -O dhis dhis2
"

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

sudo apt-get -y install default-jdk

echo installing Tomcat 7
sudo apt-get -y install tomcat7-user
sudo apt-get autoremove

echo creating tomcat instance for DHIS
tomcat7-instance-create /home/dhis/tomcat-dhis

# Small heap memory settings for Java due to 1GB total system memory
echo adding environment variable setting to tomcat setenv.sh file
sudo cat <<EOT >> /home/dhis/tomcat-dhis/bin/setenv.sh
export JAVA_HOME='/usr/lib/jvm/java-8-openjdk-armhf/'
export JAVA_OPTS='-Xmx256m -Xms128m'
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
