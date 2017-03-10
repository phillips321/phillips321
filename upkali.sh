#!/bin/bash
#__________________________________________________________
# Author:     phillips321 contact through phillips321.co.uk
# License:    CC BY-SA 3.0
# Use:        Kali update script
# Released:   www.phillips321.co.uk
  version=0.2
# ToDo:
# 	add more tools
# ChangeLog:
#	v0.1 - First write
#	v0.2 - Additional commands added by 2bitwannabe

# Program
/etc/init.d/nessusd stop
apt-get clean
apt-get update
apt-get dist-upgrade -y
/opt/nessus/sbin/nessuscli update --all
/etc/init.d/nessusd start
nmap --script-updatedb
exit 0
