#!/bin/bash
#__________________________________________________________
# Author:     phillips321 contact through phillips321.co.uk
# License:    CC BY-SA 3.0
# Use:        Looks through *.gnmap output for port and outputs IPs
# Released:   www.phillips321.co.uk
  version=0.1
# ToDo:
#	nothing yet
# ChangeLog:
#	v0.1 - First write
#___________________________________________________________
if [ -z ${1} ] ; then echo -e "Usage: $0 [port] \n Example: $0 80" ; exit 1 ; fi
cat *.gnmap | grep "\ ${1}/open" | cut -d" " -f2 | sort | uniq

#for i in `cat open_ports.txt | grep open | grep -v http | grep -v "OS\ CPE" | grep -v fingerprint | grep -v "|" | cut -f1 -d"/" | sort | uniq | sort -n`
#do
#	echo "$i was open on the following IPs---------------" #>> portlist.txt
	#cat *.gnmap | grep "\ ${i}/open" | cut -d" " -f2 | sort | uniq
#	if [ `cat *.gnmap | grep "\ ${i}/open" | cut -d" " -f2 | sort | uniq | wc -l` -ge 2 ] ; then echo "more than 2 found" ; fi  #>> portlist.txt
#done
exit 0
