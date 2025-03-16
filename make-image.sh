#!/bin/bash

. ./scripts/INCLUDE.sh

# Exit on error
set -e

# Profile info
make info

# Main configuration name
PROFILE=""
PACKAGES=""

# Base
PACKAGES+=" dnsmasq-full cgi-io libiwinfo libiwinfo-data libiwinfo-lua liblua \
liblucihttp liblucihttp-lua libubus-lua lua block-mount adb curl \
htop coreutils-stty coreutils-base64 coreutils-stat coreutils-sleep screen \
rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns jq jshn \
libjson-script liblucihttp liblucihttp-lua lolcat lsblk tar unzip \
zram-swap uhttpd uhttpd-mod-ubus uuidgen wget-ssl zoneinfo-asia zoneinfo-core \
luci luci-base luci-ssl luci-compat luci-lib-base luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio \
luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp"

# Modem and UsbLAN Driver
PACKAGES+=" kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179"
PACKAGES+=" kmod-mii kmod-usb-net kmod-usb-wdm kmod-usb-net-qmi-wwan uqmi luci-proto-qmi \
kmod-usb-net-cdc-ether kmod-usb-serial-option kmod-usb-serial kmod-usb-serial-wwan qmi-utils \
kmod-usb-serial-qualcomm kmod-usb-acm kmod-usb-net-cdc-ncm kmod-usb-net-cdc-mbim umbim \
modemmanager luci-proto-modemmanager libmbim libqmi usbutils luci-proto-mbim \
kmod-usb-net-huawei-cdc-ncm kmod-usb-net-cdc-ether kmod-usb-net-rndis kmod-usb-net-sierrawireless kmod-usb-ohci kmod-usb-serial-sierrawireless \
kmod-usb-uhci kmod-usb2 kmod-usb-ehci usb-modeswitch kmod-nls-utf8 mbim-utils xmm-modem"

# Modem Tools
PACKAGES+=" modeminfo luci-app-modeminfo atinout modemband luci-app-modemband luci-app-mmconfig sms-tool luci-app-sms-tool-js luci-app-3ginfo-lite picocom minicom"

# Modem Info
PACKAGES+=" modeminfo-serial-tw modeminfo-serial-dell modeminfo-serial-xmm modeminfo-serial-fibocom modeminfo-serial-sierra"

# Tunnel option
OPENCLASH+="coreutils-nohup bash ca-certificates ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag kmod-nft-tproxy luci-app-openclash"
NIKKI+="nikki luci-app-nikki"
PASSWALL+="chinadns-ng resolveip dns2socks dns2tcp ipt2socks microsocks tcping xray-core xray-plugin luci-app-passwall"

# Tunnel options handling
handle_tunnel_option() {
    case "$1" in
        "openclash")
            PACKAGES+=" $OPENCLASH"
            ;;
        "nikki")
            PACKAGES+=" $NIKKI"
            ;;
        "openclash-passwall")
            PACKAGES+=" $OPENCLASH $PASSWALL"
            ;;
        "nikki-openclash")
            PACKAGES+=" $NIKKI $OPENCLASH"
            ;;
    esac
}

# Nas and storage
PACKAGES+=" luci-app-diskman luci-app-tinyfm kmod-usb-storage kmod-usb-storage-uas"

# Bandwidth And Network Monitoring
PACKAGES+=" internet-detector luci-app-internet-detector internet-detector-mod-modem-restart vnstat2 vnstati2 luci-app-netmonitor"

# Remote Services
PACKAGES+=" tailscale luci-app-tailscale"

# speedtest and limit bandwidth
PACKAGES+=" speedtestcli luci-app-eqosplus"

# Theme
PACKAGES+=" luci-theme-argon luci-theme-alpha"

# PHP8
PACKAGES+=" libc php8 php8-fastcgi php8-fpm php8-mod-session php8-mod-ctype php8-mod-fileinfo php8-mod-zip php8-mod-iconv php8-mod-mbstring"

# More
PACKAGES+=" luci-app-poweroff luci-app-ramfree luci-app-ttyd luci-app-lite-watchdog luci-app-ipinfo luci-app-droidnet luci-app-mactodong"

# Handle profile-specific packages
handle_profile_packages() {
    if [ "$1" == "rpi-4" ]; then
        PACKAGES+=" kmod-i2c-bcm2835 i2c-tools kmod-i2c-core kmod-i2c-gpio"
    elif [ "$ARCH_2" == "x86_64" ]; then
        PACKAGES+=" kmod-iwlwifi iw-full pciutils"
    fi

    case "${TYPE}" in
        "OPHUB")
            PACKAGES+=" btrfs-progs kmod-fs-btrfs luci-app-amlogic"
            EXCLUDED+=" -procd-ujail"
            ;;
        "ULO")
            PACKAGES+=" luci-app-amlogic"
            EXCLUDED+=" -procd-ujail"
            ;;
    esac
}

# Handle release branch specific packages
handle_release_packages() {
    if [ "${BASE}" == "openwrt" ]; then
        PACKAGES+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211 luci-app-temp-status"
        EXCLUDED+=" -dnsmasq"
    elif [ "${BASE}" == "immortalwrt" ]; then
        PACKAGES+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211 luci-app-temp-status"
        EXCLUDED+=" -dnsmasq -automount -libustream-openssl -default-settings-chn -luci-i18n-base-zh-cn"
        if [ "$ARCH_2" == "x86_64" ]; then
            EXCLUDED+=" -kmod-usb-net-rtl8152-vendor"
        fi
    fi
}

# Main build function
build_firmware() {
    local profile=$1
    local tunnel_option=$2

    log "INFO" "Starting build for profile: $profile"
    
    # Handle packages based on profile and tunnel option
    handle_profile_packages "$profile"
    handle_tunnel_option "$tunnel_option"
    handle_release_packages
    
    # Custom Files
    FILES="files"
    
    log "INFO" "Building image..."
    make image PROFILE="$profile" PACKAGES="$PACKAGES $EXCLUDED" FILES="$FILES" 2>&1
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "INFO" "Build completed successfully!"
    else
        log "ERROR" "Build failed. Check log for details."
    fi
}

# Main script execution
if [ -z "$1" ]; then
    log "ERROR" "Profile not specified"
fi

build_firmware "$1" "$2"
