# script-dhis2
script dhis2

## Automation of the process described here: https://docs.dhis2.org/2.25/en/implementer/html/install_server_setup.html

### Get ready to use the script

As root, or a sudo-privileged user, create a user "dhis"

```
sudo su -
adduser dhis
```

Select a password and enter nothing for the remaining fields.

Then:

```usermod -aG sudo dhis```

Skip the disabling of root login for now!

Log out of root and log in as dhis user:

```
exit
sudo su - dhis

```


If Git is not already installed and configured, make it so

```
sudo apt-get install git
git config --global user.name YOURNAME
git config --global user.email YOUREMAIL
```

As dhis user, clone this repo

```git clone https://github.com/devit-alima/script-dhis2.git```

If you already have a copy of the dhis.war file, place it in the folder ```~/script-dhis2```; this will avoid the necessity of downloading it anew for each device you install.

Step into the resulting folder and run the script! You will need to sit by and answer questions.

```
cd script-dhis2
./dhis2_install.sh
```

# Installation on Raspberry Pi 3
## This works but doesn't create a very powerful server! Use at your own risk!
 Setup DHIS on a fresh install of Raspbian Stretch Lite
 on a Raspberry Pi 3
 https://downloads.raspberrypi.org/raspbian_lite_latest
 Script assumes it is being run by a user called dhis with sudo privileges

# Utilisation:
- Buy Raspberry Pi 3, install Raspbian, get on wifi or Ethernet
  - Read the docs on their site https://www.raspberrypi.org/downloads/raspbian/
- Create a user called dhis with sudo privileges
  - sudo adduser dhis (when asked, use a sensible password)
  - sudo usermod -aG sudo dhis
- Reboot and log in as dhis
- Install git
  - sudo apt-get install git
- Clone this repo
  - git clone https://devit-alima/script-dhis2
- Run the script
  - cd /script-dhis2
  - ./rpi3_dhis2_install.sh
- Answer the questions (your user password,
    the password for database, time zone, etc)


- NOTE: On Raspbian Stretch, Postgres 9.5 is deprecated. The installation
    will complain, and suggest that you install 9.6. Please don't; we haven't
    had time to verify that this works! Unfortunately this means that the
    script needs user input in mid-stream to accept the installation of
    Postgresql 9.5.




