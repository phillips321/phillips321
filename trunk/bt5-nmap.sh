#!/bin/bash
#__________________________________________________________
# Author:     phillips321 contact through phillips321.co.uk
#						  Rich Hicks	contact through about.me/r.hicks
# License:    CC BY-SA 3.0
# Use:        Update several applications
# Released:   www.phillips321.co.uk
  version=1.5
# Dependencies:
# 			nmap
# 			sslscan
# 			gnome-web-photo
# 			arp-scan
# debian users can apt-get install nmap sslscan gnome-web-photo arp-scan
# 
# ToDo:
# 			Use watch instead of looping a #process left message
# 			Use a nice output to show status of scans and what has been complete
# 			Allow changing of THREADS on fly by reading THREADS from file
#
# ChangeLog:
#			v1.5 fixed the WeakCiphers file appearing all the time, also added a new targeting function to allow for pre-existing targets.txt files.
#			v1.4 fixed the "host alive" check flag and usage.
#			v1.3 fixed some issues relating to the directory creation and the script after the initial nmap.
#			v1.2 added timeout and width option to gnome-web-photo
#			v1.1 added UDP custom and added NMAPUDP command string as f_uservariable()
#			v1.0 Migrated from bt5-nmap.sh --> gt-nmap.sh and improved layout using functions
#___________________________________________________________

f_uservariables(){
	CUSTOMPORTS="21,22,23,80,443,445,3389"  #seperate with a comma e.g. CUSTOMPORTS="21,22,23,80,443,445,3389" 
	NMAPTCP="nmap -sS -vv -d -A -Pn -n -r -oA"
	NMAPUDP="nmap -sU -vv -d -A -Pn -n -r -oA"

}
f_usage(){		#outputs usage information
		echo "MESSAGE: bt5-nmap.sh ${version}"
		echo "MESSAGE: Usage: `basename ${0}` [threads max = 99] [big/small/both/custom] [directory]"
		echo "MESSAGE: # `basename ${0}` 5 small VLANxyz"
		echo "MESSAGE: if scan size not given i will scan all ports"
		echo "MESSAGE: if directory is not given then I will write to ./devices/"
		echo "MESSAGE:"
}
f_yesorno(){	#returns 1 if yes is selected
	read -e CONFIRM
	case $CONFIRM in
		y|Y|YES|yes|Yes)
			return 1 ;;
		*)
			return 0 ;;
	esac
}
f_rootcheck(){	#checks for root and exits if not
	if [ `echo -n $USER` != "root" ]
	then
		echo "MESSAGE: bt5-nmap.sh ${VERSION}"
		echo "MESSAGE: ERROR: Please run as root!"
		echo "MESSAGE:"
		exit 1
	fi
}
f_threadcheck(){	#checks input for num of threads
	if [ -z ${1} ]
	then
		f_usage
		exit 1
	fi
	THREADS="`echo "${1}" | tr -cd '[:digit:]' | cut -c 1-2`"
}
f_scansizecheck(){	#checks input for type of scan
	if [ ${1} = "big"  ] || [ ${1} = "small" ] || [ ${1} = "both" ] || [ ${1} = "custom" ]
	then
		SIZETYPE="`echo "${1}" | tr -cd '[:alnum:]' | cut -c 1-6`"
		echo "MESSAGE: performing a ${SIZETYPE} scan"
	else
		SIZETYPE="both"
		echo "MESSAGE: no scan size given or its invalid so scan size will be both(small and big)."
	fi	
}
f_directorycheck(){	#checks input for directory name to save to
	if [ -z ${1} ]
	then
		DIRECTORY="devices"
		echo "MESSAGE: no dir given so outputting to ${DIRECTORY}"
	else
		DIRECTORY="`echo "${1}" | tr -cd '[:graph:]'`" 
		echo "MESSAGE: output dir = ${DIRECTORY}"
	fi
}
f_outputtargets(){	#cats targets.txt to screen
	echo "MESSAGE: targets.txt contents:"
	cat targets.txt
	echo "MESSAGE: end of IPs/Hosts"
}
f_arpscansubnet(){	#arpscans local subnet
	arp-scan -l -g | grep . | cut -f1 | grep -v packets |grep -v Interface | grep -v Ending | grep -v Starting > targets.txt
}
f_createtargetstxt(){ #Creates a targets.txt file
	if [[ -f ./targets.txt ]]; then
		echo -n "Message: Edit Existing? (Yes/No) : "
		f_yesorno \
			&& (echo "Message: Now arp-scanning current subnet"; f_arpscansubnet) \
			|| (nano targets.txt)
	else
		echo "Message: Now arp-scanning current subnet"; f_arpscansubnet
	fi
		echo "Message: We found `cat targets.txt | wc -l` targets"
		f_outputtargets
		echo -n "Message: Do you wish to edit this list (DELETE YOURSELF!) yes/no : "
		f_yesorno && echo "Message: Chose not to edit... Continue with scan" || nano targets.txt ; f_outputtargets
}

f_findtargetstxt(){	#checks for targets.txt and offer to create
	if [ -f ./targets.txt ]
	then
		echo "MESSAGE: targets.txt file located"
		f_outputtargets
		echo -n "MESSAGE: is the above listing correct? yes/no : "
		f_yesorno \
			&& f_createtargetstxt \
			|| (echo "MESSAGE: Listing is correct, continue with scan")
	else
		echo -n "MESSAGE: there is no targets.txt file so do you want me to create one? yes/no : "
		f_yesorno && exit 0
		f_createtargetstxt
#		echo "MESSAGE: Now arp-scanning current subnet"
#		f_arpscansubnet
#		echo "MESSAGE: We found `cat targets.txt | wc -l` targets and have output them to targets.txt"
#		f_outputtargets
#		echo -n "MESSAGE: Do you wish to edit this list? (DELETE YOURSELF!)yes/no : "
#		f_yesorno && echo "MESSAGE: Chose not to edit.....continue with scan" || nano targets.txt ; f_outputtargets
	fi
}
f_numberoftargets(){ #counts number of targets in targets.txt
	NUMBER=`wc -l targets.txt`
	COUNT=0
	echo "MESSAGE: Found ${NUMBER} targets to scan"
}
f_createdirectory(){ #makes the directory
	mkdir -p "${1}"
	cp targets.txt "${1}/"
}
f_nmapscans(){	#performs loops of nmap scans
	echo "MESSAGE: Starting Scan with ${THREADS} threads"
	for i in `cat targets.txt`
	do
		TARGET=${i}
		LOC=${DIRECTORY}/${TARGET}
		((COUNT++))
		echo "MESSAGE: now scanning ${TARGET} ${COUNT} of ${NUMBER}"
		case ${SIZETYPE} in
			small) xterm -title "${TARGET} small TCP" -e "${NMAPTCP} ${LOC}.small.tcp ${TARGET}" & ;;
			both) xterm -title "${TARGET} small TCP" -e "${NMAPTCP} ${LOC}.small.tcp ${TARGET}" &
				xterm -title "${TARGET} big TCP" -e "${NMAPTCP} ${LOC}.big.tcp -p1-65535 ${TARGET}" & ;;
			big) xterm -title "${TARGET} big TCP" -e "${NMAPTCP} ${LOC}.big.tcp -p1-65535 ${TARGET}" & ;;
			custom) xterm -title "${TARGET} custom TCP" -e "${NMAPTCP} ${LOC}.custom.tcp -p${CUSTOMPORTS} ${TARGET}" & ;;
		esac
		case ${SIZETYPE} in
			custom) xterm -title "${TARGET} custom UDP" -e "${NMAPUDP} ${LOC}.custom.udp -p${CUSTOMPORTS} ${TARGET}" & ;;
			*) xterm -title "${TARGET} small UDP" -e "${NMAPUDP} ${LOC}.small.udp ${TARGET}" & ;;
		esac
		
		while [ `ps -Aef --cols 200 | grep ${DIRECTORY} | grep xterm | wc -l` -ge ${THREADS} ]
			do
			sleep 5
		done
		sleep 5
	done
	while [ `ps -Aef --cols 200 | grep ${DIRECTORY} | grep xterm | wc -l` -gt 0 ]
	do
		echo MESSAGE: `ps -Aef --cols 200 | grep ${DIRECTORY} | grep xterm | wc -l`nmaps still running
		sleep 10
	done
	echo "MESSAGE: NMap Scanning Complete"
}
f_amapscans(){
	cd "${DIRECTORY}"
	for i in `ls *.gnmap | sed -e "s/.gnmap//"`
	do
		xterm -title "${i} AMAP" -e "amap -i ${i}.gnmap -o ${i}.amap | tee -a amap_full.txt" &
		echo "MESSAGE: now amaping ${i}"
		while [ `ps -Aef --cols 200 | grep AMAP | grep xterm | wc -l` -ge ${THREADS} ]
		do
			sleep 1
		done
		sleep 5
	done
	while [ `ps -Aef --cols 200 | grep AMAP | grep xterm | wc -l` -gt 0 ]
	do
		echo MESSAGE: `ps -Aef --cols 200 | grep AMAP | grep xterm | wc -l`amaps still running
		sleep 10
	done
	cat amap_full.txt | cut -d" " -f3,4,5 | grep matches | sort -n | uniq > amap.txt
	cat amap.txt | grep http | cut -d"/" -f 1 | sort | uniq > amap.http.txt
	cat amap.txt | grep ssl | cut -d"/" -f 1 | sort | uniq > amap.ssl.txt
	cd -
	echo "MESSAGE: Amaping Complete"
	sleep 5
}
f_sslscans(){
	cd "${DIRECTORY}"
	if [ -s amap.ssl.txt ] 
	then
		cat amap.ssl.txt
		for i in `cat amap.ssl.txt`
		do
			SSLOUT="`echo "${i}" | sed -e s/:/_/g`" 
			echo "MESSAGE: now sslscanning ${i} and outputting as ${SSLOUT}.sslscan.txt"
			xterm -title "${i} SSLSCAN" -e "sslscan --no-failed ${i} | tee ${SSLOUT}.sslscan.txt ; sleep 5" &
			while [ `ps -Aef --cols 200 | grep SSLSCAN | grep xterm | wc -l` -ge ${THREADS} ]
				do
						sleep 2
				done
		sleep 5
		done
		while [ `ps -Aef --cols 200 | grep SSLSCAN | grep xterm | wc -l` -gt 0 ]
		do
			echo MESSAGE: `ps -Aef --cols 200 | grep SSLSCAN | grep xterm | wc -l`sslscans still running
			sleep 10
		done
		cat *.sslscan.txt | grep "Testing\ SSL\|Accepted\|ERROR" | grep "SSLv2\|Testing\|\ 40\|\ 56" | grep -v "ERROR" > WeakCiphers.txt
		echo "MESSAGE: Auto SSLSCAN Complete"
	else
		echo "MESSAGE: sslscan will not run - no ssl ports found using amap"
	fi	
	sleep 5
	cd -
	

}
f_gwp(){
	cd "${DIRECTORY}"
	if [ -s amap.ssl.txt ] 
	then
		cat amap.ssl.txt
		for i in `cat amap.ssl.txt`
		do
			HTTPOUT="`echo "${i}" | sed -e s/:/_/g`" 
			echo "MESSAGE: now taking photo of https://${i} and outputting as ${HTTPOUT}_https.png"
			xterm -title "${i} GNOME-WEB-PHOTO" -e "gnome-web-photo -t 20 -w 1024 -m photo -f --format=png https://${i} ${HTTPOUT}_https.png" &
			while [ `ps -Aef --cols 200 | grep GNOME | grep xterm | wc -l` -ge ${THREADS} ]
			do
				sleep 5
			done
			sleep 5
		done
	else
		echo "MESSAGE: gnome-web-photo will not run - no https ports found using amap"
	fi
	if [ -s amap.http.txt ] 
	then
		cat amap.http.txt
		for i in `cat amap.http.txt`
		do
			HTTPOUT="`echo "${i}" | sed -e s/:/_/g`" 
			echo "MESSAGE: now taking photo of http://${i} and outputting as ${HTTPOUT}_http.png"
			xterm -title "${i} GNOME-WEB-PHOTO" -e "gnome-web-photo -m photo -f --format=png ${i} ${HTTPOUT}_http.png" &
			while [ `ps -Aef --cols 200 | grep GNOME | grep xterm | wc -l` -ge ${THREADS} ]
			do
				sleep 5
			done
			sleep 5
		done
	else
		echo "MESSAGE: gnome-web-photo will not run - no http ports found using amap"
	fi
	while [ `ps -Aef --cols 200 | grep GNOME | grep xterm | wc -l` -gt 0 ]
	do
		echo MESSAGE: `ps -Aef --cols 200 | grep GNOME | grep xterm | wc -l`screenshots still running
		sleep 10
	done
	sleep 5
	cd -
}
f_cleanup(){
	cd "${DIRECTORY}"
	for i in `ls *.png`
	do
		iSIZE=`stat -c %s ${i}`
		if [ ${iSIZE} -eq "469" ]
		then
			echo "MESSAGE: Deleting file: ${i} as it is ${iSIZE} bytes"
			rm ${i}
		fi
	done
}
f_displayresults(){
	cd "${DIRECTORY}"
	cat *p.nmap | grep "scan\ report\ for\|Interesting\|open\|---------------------------------------------" | grep -v "OSScan" | grep -v "filtered" > open_ports.txt
	xterm -title "OpenPorts from ${DIRECTORY}" -e "grep -E --color=always '.*(ssh|rdp|ssl|http|telnet|https|sslv2|mail|smtp|snmp|oracle|sql|tnls|ftp|sftp).*|' open_ports.txt | less -R" &
	if [[ `grep -v Testing WeakCiphers.txt | wc -l` -gt 0 ]]
	then
		xterm -title "WeakCiphers from ${DIRECTORY}" -e "less -R WeakCiphers.txt" &
	else
		rm -f WeakCiphers.txt		
		echo "MESSAGE: no weak ciphers found"
	fi
	cd -
}

f_uservariables
f_threadcheck ${1}
f_scansizecheck ${2}
f_directorycheck ${3}
f_findtargetstxt
f_numberoftargets
f_createdirectory ${DIRECTORY}
f_nmapscans		#comment me out to skip nmap scans
f_amapscans		#comment me out to skip amap scans
f_sslscans		#comment me out to skip ssl scans
f_gwp			#comment me out to skip web screenshots
f_cleanup
f_displayresults
exit 0
