#!/bin/bash
#__________________________________________________________
# Authors:    	phillips321 (matt@phillips321.co.uk)
# License:    	CC BY-SA 3.0
# Use:        	mounts nfs shares on a target for browsing
# Released:   	www.phillips321.co.uk
#__________________________________________________________
version="0.2" #May/2012
# Changelog:
#	v0.2 - Added mount to be readonly for safety!
# 	v0.1 - First release
#
# ToDo:
# - ensure everything is unmounted before deleting nfs dir
# - Clean up by creating functions

if [ -z ${1} ] ; then echo -e "Usage: $0 target \n  Example:$0 192.168.1.100" && exit 1 ; else target=${1} ; fi

echo "Identified shares"
showmount -e ${target}

for i in `showmount -e ${target} | cut -d" " -f1 | grep -v "Export"`
do
	mkdir -p "`pwd`/nfs${i}"
	mount -o nolock,ro -t nfs ${target}:${i} "`pwd`/nfs${i}"
done

echo "You now have mounted shares at `pwd`/nfs/"
nautilus `pwd`/nfs/ &
echo "Now running tree against the nfs shares... please wait"
tree `pwd`/nfs >> `pwd`/nfs_${target}.txt
echo "Tree output finished and saved to pwd`/nfs_${target}.txt"
read -p "Feel free to browse the shares, press [Enter] to finish"
echo "unmounting the following:"
mount | grep ${target} | cut -d" " -f1

for i in `mount | grep ${target} | cut -d" " -f1`
do
	umount ${i}
done

#run twice as sometimes thing dont unmount tidy
for i in `mount | grep ${target} | cut -d" " -f1`
do
        umount ${i}
done

#This shit is dangerous if you have mounted shares with write privs, FIXIT
echo "deleting nfs directory"
echo "rm -rf `pwd`/nfs" ; rm -rf `pwd`/nfs

exit 0


