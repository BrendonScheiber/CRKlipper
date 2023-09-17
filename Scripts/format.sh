#!/bin/sh

#-----------------------#
#-----  Variables  -----#
#-----------------------#

# Device names for SD card and its partition
DEVICE='/dev/mmcblk0'
PARTITION='/dev/mmcblk0p1'


#-----------------------#
#-----   Colors    -----#
#-----------------------#

RED='\033[0;31m'	# Red
RED2=$(printf '\033[31m')  # Red2
CYAN='\033[0;36m'	# Cyan
CYAN2=$(printf '\033[36m') # Cyan2
NC='\033[0m' 		# No Color
NC2=$(printf '\033[0m')    # No Color2

# Function to print error message to stderr
echoerr(){
    printf "[${RED}ERROR${NC}] %s\n" "$*" 1>&2;
}

# Function to print info message
info(){
    printf "[${CYAN}INFO${NC}]${CYAN} %s${NC}\n" "$*";
}

# Display introduction
printf "%40s\n\n" "${CYAN2}This script will format your sd card and make it extroot${NC2}"
printf "%40s\n" "${RED2}   ###################################################"
printf "   ## Make sure you've got a microSD card plugged!  ##\n"
printf "%40s\n\n" "   ###################################################${NC2}"
# Prompt user to continue
printf "Press [ENTER] to continue...or [ctrl+c] to exit"
read -r;

main(){
    while true; do
        printf "This script will format your sdcard. Are you sure about this? [y/n]: "
        read -r yn;
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) printf "Please answer yes(y) or no(n).\n";;
        esac
    done
    
    printf "Check and install packages.\n\n";
    
    # Update package list
    opkg update;
    opkg_list=$(opkg list-installed);
    
    # Function to check and install a package
    check_and_install_package() {
        package="$1";
        if echo "$opkg_list" | grep -q "$package"; then
            status="${CYAN2}already installed${NC2}";
        else
            opkg install "$package";
            status="${CYAN2}installed${NC2}";
        fi
        info "Package $package is $status."
    }
    
    # Check and install required packages
    check_and_install_package "kmod-fs-ext4";
    check_and_install_package "block-mount";
    check_and_install_package "swap-utils";
    check_and_install_package "e2fsprogs";
    check_and_install_package "parted";
    check_and_install_package "wipefs";
    check_and_install_package "fdisk";
    
    printf "Check if the volume is mounted\n\n";
    
    if mount | grep $PARTITION > /dev/null; then
        printf "%s is mounted, unmounting...\n" "$PARTITION"
        umount /mnt;
    fi
    
    info "Installation target is $DEVICE"
    
    # Perform formatting and setup
    info "Creating EXT4 filesystem on $PARTITION..."
    # Partition the device and create EXT4 filesystem
    parted -s "$DEVICE" -- mktable gpt mkpart CRKlipper 0% 100%;
    wipefs -a "$PARTITION";
    
    yes | mkfs.ext4 "$PARTITION";
    
    # Configure mount points
    DEVICE="$(sed -n -e "/\s\/overlay\s.*$/s///p" /etc/mtab)"
    uci -q delete fstab.rwm;
    uci set fstab.rwm="mount";
    uci set fstab.rwm.device="${DEVICE}";
    uci set fstab.rwm.target="/rwm";
    uci commit fstab;
    DEVICE="$PARTITION";
    eval "$(block info "$PARTITION" | grep -o -e "UUID=\S*")";
    uci -q delete fstab.overlay;
    uci set fstab.overlay="mount";
    uci set fstab.overlay.uuid="${UUID}";
    uci set fstab.overlay.target="/overlay";
    uci commit fstab;
    # Copy contents and unmount
    mount "$PARTITION" /mnt;
    cp -f -a /overlay/. /mnt;
    umount /mnt;
    
    printf "Please reboot then run the second script!\n";
}

main;