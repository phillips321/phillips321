#!/bin/bash

interface="eth0"
LinkLocal=`ping6 -c 2 -I $interface ff02::1 | grep icmp_seq | cut -d" " -f4 | cut -d"%" -f 1 | sort -u`
RouterLocal=`ping6 -c 2 -I $interface ff02::2 | grep icmp_seq | cut -d" " -f4 | cut -d"%" -f 1 | sort -u`
ArpScan=`arp-scan -l -I $interface | grep -v packets | grep -v Interface | grep -v Starting | grep -v Ending | cut -f1,2`

echo "$ArpScan"

for IPV6Address in ${LinkLocal}; do
    MACAddress=`atk6-address6 ${IPV6Address} 2>/dev/null`
    if [ ! -z ${MACAddress} ]; then IPV4Address=`echo "${ArpScan}" | grep ${MACAddress} | cut -f1`
    else MACAddress="Unknown";IPV4Address="Unknown" ; fi
    if (echo "$RouterLocal" | grep -q ${IPV6Address}) ; then IsRouter="- ROUTER"; fi
    echo "${IPV6Address} - ${MACAddress} - ${IPV4Address} ${IsRouter}"
done