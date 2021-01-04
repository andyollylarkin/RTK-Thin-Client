#!/bin/bash

if (( "$#" < 3 )); then
	print "1) Device for write ISO image e.g /dev/sdX \
	      2) Sourse image RescueCD path \
          3) System disk device e.g. /dev/sdX"
		  exit 64;
fi	     

#Check is root
if [[ $(whoami) != "root" ]]
then
    print "Please login as root!\n";
    exit 2;
else
    export ROOT_DIR=$HOME;
fi

if [ ! -f "${ROOT_DIR}/systemrescue-7.01-amd64.iso" ]
then
    echo -e "\033[31m\033[4mDOWNLOAD SYSTEM RESCUE IMAGE:\033[0m";
    wget "https://osdn.net/frs/redir.php?m=dotsrc&f=%2Fstorage%2Fg%2Fs%2Fsy%2Fsystemrescuecd%2Freleases%2F7.01%2Fsystemrescue-7.01-amd64.iso" \
    --output-document="${ROOT_DIR}/systemrescue-7.01-amd64.iso";
else
    echo "Image already exist. Continue build.";
fi

if [ -d '/mnt/toor' ]
then
	rm -Rfv /mnt/toor
fi

device=$1;
source_image=$2;
system_disk=$3;

XZ_OPT="-7 -T0";

mkdir /tmp/{iso_custom,source_image,target_system};
mount -o loop "${ROOT_DIR}/${source_image}" /tmp/source_image;

#Copy all files from original System Rescue CD
cp -Rfv /tmp/source_image/* /tmp/iso_custom/;

cd /tmp/iso_custom/sysresccd/x86_64;
unsquashfs -x airootfs.sfs;
rm airootfs.sfs;

mkdir /mnt/toor && mount $system_disk /mnt/toor;
cd /mnt/toor
tar --numeric-owner -cvpJf /tmp/target_system/tionix_client_archive.tar.xz . 
cd -;
cp -Rfv /tmp/target_system/tionix_client_archive.tar.xz /tmp/iso_custom/sysresccd/x86_64/squashfs-root/root/;
cp "${ROOT_DIR}/RTK\-Thin\-Client/install_tc.sh" /tmp/iso_custom/sysresccd/x86_64/squashfs-root/root;


mksquashfs squashfs-root /tmp/iso_custom/sysresccd/x86_64/airootfs.sfs -xattrs;
sha512sum airootfs.sfs > airootfs.sha512;
rm -Rfv /tmp/iso_custom/sysresccd/x86_64/squashfs-root;

#make ISO image
xorriso -as mkisofs -o /tmp/RTK_thin_client.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
	-boot-info-table -iso-level 3 -joliet-long -input-charset utf-8 -J -R -V RESCUE701 /tmp/iso_custom;
isohybrid /tmp/RTK_thin_client.iso;

#Write ISO image to USB stick?
while true; do
    read -p "\033[31m\033[4mWRITE ISO TO USB STICK:\033[0m" Question
    case $Question in
        Y|y|yes)
            dd if=/tmp/RTK_thin_client.iso of=$device bs=1M status=progress;
            fatlabel $device RESCUE701;
            break
            ;;
        N|n|no)
            echo "No"
            break
            ;;
        *)
            echo "Yes or No!"
            continue
            ;;
    esac
done

#FINILIZE - delete temporary files
cp -f /tmp/RTK_thin_client.iso ${ROOT_DIR};
echo -e "\033[31m\033[4mCALCULATE MD5 SUM OF IMAGE\033[0m";
md5sum "${ROOT_DIR}/RTK_thin_client.iso" > "${ROOT_DIR}/RTK_thin_client.md5";
umount $system_disk;
unset device;
unset source_image;
unset system_disk;
