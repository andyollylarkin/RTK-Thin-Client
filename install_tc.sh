#!/bin/bash 
export installation_disk=$1;
export disk_space=""



echo -e "\033[31m\033[4mWIPING DISK:\033[0m"
wipe $installation_disk;

while true; do
    read -p "Set disk space for system (Dont recommend set more than 20Gb),(Set as xxG, where xx is the number of Gigabytes) ->" space
    if [[ $(echo ${space}|grep -Eo "\w\b") == "G" ]]; then
        disk_space=$space;
        break;
    else
        echo -e "\033[101mIncorrect input format. Use xxG, e.g.\033[0m \033[102m20G\033[0m";
        continue;
    fi
done


echo -e "\033[31m\033[4mPREPARING PARTITIONS:\033[0m"
echo "label: dos"|sfdisk $installation_disk;
echo "
,${disk_space},83,*
,+3G,82,
"|sfdisk $installation_disk;

mkfs.ext4 -F -L "TC_RootDisk" $installation_disk"1";

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
source /etc/profile >> /dev/null;

#Generate initramfs
update-initramfs -c -k $(ls /boot|egrep -o "$config-$(ls -l /boot | grep -m 1 -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$');

#Install GRUB
grub-install --force $installation_disk;
grub-mkconfig -o /boot/grub/grub.cfg;

#SWAP
mkswap $installation_disk"2";
swapon $installation_disk"2";

#Reconfigure vipnet package
dpkg-reconfigure vipnetclient-gui;

#Set hostname
echo "VDI_client_$(cat /proc/sys/kernel/random/uuid|egrep -o '^(\w|\d|\S){0,5}')" > /etc/hostname;

#Update hosts
echo "
127.0.0.1	localhost
127.0.1.1   $(cat /etc/hostname)	

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
" > /etc/hosts;

#Setup new password for user
print "\033[101mYour need to change default password for user: tionix-user, and tell him it!\033[0m\n";
passwd tionix-user;

#Editing fstab
export root_disk=$(blkid $installation_disk"1"|egrep -o '\sUUID=\"(\w|\d|\S)+\"'|awk '{ print $1 }');
export swap_disk=$(blkid $installation_disk"2"|egrep -o '\sUUID=\"(\w|\d|\S)+\"'|awk '{ print $1 }');
echo "$root_disk /               ext4    errors=remount-ro 0       0" > /etc/fstab;
echo "$swap_disk none            swap    sw                0       0" >> /etc/fstab;
EOF
reboot;
