#!/bin/bash
#__________________________________________________________
# Author:     phillips321 contact through phillips321.co.uk
# License:    CC BY-SA 3.0
# Use:        ipv6 finder
# Released:   www.phillips321.co.uk
  version=0.3
# Dependencies:
#	arp-scan

# ToDo:
#	add ability to nmap IPv4/6 and diff services

f_main(){
    #Ping broadcast address for local neighbours and store as LinkLocalNeighbours
    echo -n "[+]Pinging (ff02::1) broadcast for nodes" ; 
        for ((n=0;n<${loops};n++)); do 
            LinkLocalNeighbours=`ping6 -c 2 -I $interface ff02::1 | grep icmp_seq | cut -d" " -f4 | cut -d"," -f 1 | sort -u` ; echo -n "."
        done; echo "Done"    

    #Ping broadcast address for router neighbours and store as RouterLocalNeighbours
    echo -n "[+]Pinging (ff02::2) broadcast for routers"
        for ((n=0;n<${loops};n++)); do
            RouterLocalNeighbours=`ping6 -c 2 -I $interface ff02::2 | grep icmp_seq | cut -d" " -f4 | cut -d"," -f 1 | sort -u` ; echo -n "."
        done; echo "Done"
    
    echo -n "[+]ArpScanning local IPv4"
    ArpScan=`arp-scan -l -I $interface | grep -v packets | grep -v Interface | grep -v Starting | grep -v Ending | cut -f1,2 | sed 's/0\([0-9A-Fa-f]\)/\1/g'`
    
    echo ".Done"


    echo "--------------------------------|--------------------|------------------|-------------"
    printf "%31s %1s %18s %1s %16s %1s %12s\n" "IPV6Address" "|" "MACAddress" "|" "IPV4Address" "|" "Info" 
    echo "--------------------------------|--------------------|------------------|-------------"
    for IPV6Address in ${LinkLocalNeighbours}; do
        #Get MAC from NDP table
        if [ "$(uname)" == "Darwin" ]; then #must be OS X
            MACAddress=`ndp -nl ${IPV6Address} | grep ${IPV6Address} | awk '{print $2}'`
        else #must be Linux/Cywin?
            MACAddress=`ip -6 neigh show $(echo ${IPV6Address} | cut -d"%" -f1) | awk {'print $5'} | sed 's/0\([0-9A-Fa-f]\)/\1/g'`
            if [ -z ${MACAddress} ] ; then MACAddress=`cat /sys/class/net/${interface}/address`; fi
        fi

        #Use MAC to pair up with IPv4 address
        if [ ! -z ${MACAddress} ]; then IPV4Address=`echo "${ArpScan}" | grep ${MACAddress} | cut -f1` ; fi

        #IPv4 not found so might be you or not in subnet?
        if [ -z ${IPV4Address} ]; then #Unable to find IPv4 so possibly you
            if [ "$(uname)" == "Darwin" ]; then #must be OS X
                IPV4Address=`arp -anl | grep ${MACAddress} | awk '{print $1}'`
            else #must be Linux/Cywin?
                IPV4Address=`ifconfig ${interface} | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
            fi
            Info="You"
        else #IPv4 found so now decididng if router or not
            if (echo "$RouterLocalNeighbours" | grep -q ${IPV6Address}) ; then Info="Router"; else Info="Node" ; fi
        fi
        if [ -z ${IPV4Address} ]; then IPV4Address="NotFound" ; Info="IPv6only?" ; fi
        printf "%31s %1s %18s %1s %16s %1s %12s\n" ${IPV6Address} "|" ${MACAddress} "|" ${IPV4Address} "|" ${Info} 
    done
    echo "--------------------------------|--------------------|------------------|-------------"
}

f_usage(){ #echo usage
	echo "[+] ipv6finder.sh v${version}"
	echo "[+] Usage: ipv6finder.sh [interface] [loops]"
	echo "[+] Example: ipv6finder.sh eth0 5"
    exit 1
}

if [[ $1 = "" ]] ; then
	f_usage
else
	interface=$1
    if [[ $2 < 2 ]] ; then loops=5 ; else loops=$2 ; fi
fi

f_main
exit 0
