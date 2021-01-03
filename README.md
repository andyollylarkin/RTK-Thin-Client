# RTK-Thin-Client
### Description: Rostelecom thin client installation and iso image generation scripts

## Requirements:
- System RescueCD [v7.01](https://osdn.net/projects/systemrescuecd/storage/releases/7.01/systemrescue-7.01-amd64.iso)<br>
- xorisso<br>
- squashfs-tools<br>
## TODO:
- [x] Setup user password when installing system<br>
- [ ] Add tionix client installation script and configuration files to repository<br> 
- [ ] Edit installation path<br>
- [x] Build tionix-client **deb** package

## Install Tionix-VDI-Client package
```shell
wget [tionixvdiclient.deb](https://github.com/andyollylarkin/RTK-Thin-Client/releases/download/t-2.5/tionixvdiclient.deb)<br>
sudo apt-get install -f ./tionixvdiclient.deb
```

