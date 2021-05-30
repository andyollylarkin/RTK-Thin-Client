#!/bin/bash

#Check root priveleges
check_root(){
    if [[ $(whoami) != "root" ]]
    then
        print "Please login as root!\n";
        exit 2;
    else
        export ROOT_DIR=$HOME;
    fi
}

download_boot_image(){
    if [ ! -f "$source_image" ]
    then
        local download_path="https://osdn.net/frs/redir.php?m=dotsrc&f=%2Fstorage%2Fg%2Fs%2Fsy%2Fsystemrescuecd%2Freleases%2F7.01%2Fsystemrescue-7.01-amd64.iso";
        echo -e "\033[31m\033[4mDOWNLOAD SYSTEM RESCUE IMAGE:\033[0m";
        wget ${download_path} --output-document="${ROOT_DIR}/systemrescue-7.01-amd64.iso";
        source_image=${ROOT_DIR}/systemrescue-7.01-amd64.iso;
    else
        echo "Image already exist. Continue build.";
    fi
    
}


make_new_image(){

    if [ -d '/mnt/toor' ]
    then
    	rm -Rfv /mnt/toor
    fi

    #Make new temporary required dirs
    mkdir /tmp/{iso_custom,source_image,target_system};
    mount -o loop "${source_image}" /tmp/source_image;
    
    #Copy all files from original System Rescue CD
    cp -Rfv /tmp/source_image/* /tmp/iso_custom/;
    
    cd /tmp/iso_custom/sysresccd/x86_64;
    unsquashfs -x airootfs.sfs;
    rm airootfs.sfs;

    
    #Mount source disk with production OS to /mnt/toor
    mkdir /mnt/toor && mount $system_disk /mnt/toor;
    cd /mnt/toor
    #Make archive with source OS
    tar --numeric-owner -cvpJf /tmp/target_system/tionix_client_archive.tar.xz . 
    cd -;
    cp -Rfv /tmp/target_system/tionix_client_archive.tar.xz /tmp/iso_custom/sysresccd/x86_64/squashfs-root/root/;
    cp "${ROOT_DIR}/RTK-Thin-Client/install_tc.sh" /tmp/iso_custom/sysresccd/x86_64/squashfs-root/root;
    
    
    #Make new squashfs
    mksquashfs squashfs-root /tmp/iso_custom/sysresccd/x86_64/airootfs.sfs -xattrs;
    sha512sum airootfs.sfs > airootfs.sha512;
    rm -Rfv /tmp/iso_custom/sysresccd/x86_64/squashfs-root;
    
    #make ISO image
    xorriso -as mkisofs -o /tmp/RTK_thin_client.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
    	-boot-info-table -iso-level 3 -joliet-long -input-charset utf-8 -J -R -V RESCUE701 /tmp/iso_custom;
    isohybrid /tmp/RTK_thin_client.iso;
}

#Write ISO image to USB stick?
write_iso(){
    dd if=/tmp/RTK_thin_client.iso of=$device bs=1M status=progress;
    fatlabel $device RESCUE701;
}

finilize(){
    cp -f /tmp/RTK_thin_client.iso ${ROOT_DIR};
    echo -e "\033[31m\033[4mCALCULATE MD5 SUM OF IMAGE\033[0m";
    md5sum "${ROOT_DIR}/RTK_thin_client.iso" > "${ROOT_DIR}/RTK_thin_client.md5";
    umount $system_disk;
    unset device;
    unset source_image;
    unset system_disk;
    unset ROOT_DIR;
}


main(){

    if (( "$#" < 3 )); then
    	print "1) Device for write ISO image e.g /dev/sdX \
    	       2) Sourse image RescueCD FULL path \
               3) System disk device e.g. /dev/sdX"
        exit 64;
    fi	     

    export device=$1;
    export source_image=$2;
    export system_disk=$3;
    export XZ_OPT="-7 -T0";

    check_root;
    download_boot_image;
    make_new_image;
    while true; do
        read -p "\033[31m\033[4mWRITE ISO TO USB STICK:\033[0m" answer
        case $answer in
            Y|y|yes)
                write_iso;
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
    finilize;
}
    
#START HERE --->
main;
