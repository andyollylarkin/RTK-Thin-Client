#!/bin/bash

export installation_disk=$1;



echo -e "\033[31m\033[4mWIPING DISK:\033[0m"
wipe $installation_disk;


echo -e "\033[31m\033[4mPREPARING PARTITIONS:\033[0m"
echo "label: dos"|sfdisk $installation_disk;
echo "
,+20G,83,*
,+3G,82,
"|sfdisk $installation_disk;

mkfs.ext4 -F -L "Rostelecom" $installation_disk"1";

partprobe $installation_disk;

mkdir /mnt/system;


mount $installation_disk"1" /mnt/system;

echo -e "\033[31m\033[4mCOPYING SYSTEM FILES:\033[0m"
tar -xvpJf /root/tionix_client_archive.tar.xz -C /mnt/system/ --numeric-owner;
sync;



#Mount necessary FS to chroot
mount --types proc /proc /mnt/system/proc;
mount --rbind /sys /mnt/system/sys;
mount --make-rslave /mnt/system/sys;
mount --rbind /dev /mnt/system/dev;
mount --make-rslave /mnt/system/dev;

echo -e "\033[31m\033[4mENTERING TO CHROOT:\033[0m"
chroot /mnt/system /bin/bash -x <<'EOF'
source /etc/profile;


#Install GRUB
grub-install --force $installation_disk;
grub-mkconfig -o /boot/grub/grub.cfg;

#SWAP
mkswap $installation_disk"2";
swapon $installation_disk"2";

#Reconfigure vipnet package
dpkg-reconfigure vipnetclient-gui;

#Set hostname
echo "VDI-client:$(cat /proc/sys/kernel/random/uuid|egrep -o '^(\w|\d|\S){0,5}')" > /etc/hostname;

#Editing fstab
export root_disk=$(blkid $installation_disk"1"|egrep -o '\sUUID=\"(\w|\d|\S)+\"'|awk '{ print $1 }');
export swap_disk=$(blkid $installation_disk"2"|egrep -o '\sUUID=\"(\w|\d|\S)+\"'|awk '{ print $1 }');
echo "$root_disk /               ext4    errors=remount-ro 0       0" > /etc/fstab;
echo "$swap_disk none            swap    sw                0       0" >> /etc/fstab;
EOF
reboot;
