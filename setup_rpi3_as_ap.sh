#!/bin/bash

# Installs the appropriate software and configures a Raspberry PI 3
# as an Access Point (AP) using hostapd and dnsmasq
# partially following https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/

set -e

sudo apt-get install hostapd dnsmasq

sudo cat <<EOT >> /etc/dhcpcd.conf
denyinterfaces wlan0
EOT
