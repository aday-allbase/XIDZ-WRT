#!/bin/sh

exec > /root/setup.log 2>&1

# dont remove!
echo "Installed Time: $(date '+%A, %d %B %Y %T')"
sed -i "s#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' / ':'')+(luciversion||''),#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' By Xidz_x':''),#g" /www/luci-static/resources/view/status/include/10_system.js
sed -i -E "s|icons/port_%s.png|icons/port_%s.gif|g" /www/luci-static/resources/view/status/include/29_ports.js
sed -i -E "s|services/ttyd|system/ttyd|g"
if grep -q "ImmortalWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='ImmortalWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  echo Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
elif grep -q "OpenWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  echo Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
fi
echo "Tunnel Installed: $(opkg list-installed | grep -e luci-app-openclash -e luci-app-nikki -e luci-app-passwall | awk '{print $1}' | tr '\n' ' ')"

# Set hostname and Timezone to Asia/Jakarta
echo "Set hostname and Timezone to Asia/Jakarta"
uci set system.@system[0].hostname='XIDZ-WRT'
uci set system.@system[0].timezone='WIB-7'
uci set system.@system[0].zonename='Asia/Jakarta'
uci -q delete system.ntp.server
uci add_list system.ntp.server="pool.ntp.org"
uci add_list system.ntp.server="id.pool.ntp.org"
uci add_list system.ntp.server="time.google.com"
uci commit system

# set bahasa default
uci set luci.@core[0].lang='en' && uci commit

# configure wan and lan
echo "configure wan and lan"
uci set network.WAN=interface
uci set network.WAN.proto='dhcp'
uci set network.WAN.device='eth1'
uci set network.WAN.metric='5'
uci set network.WAN2=interface
uci set network.WAN2.proto='dhcp'
uci set network.WAN2.device='eth2'
uci set network.WAN2.metric='10'
uci set network.MODEM=interface
uci set network.MODEM.proto='dhcp'
uci set network.MODEM.device='wwan0'
uci set network.MODEM.metric='15'
uci set network.MM=interface
uci set network.MM.proto='modemmanager'
uci set network.MM.device='/sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb2/2-1'
uci set network.MM.apn='internet'
uci set network.MM.auth='none'
uci set network.MM.iptype='ipv4'
uci set network.MM.signalrate='10'
uci set network.MM.metric='20'
uci -q delete network.wan6
uci commit network
uci set firewall.@zone[1].network='WAN WAN2 MODEM MM'
uci commit firewall

# configure ipv6
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci -q delete dhcp.lan.ndp
uci commit dhcp

# configure WLAN
echo "Setup Wireless if available"
uci set wireless.@wifi-device[0].disabled='0'
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-iface[0].encryption='none'
uci set wireless.@wifi-device[0].country='ID'
if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
  uci set wireless.@wifi-iface[0].ssid='XIDZ-WRT_5G'
  uci set wireless.@wifi-device[0].channel='149'
  uci set wireless.radio0.htmode='HT40'
  uci set wireless.radio0.band='5g'
else
  uci set wireless.@wifi-iface[0].ssid='XIDZ-WRT'
  uci set wireless.@wifi-device[0].channel='1'
  uci set wireless.@wifi-device[0].band='2g'
fi
uci commit wireless
wifi reload && wifi up
if iw dev | grep -q Interface; then
  if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo; then
    if ! grep -q "wifi up" /etc/rc.local; then
      sed -i '/exit 0/i # remove if you dont use wireless' /etc/rc.local
      sed -i '/exit 0/i sleep 10 && wifi up' /etc/rc.local
    fi
    if ! grep -q "wifi up" /etc/crontabs/root; then
      echo "# remove if you dont use wireless" >> /etc/crontabs/root
      echo "0 */12 * * * wifi down && sleep 5 && wifi up" >> /etc/crontabs/root
      service cron restart
    fi
  fi
else
  echo "No wireless device detected."
fi

# Remove sysinfo banner if Devices Amlogic
if opkg list-installed | grep luci-app-amlogic > /dev/null; then
    rm -rf /etc/profile.d/30-sysinfo.sh
fi

# custom repo and Disable opkg signature check
echo "custom repo and Disable opkg signature check"
sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf
echo "src/gz custom_pkg https://dl.openwrt.ai/latest/packages/$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')/kiddin9" >> /etc/opkg/customfeeds.conf

# Set login root password
(echo "xidz"; sleep 1; echo "xidz") | passwd > /dev/null

# setup default theme
uci set luci.main.mediaurlbase='/luci-static/argon' && uci commit

# remove login password ttyd
uci set ttyd.@ttyd[0].command='/bin/bash --login' && uci commit

# remove huawei me909s usb-modeswitch
sed -i -e '/12d1:15c1/,+5d' /etc/usb-mode.json

# remove dw5821e usb-modeswitch
sed -i -e '/413c:81d7/,+5d' /etc/usb-mode.json

# Disable /etc/config/xmm-modem
uci set xmm-modem.@xmm-modem[0].enable='0' && uci commit

# install2.sh
chmod +x /root/install2.sh
bash /root/install2.sh

# setup misc settings
echo "setup misc settings"
sed -i 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' /etc/profile
sed -i 's/\[ -n "$FAILSAFE" \] && cat \/etc\/banner.failsafe/& || \/usr\/bin\/idz/' /etc/profile
chmod -R +x /sbin
chmod -R +x /usr/bin
chmod +x /usr/lib/ModemManager/connection.d/10-report-down

# netdata
mv /usr/share/netdata/web/lib/jquery-3.6.0.min.js /usr/share/netdata/web/lib/jquery-2.2.4.min.js

# Setup Auto Vnstat Database Backup
echo "Setup Auto Vnstat Database Backup"
mkdir /etc/vnstat
chmod +x /etc/init.d/vnstat_backup
bash /etc/init.d/vnstat_backup enable

# vnstati
echo "configuring netdata"
chmod +x /www/vnstati/vnstati.sh
/etc/init.d/netdata restart
/etc/init.d/vnstat restart
/www/vnstati/vnstati.sh

# Setting Tinyfm
ln -s / /www/tinyfm/rootfs

# configurating openclash
if opkg list-installed | grep luci-app-openclash > /dev/null; then
  echo "Openclash Detected!"
  echo "Configuring Core..."
  chmod +x /etc/openclash/core/clash_meta
  chmod +x /etc/openclash/GeoIP.dat
  chmod +x /etc/openclash/GeoSite.dat
  chmod +x /etc/openclash/Country.mmdb
  chmod +x /usr/bin/patchoc.sh
  echo "Patching Openclash Overview"
  bash /usr/bin/patchoc.sh
  sed -i '/exit 0/i #/usr/bin/patchoc.sh' /etc/rc.local
  ln -s /etc/openclash/history/Quenx.db /etc/openclash/cache.db
  ln -s /etc/openclash/core/clash_meta  /etc/openclash/clash
  rm -rf /etc/config/openclash
  rm -rf /etc/openclash/custom
  rm -rf /etc/openclash/game_rules
  rm -rf /usr/share/openclash/openclash_version.sh
  find /etc/openclash/rule_provider -type f ! -name "*.yaml" -exec rm -f {} \;
  mv /etc/config/openclash1 /etc/config/openclash
  echo "setup complete!"
else
  echo "No Openclash Detected."
  rm -rf /etc/config/openclash1
  rm -rf /etc/openclash
fi

# configurating Nikki
if opkg list-installed | grep luci-app-nikki > /dev/null; then
  echo "setup complete!"
  chmod +x /etc/nikki/run/GeoIP.dat
  chmod +x /etc/nikki/run/GeoSite.dat
else
  echo "No Nikki Detected."
  rm -rf /etc/config/nikki
  rm -rf /etc/nikki
fi

# Setup PHP
echo "setup php"
uci set uhttpd.main.ubus_prefix='/ubus'
uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
uci set uhttpd.main.index_page='cgi-bin/luci'
uci add_list uhttpd.main.index_page='index.html'
uci add_list uhttpd.main.index_page='index.php'
uci commit uhttpd
sed -i -E "s|memory_limit = [0-9]+M|memory_limit = 100M|g" /etc/php.ini
sed -i -E "s|display_errors = On|display_errors = Off|g" /etc/php.ini
ln -s /usr/bin/php-cli /usr/bin/php
[ -d /usr/lib/php8 ] && [ ! -d /usr/lib/php ] && ln -sf /usr/lib/php8 /usr/lib/php
/etc/init.d/uhttpd restart

echo "All first boot setup complete!"
rm -f /etc/uci-defaults/$(basename $0)
exit 0