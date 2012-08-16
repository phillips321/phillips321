#!/bin/sh
# Nix-auditor - A simple Ubuntu / Redhat / CentOS audit script (which may run on other Linux variants)
# Nix-auditor should be run as root
# v0.16 Matt Byrne - November 2011
clear
echo =================================================
echo Nix-auditor v0.16 - Matt Byrne, November 2011
echo 
echo A simple Ubuntu / Redhat / CentOS Audit Script
echo =================================================
FILENAME=$1 
if [ "$FILENAME" = "" ]
then
	echo ""	
	echo "Error: No filename entered."
	echo ""
	echo "Usage- ./Nix-auditor.sh <filename>"
	exit
fi

FILECHECK=`ls | grep $FILENAME`

if [ "$FILECHECK" = "$FILENAME" ] 
then 
	echo ""
	echo "Filename already exists. Overwrite <y/n>?"
	read RESPONSE >> $FILENAME
	if [ "$RESPONSE" = "y" ]
	then 
		echo "Overwriting file..."
	else
		echo "Exiting. Please re-run with different filename"
		exit
	fi
fi
clear
echo "================================================================" | tee $FILENAME
echo "Nix-auditor v0.16 Scan: Initiated `date`" | tee -a $FILENAME
echo ""
echo "A simple Ubuntu / Redhat / CentOS Audit Script" | tee -a $FILENAME
echo "================================================================" | tee -a $FILENAME
echo ""
ID=$(id | cut -c 5) 
if [ "$ID" != 0 ]; then
	echo "You need to run Nix-auditor as root....Please "su" to "root!!!""	
	exit
	else
echo "Do you want to list (optional):"
echo ""
echo "	ALL World Readable Files?"
echo "	ALL World Writable Files?"
echo "	ALL SETUID Files?"
echo "	ALL SETGID Files?"
echo "	ALL Installed Sotware Packages?" 
echo ""
echo "WARNING: These File checks take considerably longer than the standard checks."  
echo ""
echo "Perform Extra File Checks Listed Above?: <y/n>?"
	read RESPONSE >> $FILENAME
	if [ "$RESPONSE" = "y" ]
	then 
	        echo "" 	
		echo "Nix-auditor is performing the File Checks this may take a while...."
		echo "" >> .files_tmp 
		echo "Listing World Readable / Writable Files:" >> .files_tmp
		echo ========================================= >> .files_tmp 
		echo "" >> .files_tmp
		find / -type f \( -perm -a+r -o -perm -a+w \) -not -regex '.*/proc/*.*' -not -regex '.*/dev/*.*' ! -type l -exec ls -ld '{}' \; >> .files_tmp
		echo "" >> .files_tmp 
		echo "Listing SETUID / SETGID Files:" >> .files_tmp 
		echo =============================== >> .files_tmp 
		echo "" >> .files_tmp
		find / -type f \( -perm -4000 -o -perm -2000 \) -not -regex '.*/proc/*.*' -not -regex '.*/dev/*.*' -exec ls -ld '{}' \; >> .files_tmp
		echo "" >> .files_tmp
		echo "Listing installed Software Packages:" >> .files_tmp 
		echo ===================================== >> .files_tmp
		echo "" >> .files_tmp
		if [ -f /bin/rpm ] ; then
		rpm -qa >> .files_tmp 
		elif [ -f /usr/bin/rpm ] ; then
		rpm -qa >> .files_tmp 
		fi
	        if [ -f /bin/dpkg ] ; then
		dpkg --list >> .files_tmp	
		elif [ -f /usr/bin/dpkg ] ; then
		dpkg --list >> .files_tmp
		fi
	fi	
fi
echo ""
echo "Nix-auditor is now performing the standard checks, not long now...."
echo "" >> $FILENAME
echo Hostname: >> $FILENAME
echo =========== >> $FILENAME
hostname >> $FILENAME
echo "" >> $FILENAME
echo Linux Distribution: >> $FILENAME
echo =================== >> $FILENAME
echo "NOTE: For RHEL or CentOS Systems should be atleast CentOS 5.7 or RHEL 4" >> $FILENAME 
echo "(although RHEL 3 has an Extended Life Cycle until 31/10/13)" >> $FILENAME
echo "" >> $FILENAME
cat /etc/issue >> $FILENAME
if [ -f /usr/bin/lsb_release ] ; then
	/usr/bin/lsb_release -dric | grep -v "No LSB" >> $FILENAME
fi
if [ -f /bin/lsb_release ] ; then
	/bin/lsb_release -dric >> $FILENAME
fi
echo "" >> $FILENAME
echo Kernal Version: >> $FILENAME
echo ================ >> $FILENAME
uname -a >> $FILENAME
echo "" >> $FILENAME
echo Network Interfaces: >> $FILENAME
echo =================== >> $FILENAME
ifconfig | grep -B 100 lo | grep -v lo | grep -B 1 "inet addr:" >> $FILENAME 
echo "" >> $FILENAME
echo Routing Info: >> $FILENAME
echo ============= >> $FILENAME
route -n | grep -v Kernel >> $FILENAME
echo "" >> $FILENAME
echo "IP Forwarding Enabled? (1=Enabled, 0=Disabled):" >> $FILENAME
echo ================================================ >> $FILENAME
if [ -f /etc/sysctl.conf ] ; then
	cat /etc/sysctl.conf | grep ipv4.ip_forward >> $FILENAME
fi
echo "" >> $FILENAME
echo netstat -an output: >> $FILENAME
echo =================== >> $FILENAME
netstat -anp | grep -B 100 Active | grep -v Active | grep -v 127.0.0.1 >> $FILENAME 
echo "" >> $FILENAME
echo Contents of /etc/hosts: >> $FILENAME
echo ======================= >> $FILENAME
cat /etc/hosts >> $FILENAME
echo "" >> $FILENAME
echo "Listing Sensitive File & Folder Permissions:" >> $FILENAME
echo ============================================= >> $FILENAME
if [ -f /etc/passwd ] ; then
	ls -l /etc/passwd >> $FILENAME
fi
if [ -f /etc/passwd- ] ; then
	ls -l /etc/passwd- >> $FILENAME
fi
if [ -f /etc/shadow ] ; then
	ls -l /etc/shadow >> $FILENAME
fi
if [ -f /etc/shadow- ] ; then
	ls -l /etc/shadow- >> $FILENAME
fi
if [ -f /etc/sudoers ] ; then
	ls -l /etc/sudoers >> $FILENAME
fi
if [ -d /root ] ; then
	ls -ld /root >> $FILENAME
fi
if [ -d /root/.ssh ] ; then
	ls -ld /root/.ssh >> $FILENAME
fi
if [ -d /root/.ssh ] ; then
	ls -l /root/.ssh | grep -v total >> $FILENAME
fi
if [ -f /root/.bash_history ] ; then
	ls -l /root/.bash_history >> $FILENAME
fi
if [ -f /etc/hosts.equiv ] ;then
	ls -l /etc/hosts.equiv >> $FILENAME
fi
echo "" >> $FILENAME
echo Listing uid 0 accounts: >> $FILENAME
echo ======================= >> $FILENAME
awk -F: '{if ($3=="0") print$1}' /etc/passwd >> $FILENAME
echo "" >> $FILENAME
echo "List Accounts with blank passwords (if any):" >> $FILENAME
echo ============================================= >> $FILENAME
if [ -f /etc/shadow ] ; then
      echo `awk -F: '{if ($2=="") print $1}' /etc/shadow` >> $FILENAME
else
      echo `awk -F: '{if ($2=="") print $1}' /etc/passwd` >> $FILENAME
fi
echo "" >> $FILENAME
echo Listing Last Time Users Logged On: >> $FILENAME
echo ================================== >> $FILENAME
lastlog >> $FILENAME
echo "" >> $FILENAME
echo Listing Potentially Useful Utilities: >> $FILENAME
echo ===================================== >> $FILENAME
find / -type f -name rlogin > .find_tmp
find / -type f -name rsh >> .find_tmp
find / -type f -name wget >> .find_tmp
find / -type f -name nc >> .find_tmp
find / -type f -name netcat >> .find_tmp
find / -type f -name tftp >> .find_tmp
find / -type f -name ftp >> .find_tmp
find / -type f -name ssh >> .find_tmp
find / -type f -name telnet >> .find_tmp
find / -type f -name nmap >> .find_tmp
find / -type f -name perl >> .find_tmp
find / -type f -name python >> .find_tmp
find / -type f -name ruby >> .find_tmp
for i in `cat .find_tmp`
do
    	TARGET=${i}
    	ls -l ${TARGET} >> $FILENAME
done
rm .find_tmp
echo "" >> $FILENAME
echo "Listing /etc/hosts.allow configuration (if populated):" >> $FILENAME
echo ======================================================= >> $FILENAME
egrep -v '^.{0}#' /etc/hosts.allow >> $FILENAME
echo "" >> $FILENAME
echo "Listing /etc/hosts.deny configuration (if populated):" >> $FILENAME
echo ====================================================== >> $FILENAME
egrep -v '^.{0}#' /etc/hosts.deny >> $FILENAME
echo "" >> $FILENAME
echo "Listing SELinux Configuration (if present):" >> $FILENAME
echo "===========================================" >> $FILENAME
if [ -f /etc/selinux/config ] ; then
	cat /etc/selinux/config >> $FILENAME
fi
echo "" >> $FILENAME
echo "Listing /etc/hosts.equiv file (if present):" >> $FILENAME
echo ============================================ >> $FILENAME
if [ -f /etc/hosts.equiv ] ; then
	cat /etc/hosts.equiv >> $ FILENAME
fi
echo "" >> $FILENAME
echo "Listing User's .rhosts files (if present):" >> $FILENAME
echo =========================================== >> $FILENAME
find /home -type f -name .rhosts > .rhosts_tmp 
for j in `cat .rhosts_tmp`
do 
	TARGET=${j}
	ls -l ${TARGET} >> $FILENAME
	echo "" >> $FILENAME
	echo "Contents of ${TARGET}:" >> $FILENAME
	cat ${TARGET} >> $FILENAME
	echo "" >> $FILENAME
done
rm .rhosts_tmp
echo "" >> $FILENAME
echo "Listing User's .ssh file permissions (if present):" >> $FILENAME
echo =================================================== >> $FILENAME
find /home -type d -name .ssh > .ssh_tmp
for k in `cat .ssh_tmp`
do
	TARGET=${k}
	ls -ld ${TARGET} >> $FILENAME
	echo "" >> $FILENAME
	echo "Contents of ${TARGET}:" >> $FILENAME
	ls -l ${TARGET} | grep -v total >> $FILENAME
	echo "" >> $FILENAME
done
rm .ssh_tmp
echo "" >> $FILENAME
echo "Listing FTP User Permissions (if any):" >> $FILENAME
echo ======================================= >> $FILENAME
if [ -f /etc/ftpusers ] ; then
	cat /etc/ftpusers >> $FILENAME
fi 
if [ -f /etc/vsftpd.conf ] ; then
	cat /etc/vsftp.conf >> $FILENAME
fi
if [ -f /etc/vsftpd/vsftpd.conf ] ; then
	cat /etc/vsftpd/vsftpd.conf >> $FILENAME
fi
echo "" >> $FILENAME
echo "Listing NFS Exports (if any):" >> $FILENAME
echo =============================== >> $FILENAME
if [ -f /etc/exports ] ; then
      cat /etc/exports >> $FILENAME
fi
echo "" >> $FILENAME
echo "Listing SNMP Configuration (if any):" >> $FILENAME
echo ===================================== >> $FILENAME
if [ -f /etc/snmp/snmpd.conf ] ; then
	cat /etc/snmp/snmpd.conf >> $FILENAME
fi
echo "" >> $FILENAME
echo "Listing iptables configuration:" >> $FILENAME
echo ================================ >> $FILENAME
iptables -L >> $FILENAME
echo "" >> $FILENAME
echo "Listing all System processes:" >> $FILENAME
echo =============================== >> $FILENAME
ps -ef >> $FILENAME
echo "" >> $FILENAME
if [ -f .files_tmp ] ; then 
	cat .files_tmp >> $FILENAME
	rm .files_tmp
fi
echo "" >> $FILENAME
echo ================================================================= >> $FILENAME
echo THIS IS THE END OF THE AUDIT FILE FOR HOST: `hostname`  >> $FILENAME
echo ================================================================= >> $FILENAME
echo ""
echo "Audit successful the results can be found in $FILENAME  : )"
