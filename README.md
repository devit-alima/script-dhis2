# script-dhis2
script dhis2

## Automation of the process described here: https://docs.dhis2.org/2.25/en/implementer/html/install_server_setup.html

## First create a user "dhis"

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

 