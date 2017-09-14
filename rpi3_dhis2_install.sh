#!/bin/bash

# Setup DHIS on a fresh install of Raspbian Stretch Lite
# on a Raspberry Pi 3
# https://downloads.raspberrypi.org/raspbian_lite_latest
# Script assumes it is being run by a user called dhis with sudo privileges
#
# Utilisation:
# - Buy Raspberry Pi 3, install Raspbian, get on wifi or Ethernet
# - Create a user called dhis with sudo privileges
#   - sudo adduser dhis (when asked, use a sensible password)
#   - sudo usermod -aG sudo dhis
# - Reboot and log in as dhis
# - Install git
#   - sudo apt-get install git
# - Clone this repo
#   - git clone https://devit-alima/script-dhis2
# - Run the script
#   - cd /script-dhis2
#   - ./rpi3_dhis2_install.sh
# - Answer the questions (your user password,
#     the password for database, time zone, etc)


# - NOTE: On Raspbian Stretch, Postgres 9.5 is deprecated. The installation
#     will complain, and suggest that you install 9.6. Please don't; we haven't
#     had time to verify that this works! Unfortunately this means that the
#     script needs user input in mid-stream to accept the installation of
#     Postgresql 9.5.


set -e

echo 
echo
echo What password do you want for your postgres user?
read postgres_password

if [ ! -d /home/dhis/config ]; then
    echo creating configuration folder
    mkdir /home/dhis/config
else echo configuration folder is already created
fi

# Set the time zone - this requires user input - to be automated
echo
echo setting time zone to server location
sudo dpkg-reconfigure tzdata
locale -a
sudo locale-gen nb_NO.UTF-8

echo updating and upgrading the distribution
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y autoremove

# TODO - check if Postgres 9.5 is already installed
# Complains and asks for user agreement
echo installing Postgresql 9.5
echo this will complain about deprecated version and ask for 9.6,
echo please accept the installion of 9.5 and proceed
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

echo
echo restarting postgres
sudo /etc/init.d/postgresql restart

echo installing postgres utilities
sudo apt-get install -y postgresql-9.5 postgresql-contrib-9.5

echo
echo creating dhis.conf file
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

echo Installing Oracle Java
sudo apt-get install oracle-java8-jdk

echo installing Tomcat 8
sudo apt-get -y install tomcat8-user
sudo apt-get autoremove

echo creating tomcat instance for DHIS
tomcat8-instance-create /home/dhis/tomcat-dhis

echo adding environment variable setting to tomcat setenv.sh file
sudo cat <<EOT >> /home/dhis/tomcat-dhis/bin/setenv.sh
export JAVA_HOME='/usr/lib/jvm/jdk-8-oracle-arm32-vfp-hflt/'
export JAVA_OPTS='-Xmx384m -Xms128m'
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

# Starting Tomcat at boot time

echo checking if tomcat.sh startup script has been created yet
if [ ! -f /home/dhis/config/tomcat.sh ]; then
echo creating tomcat.sh startup script for startup at boot time
    cat >> /home/dhis/config/tomcat.sh <<'EOF'
#!/bin/sh
#Tomcat init script

case $1 in
start)
        sh /home/dhis/tomcat-dhis/bin/startup.sh
        ;;
stop)
        sh /home/dhis/tomcat-dhis/bin/shutdown.sh
        ;;
restart)
        sh /home/dhis/tomcat-dhis/bin/shutdown.sh
        sleep 5
        sh /home/dhis/tomcat-dhis/bin/startup.sh
        ;;
esac
exit 0
EOF
else something went wrong     
fi

echo copying tomcat.sh startup script to /etc/init.d
sudo cp /home/dhis/config/tomcat.sh /etc/init.d

echo making tomcat.sh startup script executable
sudo chmod +x /etc/init.d/tomcat.sh

echo updating rc.d to run tomcat.sh on boot
sudo update-rc.d -f tomcat.sh defaults 81
