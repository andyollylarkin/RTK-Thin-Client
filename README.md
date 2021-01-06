# RTK-Thin-Client
### Description: Rostelecom thin client installation and iso image generation scripts

## Requirements:
- System RescueCD [v7.01](https://osdn.net/projects/systemrescuecd/storage/releases/7.01/systemrescue-7.01-amd64.iso)<br>
- xorisso<br>
- squashfs-tools<br>
- syslinux-utils<br>

```shell
sudo apt-get install -y xorriso squashfs-tools syslinux-utils
```


## Build and install new release process
1. Install previous image for build the new image on a clean system<br>
2. Make the necessary changes<br>
3. Load from another OS<br>
4. Install all necessary packages for make new image see Requirements<br>
5. Execute "rebuild_iso.sh" script<br>
6. **Copy current release ISO image to another machine for store this release!**<br>
7. Reboot system 
8. Boot from USB stick with new image
9. Install image
10. Reboot system
11. Configure initramfs (_sudo update-kernel_)
12. DONE

## TODO:
- [x] Setup user password when installing system<br>
- [ ] Edit installation path<br>
- [x] Build tionix-client **deb** package

## Install Tionix-VDI-Client package
```shell
wget https://github.com/andyollylarkin/RTK-Thin-Client/releases/download/t-2.5/tionixvdiclient.deb
sudo apt-get install -f ./tionixvdiclient.deb
```
## Update kernel to 5.10.4
```shell
dpkg --install kernel-5.10.4.deb
```

