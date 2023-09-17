#!/bin/sh

#-----------------------#
#-----  Variables  -----#
#-----------------------#

# Name of subvolume
KLIPPERVOL='klipper'
MOONRAKERVOL='moonraker'
PRINTER_DATAVOL='printer_data'
# Mountpoint paths

#-----------------------#
#-----   Colors    -----#
#-----------------------#

RED='\033[0;31m'	# Red
RED2=$(printf '\033[31m')  # Red2
CYAN='\033[0;36m'	# Cyan
CYAN2=$(printf '\033[36m') # Cyan2
GOLD=$(printf '\033[0;33m')   # Gold
NC='\033[0m' 		# No Color
NC2=$(printf '\033[0m')    # No Color2


echoerr(){
    printf "[${RED}ERROR${NC}] %s\n" "$*" 1>&2
}
info(){
    printf "[${CYAN}INFO${NC}]${CYAN} %s${NC}\n" "$*"
}


install_fluidd(){
    FLUIDDVOL='fluidd'
    mkdir "$MOUNTPOINT/$FLUIDDVOL";
    wget -q -O "$MOUNTPOINT/$FLUIDDVOL/fluidd.zip" https://github.com/cadriel/fluidd/releases/latest/download/fluidd.zip && unzip "$MOUNTPOINT/$FLUIDDVOL/fluidd.zip" -d "$MOUNTPOINT/$FLUIDDVOL" && rm "$MOUNTPOINT/$FLUIDDVOL/fluidd.zip";
    wget -q -O "$MOUNTPOINT/$PRINTER_DATAVOL/config/moonraker.conf" https://raw.githubusercontent.com/BrendonScheiber/CRKlipper/main/Configs/fluidd_moonraker.conf;
    wget -q -O /etc/nginx/conf.d/fluidd.conf https://raw.githubusercontent.com/BrendonScheiber/CRKlipper/main/Configs/fluidd.conf;
    wget https://github.com/BrendonScheiber/CRKlipper/raw/main/Configs/fluidd.cfg -P "$MOUNTPOINT/$PRINTER_DATAVOL/config/"
}


install_mainsail(){
    MAINSAILVOL='mainsail'
    mkdir "$MOUNTPOINT/$MAINSAILVOL";
    wget -q -O "$MOUNTPOINT/$MAINSAILVOL/mainsail.zip" https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip && unzip "$MOUNTPOINT/$MAINSAILVOL/mainsail.zip" -d "$MOUNTPOINT/$MAINSAILVOL" && rm "$MOUNTPOINT/$MAINSAILVOL/mainsail.zip";
    wget -q -O "$MOUNTPOINT/$PRINTER_DATAVOL/config/moonraker.conf" https://raw.githubusercontent.com/BrendonScheiber/CRKlipper/main/Configs/mainsail_moonraker.conf;
    wget -q -O /etc/nginx/conf.d/mainsail.conf https://raw.githubusercontent.com/BrendonScheiber/CRKlipper/main/Configs/mainsail.conf;
    wget https://github.com/BrendonScheiber/CRKlipper/raw/main/Configs/mainsail.cfg -P "$MOUNTPOINT/$PRINTER_DATAVOL/config/"
}

main(){
    
    printf "%40s\n" "${RED2}   #############################################"
    printf "      ## Did you execute format.sh first?  ##\n"
    printf "%40s\n\n" "   #############################################${NC2}"
    printf "Press [ENTER] if YES ...or [ctrl+c] to exit"
    read -r
    
    printf "%40s\n\n" "${CYAN2}This script will download and install all packages form the internet${NC2}"
    printf "%40s\n" "${RED2}   #############################################"
    printf "      ## Make sure extroot is enabled...  ##\n"
    printf "%40s\n\n" "   #############################################${NC2}"
    printf "Press [ENTER] to check if extroot is enabled ...or [ctrl+c] to exit"
    read -r
    
    printf "%40s\n" "${CYAN2}   ####################################################"
    printf "      ## Is /dev/mmcblk0p1 mounted on /overlay?  ##\n"
    printf "%40s\n\n" "   ####################################################${NC2}"
    printf "Press [ENTER] if YES ...or [ctrl+c] to exit"
    read -r
    
    printf "%40s\n" "${RED2}   ################################################################"
    printf "       ## Make sure you've got a stable Internet connection!  ##\n"
    printf "%40s\n\n" "   ################################################################${NC2}"
    printf "Press [ENTER] if YES ...or [ctrl+c] to exit"
    read -r
    
    info "Preserving opkg lists"
    sed -i -e "/^lists_dir\s/s:/var/opkg-lists$:/usr/lib/opkg/lists:" /etc/opkg.conf;
    opkg update;
    
    info "Creating swap file"
    dd if=/dev/zero of=/overlay/swap bs=1M count=1024;
    mkswap /overlay/swap;
    
    info "Enabling swap file"
    uci -q delete fstab.swap;
    uci set fstab.swap="swap";
    uci set fstab.swap.device="/overlay/swap";
    uci commit fstab;
    /etc/init.d/fstab boot;
    
    info "Verify swap status"
    cat /proc/swaps;
    
    info "Installing main dependencies..."
    opkg install git-http unzip wget;
    
    info "Installing klipper dependencies..."
    opkg install htop gcc patch;
    opkg install python3 python3-pip python3-dev python3-cffi python3-greenlet python3-jinja2 python3-markupsafe;
    
    #opkg install libyaml-dev build-essential python3-setuptools python3-virtualenv
    #sudo apt install python3-virtualenv python3-dev python3-dev libffi-dev build-essential libncurses-dev avrdude gcc-avr binutils-avr avr-libc stm32flash dfu-util libnewlib-arm-none-eabi gcc-arm-none-eabi binutils-arm-none-eabi libusb-1.0-0 libusb-1.0-0-dev
    
    pip3 install --upgrade pip;
    pip3 install python-can configparser;
    
    info "Cloning 250k baud pyserial"
    git clone https://github.com/pyserial/pyserial /root/pyserial;
    cd /root/pyserial
    python3 /root/pyserial/setup.py install;
    cd /root/
    rm -rf /root/pyserial;
    
    # Install Python3 and its dependencies
    printf "Installing  Python3 and Python3 packages...\n"
    opkg install python3-tornado python3-pillow python3-distro python3-curl python3-zeroconf python3-paho-mqtt python3-yaml python3-requests ip-full libsodium --force-overwrite;
    
    # Upgrade setuptools
    info "Upgrading setuptools..."
    pip3 install --upgrade setuptools;
    
    # Install Pip3 dependencies
    info "Installing pip3 packages..."
    pip3 install pyserial-asyncio lmdb streaming-form-data inotify-simple libnacl preprocess-cancellation apprise ldap3 dbus-next;
    
    # Create parent directory
    MOUNTPOINT='/etc/CRKlipper'
    info "Root mountpoint is '$MOUNTPOINT'"
    
    mkdir -p "$MOUNTPOINT"
    
    # Create other directory
    mkdir -p "$MOUNTPOINT/$PRINTER_DATAVOL";
    mkdir -p "$MOUNTPOINT/$PRINTER_DATAVOL/config";
    mkdir -p "$MOUNTPOINT/$PRINTER_DATAVOL/logs";
    mkdir -p "$MOUNTPOINT/$PRINTER_DATAVOL/gcodes";
    mkdir -p "$MOUNTPOINT/$PRINTER_DATAVOL/systemd";
    mkdir -p "$MOUNTPOINT/$PRINTER_DATAVOL/comms";
    touch "$MOUNTPOINT/$PRINTER_DATAVOL/config/printer.cfg";
    
    #=====================#
    #=====  Klipper  =====#
    #=====================#
    
    # Clone Klipper repository
    info "Cloning Klipper..."
    git clone 'https://github.com/KevinOConnor/klipper' "$MOUNTPOINT/$KLIPPERVOL";
    
    # Download Klipper service script
    info "Creating klipper service..."
    wget https://raw.githubusercontent.com/BrendonScheiber/CRKlipper/main/Services/klipper -P /etc/init.d/;
    chmod 755 /etc/init.d/klipper;
    /etc/init.d/klipper enable;
    
    #=======================#
    #=====  Moonraker  =====#
    #=======================#
    
    # Clone Moonraker repository
    info 'Cloning Moonraker...'
    git clone 'https://github.com/Arksine/moonraker.git' "$MOUNTPOINT/$MOONRAKERVOL";
    
    # Download Moonraker service script
    info 'Downloading moonraker service...'
    wget https://raw.githubusercontent.com/BrendonScheiber/CRKlipper/main/Services/moonraker -P /etc/init.d/
    chmod 755 /etc/init.d/moonraker
    /etc/init.d/moonraker enable
    
    # Install Nginx
    info "Installing nginx..."
    opkg install nginx-ssl;
    
    # Download and configure Nginx services
    info "Downloading nginx services..."
    wget https://raw.githubusercontent.com/BrendonScheiber/CRKlipper/main/Configs/upstreams.conf -P /etc/nginx/conf.d/
    wget https://raw.githubusercontent.com/BrendonScheiber/CRKlipper/main/Configs/common_vars.conf -P /etc/nginx/conf.d/
    /etc/init.d/nginx enable
    
}

# Function to choose a frontend to install
choose_frontend(){
    info "Choose a frontend to install:\n"
    printf "0. Abort(Other frontend)\n"
    printf "1. Fluidd\n"
    printf "2. Mainsail\n"
    
    printf "Enter your choice (0/1/2): "
    read -r choice
    
    case $choice in
        1)
            _FRONTEND='fluidd'
            install_frontend
        ;;
        2)
            _FRONTEND='mainsail'
            install_frontend
        ;;
        0)
            info "Exiting...\n"
            exit 1
        ;;
        *)
            info "Invalid choice. Please enter a valid number.\n"
            choose_frontend
        ;;
    esac
}

# Function to install the selected frontend
install_frontend(){
    info 'Installing frontend...'
    if [ "$_FRONTEND" = 'fluidd' ]; then
        install_fluidd
        elif [ "$_FRONTEND" = 'mainsail' ]; then
        install_mainsail
    fi
}

# Function to set hostname using Avahi
hostname(){
    info "Using hostname instead of ip..."
    opkg install avahi-daemon-service-ssh avahi-daemon-service-http;
}

webcam(){
    info "Installing mjpg-streamer..."
    opkg install kmod-video-uvc mjpg-streamer;
    opkg install v4l-utils;
    opkg install mjpg-streamer-input-uvc mjpg-streamer-output-http mjpg-streamer-www;
    
    rm /etc/config/mjpg-streamer;
cat << "EOF" > /etc/config/mjpg-streamer
config mjpg-streamer 'core'
        option enabled '0'
        option input 'uvc'
        option output 'http'
        option device '/dev/video0'
        option resolution '640x480'
        option yuv '0'
        option quality '80'
        option fps '5'
        option led 'auto'
        option www '/www/webcam'
        option port '8080'
        #option listen_ip '192.168.1.1'
        #option username 'openwrt'
        #option password 'openwrt'
EOF
    
    /etc/init.d/mjpg-streamer enable;
    ln -s /etc/init.d/mjpg-streamer /etc/init.d/webcamd;
}

ttyhotplug(){
    info "Install tty hotplug rule..."
    opkg update && opkg install usbutils;
cat << "EOF" > /etc/hotplug.d/usb/22-tty-symlink
# Description: Action executed on boot (bind) and with the system on the fly
PRODID="1a86/7523/264" #change here according to "PRODUCT=" from grep command
SYMLINK="ttyPrinter" #you can change this to whatever you want just don't use spaces. Use this inside printer.cfg as serial port path
if [ "${ACTION}" = "bind" ] ; then
  case "${PRODUCT}" in
    ${PRODID}) # mainboard product id prefix
      DEVICE_TTY="$(ls /sys/${DEVPATH}/tty*/tty/)"
      # Mainboard connected to USB1 slot
      if [ "${DEVICENAME}" = "1-1.4:1.0" ] ; then
        ln -s /dev/${DEVICE_TTY} /dev/${SYMLINK}
        logger -t hotplug "Symlink from /dev/${DEVICE_TTY} to /dev/${SYMLINK} created"

      # Mainboard connected to USB2 slot
      elif [ "${DEVICENAME}" = "1-1.2:1.0" ] ; then
        ln -s /dev/${DEVICE_TTY} /dev/${SYMLINK}
        logger -t hotplug "Symlink from /dev/${DEVICE_TTY} to /dev/${SYMLINK} created"
      fi
    ;;
  esac
fi
# Action to remove the symlinks
if [ "${ACTION}" = "remove" ]  ; then
  case "${PRODUCT}" in
    ${PRODID})  #mainboard product id prefix
     # Mainboard connected to USB1 slot
      if [ "${DEVICENAME}" = "1-1.4:1.0" ] ; then
        rm /dev/${SYMLINK}
        logger -t hotplug "Symlink /dev/${SYMLINK} removed"

      # Mainboard connected to USB2 slot
      elif [ "${DEVICENAME}" = "1-1.2:1.0" ] ; then
        rm /dev/${SYMLINK}
        logger -t hotplug "Symlink /dev/${SYMLINK} removed"
      fi
    ;;
  esac
fi
EOF
}

logfix(){
    info "Creating system.log..."
    
    uci set system.@system[0].log_file='/etc/CRKlipper/klipper_logs/system.log';
    uci set system.@system[0].log_size='51200';
    uci set system.@system[0].log_remote='0';
    uci commit;
    
    info "Installing logrotate..."
    opkg install logrotate;
    
    info "Creating cron job..."
    printf "0 8 * * * *     /usr/sbin/logrotate /etc/logrotate.conf\n" >> /etc/crontabs/etc/CRKlipper
    
    info "Creating logrotate configuration files..."
    
cat << "EOF" > /etc/logrotate.d/klipper
/etc/CRKlipper/klipper_logs/klippy.log
{
    rotate 7
    daily
    maxsize 64M
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
}
EOF
    
cat << "EOF" > /etc/logrotate.d/moonraker
/etc/CRKlipper/klipper_logs/moonraker.log
{
    rotate 7
    daily
    maxsize 64M
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
}
EOF
    
    printf "%40s\n" "${GOLD}   ####################################################################"
    printf "     ## Congratulations, you have successfully installed Klipper.  ##\n"
    printf "%40s\n\n" "   ####################################################################${NC2}"
    
    printf "Please reboot for changes to take effect...\n"
    printf "...then proceed configuring your printer.cfg!"
}

main;
choose_frontend;
hostname;
webcam;
ttyhotplug;
logfix;