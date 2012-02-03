#!/bin/bash
#__________________________________________________________
# Authors:    	phillips321 (matt@phillips321.co.uk)
# License:    	CC BY-SA 3.0
# Use:        	Brings tools on GT5 to bleeding edge and 
#               adds missing tools
# Released:   	www.phillips321.co.uk
#__________________________________________________________
version="0.1" #Sept/2011
# Changelog:
# v0.1 - First release
#
# ToDo:
# - ensure everything is unmounted before deleting nfs dir
# - Clean up by creating functions

help_msg() {
echo -e "Usage: $0 target
 Example:
        $0 192.168.1.100"
        exit 1
        }

if [ -z ${1} ]
then
	help_msg
        exit 1
fi

target=${1}

echo "Identified shares"
showmount -e ${target}

for i in `showmount -e ${target} | cut -d" " -f1 | grep -v "Export"`
do
	mkdir -p `pwd`/nfs${i}
	mount -t nfs ${target}:${i} `pwd`/nfs${i}
	tree `pwd`/nfs -o `pwd`/nfs_${target}.txt
done

echo "You now have mounted shares at `pwd`/nfs/"
ls `pwd`/nfs/

read -p "Feel free to browse the shares, when you are ready to unmount press enter"
echo "unmounting the following:"
mount | grep ${target} | cut -d" " -f1

for i in `mount | grep ${target} | cut -d" " -f1`
do
	umount ${i}
done

#run twice as sometimes thing dont unmount
for i in `mount | grep ${target} | cut -d" " -f1`
do
        umount ${i}
done

##This shit is dangerous if you have mounted shares with write privs, FIXIT
#echo "deleting nfs directory"
#echo "rm -rf `pwd`/nfs"
#rm -rf `pwd`/nfs

cat nfs_*.txt | grep "passwd\|shadow"

exit 0


