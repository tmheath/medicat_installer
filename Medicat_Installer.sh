#!/usr/bin/env bash

# Version 0007

# Check if the terminal supports colour and set up variables if it does.
NumColours=$(tput colors)

if test -n "$NumColours" && test $NumColours -ge 8; then

    clear="$(tput sgr0)"
    blackN="$(tput setaf 0)";		blackN="$(tput bold setaf 0)"
    redN="$(tput setaf 1)";		redB="$(tput bold setaf 1)"
    greenN="$(tput setaf 2)";		greenB="$(tput bold setaf 2)"
    yellowN="$(tput setaf 3)";		yellowB="$(tput bold setaf 3)"
    blueN="$(tput setaf 4)";		blueB="$(tput bold setaf 4)"
    magentaN="$(tput setaf 5)";		magentaB="$(tput bold setaf 5)"
    cyanN="$(tput setaf 6)";		cyanB="$(tput bold setaf 6)"
    whiteN="$(tput setaf 7)";		whiteB="$(tput bold setaf 7)"

fi

# Function to echo text using terminal colour codes ###########################
function colEcho() {
    echo -e "$1$2$clear"
}

# Function to wait for a user keypress.
UserWait () {
    read -n 1 -s -r -p "Press any key to continue"
    echo -e "\r                         \r"
}

# Function to check we are not running with the elevated privileges. ##########
function CheckNotElevated {

    if (( "$EUID" == "0" )); then
        colEcho $redB "ERROR: Running with elevated privileges - do not run using sudo\n"
        exit 1
    fi
}

# Main Code Start. ############################################################

# Key variables used throughout the script to make maintenance easier.
Medicat256Hash='a306331453897d2b20644ca9334bb0015b126b8647cecec8d9b2d300a0027ea4'
Medicat7zFile="MediCat.USB.v21.12.7z"
Medicat7zFull=''MediCat\ USB\ v21.12/MediCat.USB.v21.12.7z''

clear
colEcho $yellowB "WELCOME TO THE MEDICAT INSTALLER.\n"

CheckNotElevated

colEcho $cyanB "This Installer will install Ventoy and Medicat.\n"
colEcho $yellowB "THIS IS IN BETA. PLEASE CONTACT MATT IN THE DISCORD FOR ALL ISSUES.\n"
colEcho $cyanB "Updated for efficiency and cross-distro use by SkeletonMan.\n"
colEcho $cyanB "Enhancements by Manganar.\n"
colEcho $cyanB "Thanks to @m3p89goljrf7fu9eched in the Medicat Discord for pointing out a bug.\n"

skipInstall=false
osId=grep "(?<=ID=)[a-zA-Z]+(?=\n)" /etc/release
# Set variables to support different distros.
# Find fileinfo here https://github.com/stejskalleos/os_release/tree/main
if [ $osId = ubuntu ]; then
	os=ubuntu
	pkgmgr=apt
 	install_arg=install
  	update_arg=update
elif [ $osId = freebsd ]; then
	os=freebsd
	pkgmgr=pkg
	install_arg=install
	update_arg=update
elif [ $osId = alpine ]; then
	os=alpine
	pkgmgr=apk
	install_arg=add
	update_arg=update
elif [ $osId = gentoo ]; then
	os=gentoo
	pkgmgr=emerge
	install_arg=""
 	update_arg=""
  colEcho "WARNING: This script does not install software onto a Gentoo System."
  colEcho "Please ensure the below commands are available before continuing."
  colEcho "wget 7z mkntfs aria2c"
  read -p "yn" -n1 confirm
  if [ $confirm = y ]; then
  	skipInstall=true
  else; then
  	exit 2
   fi
elif [ $osId = debian ]; then
	os=debian
	pkgmgr=apt
	install_arg=install
	update_arg=update
elif [ $osId = almalinux || $osId = rocky || $osId = centos ]; then
	colEcho $redB "Fuck Red-Hat for putting source code behind paywalls."
	os=centos
	pkgmgr=yum
	install_arg=install
	update_arg=update
elif [ $osId = fedora ]; then
	os=fedora
	pkgmgr=yum
	install_arg=install
	update_arg=update
# nobara does not state modified os-info file therefore explicit support should be unrequired
#elif [[ -e /etc/nobara ]]; then
#	colEcho $redB "gaming moment"
#	os="fedora"
#	pkgmgr="yum"
#	install_arg="install"
#	update_arg="update"
elif [ $osId = arch ]; then
	os=arch
	pkgmgr=pacman
	install_arg="-S --needed --noconfirm"
	update_arg="-Syy"
else
	colEcho "ERROR: Distro not recognised - exiting..."
	exit 1
fi

colEcho $cyanB "Operating System Identified:$whiteB $os \n"

if ! $skipInstall; then
# Ensure dependencies are installed: wget, 7z, mkntfs, and aria2c only if Medicat 7z file is not present
colEcho $cyanB "\nLocating the Medicat 7z file..."

if [[ -f "$Medicat7zFile" ]]; then
	location="$Medicat7zFile"
else
	if  [[ -f "$Medicat7zFull" ]]; then
		location="$Medicat7zFull"
	else
		colEcho $cyanB "Please enter the location of$whiteB $Medicat7zFile$cyanB if it exists or just press enter to download it via bittorrent."
		read location
	fi
fi

colEcho $cyanB "Acquiring any dependencies..."

sudo $pkgmgr $update_arg
if ! [ $(which wget 2>/dev/null) ]; then
	sudo $pkgmgr $install_arg wget
fi

if ! [ $(which 7z 2>/dev/null) ]; then
	if [[ -e /etc/arch-release ]]; then
		sudo $pkgmgr $install_arg p7zip
	elif [[ -e /etc/fedora-release  ]]; then
		sudo $pkgmgr $install_arg p7zip-full p7zip-plugins
  	elif [[ -e /etc/nobara  ]]; then
		sudo $pkgmgr $install_arg p7zip-full p7zip-plugins
	elif [ "$os" == "centos" ]; then
		sudo $pkgmgr $install_arg p7zip p7zip-plugins
	elif [ "$os" == "alpine" ]; then
		sudo $pkgmgr $install_arg 7zip
	else
		sudo $pkgmgr $install_arg p7zip-full
	fi
fi

if ! [ $(sudo which mkntfs 2>/dev/null) ]; then 
	if [ "$os" == "centos" ]; then
		sudo $pkgmgr $install_arg ntfsprogs
	else
		sudo $pkgmgr $install_arg ntfs-3g
	fi
fi

if ! [ $(which aria2c 2>/dev/null)] && [ -z "$location" ]; then
	sudo $pkgmgr $install_arg aria2
fi
fi
# Identify latest Ventoy release.
venver=$(wget -q -O - https://api.github.com/repos/ventoy/Ventoy/releases/latest | grep '"tag_name":' | cut -d'"' -f4)

# Download latest verion of Ventoy.
colEcho $cyanB "\nDownloading Ventoy Version:$whiteB ${venver: -6}"
wget -q --show-progress https://github.com/ventoy/Ventoy/releases/download/v${venver: -6}/ventoy-${venver: -6}-linux.tar.gz -O ventoy.tar.gz

colEcho $cyanB "\nExtracting Ventoy..."
tar -xf ventoy.tar.gz

colEcho $cyanB "Removing the extracted Ventory tar.gz file..."
rm -rf ventoy.tar.gz

# Remove the ./ventoy folder if it exists before renaming ventoy folder.
if [ -d ./ventoy ]; then
	colEcho $cyanB "Removing the previous ./ventoy folder..."
	rm -rf ./ventoy/
fi

colEcho $cyanB "Renaming ventoy folder to remove the version number..."
mv ventoy-${venver: -6} ventoy

# Download the missing Medicat 7z file
if [ -z "$location" ] ; then
	colEcho $cyanB "Starting to download torrent"
	wget https://github.com/mon5termatt/medicat_installer/raw/main/download/MediCat_USB_v21.12.torrent -O medicat.torrent
	aria2c --file-allocation=none --seed-time=0 medicat.torrent
	location="$Medicat7zFull"
fi

colEcho $cyanB "Medicat 7z file found:$whiteB $location"

# Check the SHA256 hash of the Medicat zip file.
colEcho $cyanB "Checking SHA256 hash of$whiteB $Medicat7zFile$cyanB..."

checksha256=$(sha256sum "$location" | awk '{print $1}')

if [[ "$checksha256" != "$Medicat256Hash" ]]; then
	colEcho $redB "$Medicat7zFile SHA256 hash does not match."
	colEcho $redB "File may be corrupted or compromised."
	colEcho $cyanB "Hash is$whiteB $checksha256"
	colEcho $cyanB "Exiting..."
	exit 1
else
	colEcho $greenB "$Medicat7zFile SHA256 hash matches."
	colEcho $cyanB "Hash is$whiteB $checksha256"
	colEcho $cyanB "Safe to proceed..."
fi

# Advise user to connect and select the required USB device.
colEcho $yellowB "\nPlease Plug your USB in now if it is not already connected..."
colEcho $yellowB "\nPress any key once it has been detected by your system..."
UserWait

colEcho $yellowB "Please Find the ID of your USB below:"

lsblk --nodeps --output "NAME,SIZE,VENDOR,MODEL,SERIAL" | grep -v loop

colEcho $yellowB "Enter the device for the USB drive NOT INCLUDING /dev/ OR the Number After."
colEcho $yellowB "for example enter sda or sdb"
read letter

drive=/dev/$letter
drive2="$drive""1"
checkingconfirm=""

while [[ "$checkingconfirm" != [NnYy]* ]]; do
	read -e -p "You want to install Ventoy and Medicat to $drive / $drive2? (Y/N) " checkingconfirm
	if [[ "$checkingconfirm" == [Nn]* ]]; then
		colEcho $yellowB "Installation Cancelled."
		exit
	elif [[ "$checkingconfirm" == [Yy]* ]]; then
		colEcho $cyanB "Installation confirmed and will commence in 5 seconds..."
		sleep 5
	else
		colEcho $redB "Invalid input. Please enter 'Y' or 'N'."
	fi
done

colEcho $cyanB "Installing Ventoy on$whiteB $drive"
sudo sh ./ventoy/Ventoy2Disk.sh -I $drive
if [ "$?" != "0" ]; then
	colEcho $redB "ERROR: Unable to install Ventoy. Exiting..."
	exit 1
fi

colEcho $cyanB "Unmounting drive$whiteB $drive"
sudo umount $drive

colEcho $cyanB "Creating Medicat NTFS file system on drive$whiteB $drive2"
sudo mkntfs --fast --label Medicat $drive2

# Create a mountpoint folder for the Medicat NTFS volume
if ! [[ -d MedicatUSB/ ]] ; then
	colEcho $cyanB "Creating a mountpoint for the Medicat NTFS volume..."
	mkdir MedicatUSB
fi

colEcho $cyanB "Mounting Medicat NTFS volume..."
sudo mount $drive2 ./MedicatUSB

colEcho $cyanB "Extracting Medicat to NTFS volume..."
7z x -O./MedicatUSB "$location"

colEcho $cyanB "MedicatUSB has been created."

unmountcheck=""
while [[ "$unmountcheck" != [NnYy]* ]]; do
	read -e -p "Would you like to unmount ./MedicatUSB? (Y/N) " unmountcheck
	if [[ $unmountcheck == [Yy]* ]]; then
		colEcho $cyanB "Unmounting MedicatUSB..."
		sudo umount ./MedicatUSB
		colEcho $cyanB "Unmounted."
	elif [[ $unmountcheck == [Nn]* ]]; then
		colEcho $cyanB "MedicatUSB will not be unmounted."
	else
		colEcho $redB "Invalid input. Please enter 'Y' or 'N'."
	fi
done
