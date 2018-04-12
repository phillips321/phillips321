#!/bin/bash
#__________________________________________________________
# Author:     phillips321 contact through phillips321.co.uk
# License:    CC BY-SA 3.0
# Use:        ipv6 finder
# Released:   www.phillips321.co.uk
  version=0.7
# Dependencies:
#	arp-scan
# ChangeLog
#   v0.7    Incremented version numbers properly - whoops!
#   v0.6    Added bug where arp-scan comes back with Duplicates (DUP)
#   v0.5    Checks if there is a local Global IPv6 Address
#   v0.4    Added Global host discovery
# ToDo:
#	use MAC address as unique key

f_main(){
    #Ping broadcast address for local neighbours and store as LinkLocalNeighbours
    echo -n "[+]Pinging (ff02::1) broadcast for nodes on link local"
    LinkLocalNeighbours=`ping6 -c 3 -I ${interface} ff02::1 | grep icmp_seq | cut -d" " -f4 | cut -d"," -f 1 | sort -u` ; echo -n "."
    echo "Done"

    #Ping broadcast address for router neighbours and store as RouterLocalNeighbours
    echo -n "[+]Pinging (ff02::2) broadcast for routers"
    RouterLocalNeighbours=`ping6 -c 3 -I ${interface} ff02::2 | grep icmp_seq | cut -d" " -f4 | cut -d"," -f 1 | sort -u` ; echo -n "."
    echo "Done"

    #Ping broadcast address for global neighbours and store as GlobalNeighbours
    echo -n "[+]Pinging (ff02::1) broadcast for nodes on Global Interface" ;
        if [ "$(uname)" == "Darwin" ]; then #must be OS X
            IPV6Address=`ifconfig ${interface} | grep inet6 | grep -v fe80 | grep -v temporary | grep -v "::1" | awk {'print $2'}`
            if [ ! -z ${IPV6Address} ]; then
                GlobalNeighbours=`ping6 -c 3 -I ${interface} -S ${IPV6Address} ff02::1 | grep icmp_seq | cut -d" " -f4 | cut -d"," -f 1 | sort -u` ; echo -n "."
                { for i in ${GlobalNeighbours} ; do ping6 -c 1 -I ${interface} $i ; done } &> /dev/null
            else
                IPV6Address=""; GlobalNeighbours=""
            fi
        else #must be Linux/Cywin?
            IPV6Address=`ip addr | grep inet6 | grep -v "::1" | grep -v fe80 | grep -v "temporary" | awk {'print $2'} | cut -d"/" -f1`
            if [ ! -z ${IPV6Address} ]; then
                GlobalNeighbours=`ping6 -c 3 -I ${IPV6Address} ff02::1 | grep icmp_seq | cut -d" " -f4 | cut -d"," -f 1 | sort -u | rev | cut -c 2- | rev` ; echo -n "."
                { for i in ${GlobalNeighbours} ; do ping6 -c 1 -I ${interface} $i ; done } &> /dev/null
            else
                IPV6Address=""; GlobalNeighbours=""
            fi
        fi
    echo "Done"

    echo -n "[+]ArpScanning local IPv4"
    ArpScan=`arp-scan -l -I ${interface} | grep -v packets | grep -v DUP | grep -v ${interface} | grep -v Starting | grep -v Ending | cut -f1,2`
    echo ".Done"

    echo "--------------------------------|------------------------------------------|--------------------|--------------------|-------------"
    printf "%31s %1s %40s %1s %18s %1s %18s %1s %12s\n" "IPV6 Link Local" "|" "IPV6 Global" "|" "MAC Address" "|" "IPV4Address" "|" "Info"
    echo "--------------------------------|------------------------------------------|--------------------|--------------------|-------------"
    for IPV6LL in ${LinkLocalNeighbours}; do
        #Get LinkLocal MAC from NDP table
        if [ "$(uname)" == "Darwin" ]; then #must be OS X
            ShortMAC=`ndp -nl ${IPV6LL} | grep ${IPV6LL} | awk '{print $2}'`
            LongMAC=`echo ${ShortMAC} | awk -F: '{printf("%02s:%02s:%02s:%02s:%02s:%02s",$1,$2,$3,$4,$5,$6)}' ; echo ""`
        else #must be Linux/Cywin?
            ShortMAC=`ip -6 neigh show $(echo ${IPV6LL} | head -n1 | cut -d"%" -f1) | awk {'print $5'} | sed 's/0\([0-9A-Fa-f]\)/\1/g'`
            LongMAC=`ip -6 neigh show $(echo ${IPV6LL} | head -n1 | cut -d"%" -f1) | awk {'print $5'}`
            if [ -z ${ShortMAC} ] ; then ShortMAC=`cat /sys/class/net/${interface}/address | sed 's/0\([0-9A-Fa-f]\)/\1/g'`; fi
            if [ -z ${LongMAC} ] ; then LongMAC=`cat /sys/class/net/${interface}/address`; fi
        fi

        #Use MAC to pair up with IPv4 address and global IPv6
        if [ ! -z ${ShortMAC} ]; then
            IPV4Address=`echo "${ArpScan}" | grep "${LongMAC}" | head -n1 | cut -f1`
            IPV6G=""
            if [ "$(uname)" == "Darwin" ]; then #must be OS X
                IPV6G=`ndp -anl | grep ${ShortMAC} | grep -v fe80 | awk {'print $1'} | tail -n 1`
            else #must be Linux/Cywin?
                IPV6G=`ip -6 neigh show | grep "${LongMAC}" | grep -v fe80 | awk {'print $1'} | head -n 1`
            fi
            if [ -z ${IPV6G} ]; then IPV6G="NotFound" ; fi
        fi

        #read -n 1 -s -r -p "${IPV6LL} ${IPV4Address} ${ShortMAC} ${LongMAC}" ; echo "" #DEBUG LINE

        #IPv4 not found so might be you or not in subnet?
        if [ -z ${IPV4Address} ]; then #Unable to find IPv4 so possibly you
            if [ "$(uname)" == "Darwin" ]; then #must be OS X
                #IPV4Address=`arp -anl | grep ${ShortMAC} | awk '{print $1}'` #commented out on 10/08/2017 due to bug
                IPV4Address=`ifconfig ${interface} | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
            else #must be Linux/Cywin?
                IPV4Address=`ifconfig ${interface} | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
            fi
            Info="You?"
        else #IPv4 found so now decididng if router or not
            if (echo "$RouterLocalNeighbours" | grep -q ${IPV6LL}) ; then Info="Router"; else Info="Node" ; fi
        fi
        if [ -z ${IPV4Address} ]; then IPV4Address="NotFound" ; Info="IPv6only?" ; fi
        if [[ ${LongMAC} == *"incomplete"* ]]; then LongMAC="00:00:00:00:00:00" ; fi
        printf "%31s %1s %40s %1s %18s %1s %18s %1s %12s\n" ${IPV6LL} "|" ${IPV6G} "|" ${LongMAC} "|" ${IPV4Address} "|" ${Info}
    done
    echo "--------------------------------|------------------------------------------|--------------------|--------------------|-------------"
}

f_usage(){ #echo usage
	echo "[+] ipv6finder.sh v${version}"
	echo "[+] Usage: ipv6finder.sh [{interface}]"
	echo "[+] Example: ipv6finder.sh eth0"
  exit 1
}

hash arp-scan 2>/dev/null || { echo >&2 "[+] I require arp-scan but it's not installed.  Aborting."; exit 1; }

if [[ $1 = "" ]] ; then
	f_usage
else
	interface=$1
fi

f_main
exit 0
