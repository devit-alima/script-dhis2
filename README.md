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





