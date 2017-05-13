#!/bin/bash
interface="eth0"
echo "[+]Pinging broadcast for nodes" ; LinkLocal=`ping6 -c 2 -I $interface ff02::1 | grep icmp_seq | cut -d" " -f4 | cut -d"%" -f 1 | sort -u`
echo "[+]Pinging broadcast for routers" ; RouterLocal=`ping6 -c 2 -I $interface ff02::2 | grep icmp_seq | cut -d" " -f4 | cut -d"%" -f 1 | sort -u`
echo "[+]ArpScanning local IPv4" ; ArpScan=`arp-scan -l -I $interface | grep -v packets | grep -v Interface | grep -v Starting | grep -v Ending | cut -f1,2`
printf "%40s %18s %16s %7s\n" "IPV6Address" "MACAddress" "IPV4Address" "IsRouter" 
for IPV6Address in ${LinkLocal}; do
    MACAddress=`atk6-address6 ${IPV6Address} 2>/dev/null`
    if [ ! -z ${MACAddress} ]; then IPV4Address=`echo "${ArpScan}" | grep ${MACAddress} | cut -f1`
    else MACAddress="Unknown";IPV4Address="Unknown" ; fi
    if [ -z ${IPV4Address} ]; then IPV4Address="PossiblyYou?" ;fi
    if (echo "$RouterLocal" | grep -q ${IPV6Address}) ; then IsRouter="ROUTER"; else IsRouter="Node" ; fi
    #echo "${IPV6Address} - ${MACAddress} - ${IPV4Address} ${IsRouter}"
    printf "%40s %18s %16s %6s\n" ${IPV6Address} ${MACAddress} ${IPV4Address} ${IsRouter} 
done