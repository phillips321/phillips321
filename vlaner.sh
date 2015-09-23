#/bin/bash
#__________________________________________________________
# Author:     phillips321 contact through phillips321.co.uk
# License:    CC BY-SA 3.0
# Use:        Quicky configure VLANs on Kali
# Released:   www.phillips321.co.uk
  version=0.2
# Dependencies:
#	vlan

f_multi(){ #add multiple VLANS
	echo "[+] Performing a multi VLAN setup"
	for line in `cat ${1}`; do
		echo ${line}
		echo "next"
		mode=`echo ${line} | cut -d" " -f1`
		vlanid=`echo ${line} | cut -d" " -f2`
		interface=`echo ${line} | cut -d" " -f3`
		ipadd=`echo ${line} | cut -d" " -f4`
		#echo ${mode} ${vlanid} ${interface} ${ipadd}
		if [[ ${mode} = "add" ]] ; then
			f_addvlan
		elif [[ ${mode} = "del" ]] ; then
			f_delvlan
		fi
	done
}
f_delvlan(){ #delete vlan
	echo "[+] Deleting VLAN"
	/sbin/ifconfig vlan${vlanid} down
	/sbin/vconfig rem vlan${vlanid}
}
f_addvlan(){ #add vlan
	echo "[+] Adding VLAN"
	/sbin/vconfig add ${interface} ${vlanid}
	/sbin/ifconfig ${interface}.${vlanid} ${ipadd}
}
f_usage(){ #echo usage
	#						$1					$2			$3		   $4
	echo "[+] -------------- vlaner.sh v${1}"
	echo "[+] Usage: $0 [add/del/multi] [vlan_id] [interface] [ipaddress]"
	echo "[+] Example: $0 add 100 eth1 192.168.100.10/24"
	echo "[+] Example: $0 del 100"
	echo "[+] Example: $0 multi"
	echo "[+] Example config.txt-------------------"
	echo "    add 10 eth1 192.168.0.20/24"
	echo "    add 20 eth2 10.20.102.45/24"
	echo "    add 30 eth1 172.16.50.12/24"
	echo "[+] -------------------------------------"
	f_exit
}
f_setup(){ #configure new line chars
	OLDIFS=${IFS}
	IFS=''
}
f_exit(){ #exit program after fix IFS
	IFS=${OLDIFS}
	exit 0
}

f_setup
if [[ ${1} = "" ]] ; then
	f_usage
else
	mode=$1
	vlanid=$2
	interface=$3
	ipadd=$4
	echo ${1} ${2} ${3} ${4}
fi

if [[ ${mode} = "del" ]] ; then 
	f_delvlan
elif [[ ${mode} = "add" ]] ; then
	f_addvlan
elif [[ -f ${mode} ]] ; then
	f_multi
fi
f_exit
