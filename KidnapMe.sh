#!/bin/sh

echo "\n\nChecking for hostapd..."
if command -v hostapd > /dev/null 2>&1 ; then
    echo "hostapd is installed.\n"
else
    echo "hostapd is NOT installed. Installing..."
    apt-get install hostapd -y > /dev/null 2>&1
    if command -v hostapd > /dev/null 2>&1 ; then
		echo "hostapd installed successfully.\n"
	else
		echo "hostapd FAILED to install. Closing...\n"
		exit
	fi
fi

echo "Checking for dnsmasq..."
if command -v dnsmasq > /dev/null 2>&1 ; then
    echo "dnsmasq is installed.\n"
else
    echo "dnsmasq is NOT installed. Installing..."
    apt-get install dnsmasq -y > /dev/null 2>&1
    if command -v dnsmasq > /dev/null 2>&1 ; then
		echo "dnsmasq installed successfully.\n"
	else
		echo "dnsmasq FAILED to install. Closing...\n"
		exit
	fi
fi

echo "Checking for aircrack-ng..."
if command -v aircrack-ng > /dev/null 2>&1 ; then
    echo "aircrack-ng is installed.\n"
else
    echo "aircrack-ng is NOT installed. Installing..."
    apt-get install aircrack-ng -y > /dev/null 2>&1
    if command -v aircrack-ng > /dev/null 2>&1 ; then
		echo "aircrack-ng installed successfully.\n"
	else
		echo "aircrack-ng FAILED to install. Closing...\n"
		exit
	fi
fi

echo "Checking for xterm..."
if command -v xterm > /dev/null 2>&1 ; then
    echo "xterm is installed.\n"
else
    echo "xterm is NOT installed. Installing..."
    apt-get install xterm -y > /dev/null 2>&1
    if command -v xterm > /dev/null 2>&1 ; then
		echo "xterm installed successfully.\n"
	else
		echo "xterm FAILED to install. Closing...\n"
		exit
	fi
fi

echo -n "\nSSID: "
read SSID

echo -n "Password (Blank if none): "
read PASSWORD

echo -n "BSSID (Blank for default): "
read BSSID
BSSID=${BSSID:-"00:00:00:00:00:00"}

echo -n "Gateway address (Blank for default): "
read GATEWAY
GATEWAY=${GATEWAY:-"192.168.1.1"}

echo -n "Channel (Blank for default): "
read CHANNEL
CHANNEL=${CHANNEL:-"11"}

echo -n "AP Interface: "
read IFACE

echo -n "Internet connected interface: "
read NET_IFACE

sudo service network-manager stop
sudo cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.backup
echo "[main]\nplugins=keyfile\n\n[keyfile]\nunmanaged-devices=interface-name:$IFACE\n" > /etc/NetworkManager/NetworkManager.conf
sudo ifconfig $IFACE up

sudo iptables --flush
sudo iptables --table nat --flush
sudo iptables --delete-chain
sudo iptables --table nat --delete-chain
sudo iptables --table nat --append POSTROUTING --out-interface $NET_IFACE -j MASQUERADE
sudo iptables --append FORWARD --in-interface $IFACE -j ACCEPT

sudo ifconfig $IFACE up $GATEWAY netmask 255.255.255.0 > /dev/null 2>&1

sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1

echo -n "" > dnsmasq.conf

echo "no-resolv" >> dnsmasq.conf
echo "interface=$IFACE" >> dnsmasq.conf

RANGE=${GATEWAY%?}

echo -n "dhcp-range=" >> dnsmasq.conf

echo -n $RANGE >> dnsmasq.conf

echo -n "3," >> dnsmasq.conf

echo -n $RANGE >> dnsmasq.conf

echo "20,12h" >> dnsmasq.conf
echo "server=8.8.8.8" >> dnsmasq.conf
echo "server=$GATEWAY" >> dnsmasq.conf

sudo mv dnsmasq.conf /etc/dnsmasq.conf > /dev/null 2>&1

sudo /etc/init.d/dnsmasq stop > /dev/null 2>&1
sudo killall dnsmasq > /dev/null 2>&1
sudo pkill dnsmasq > /dev/null 2>&1
sudo dnsmasq > /dev/null 2>&1

echo -n "" > hostapd.conf
echo "#################################" >> hostapd.conf
echo "interface=$IFACE" >> hostapd.conf
echo "driver=nl80211" >> hostapd.conf
echo "country_code=US" >> hostapd.conf
echo "ssid=$SSID" >> hostapd.conf
echo "bssid=$BSSID" >> hostapd.conf
echo "ignore_broadcast_ssid=0" >> hostapd.conf

if [ -z "$PASSWORD" ]; then
	echo "No WPA2 Key..."
else
	echo "wpa=2" >> hostapd.conf
	echo "wpa_key_mgmt=WPA-PSK" >> hostapd.conf
	echo "wpa_pairwise=CCMP" >> hostapd.conf
	echo "rsn_pairwise=CCMP" >> hostapd.conf
	echo "wpa_passphrase=$PASSWORD" >> hostapd.conf
fi

echo "max_num_sta=5" >> hostapd.conf
echo "# IEEE 802.11ac" >> hostapd.conf
echo "hw_mode=g" >> hostapd.conf
echo "channel=$CHANNEL" >> hostapd.conf
echo "ieee80211ac=1" >> hostapd.conf
echo "ieee80211n=1" >> hostapd.conf

echo "logger_stdout=-1" >> hostapd.conf
echo "logger_stdout_level=2" >> hostapd.conf
echo "#################################" >> hostapd.conf

#LET'S GO#
echo "Starting Hostapd..."
xterm -T "Kidnap Me!" -e "cd $PWD; sudo hostapd hostapd.conf"
#read -p "Press enter to quit: " unused

echo "Cleaning up..."
sudo mv /etc/NetworkManager/NetworkManager.conf.backup /etc/NetworkManager/NetworkManager.conf > /dev/null 2>&1

echo "" > /etc/NetworkManager/NetworkManager.conf
echo "[main]" >> /etc/NetworkManager/NetworkManager.conf
echo "plugins=keyfile" >> /etc/NetworkManager/NetworkManager.conf
echo "" >> /etc/NetworkManager/NetworkManager.conf
echo "[keyfile]" >> /etc/NetworkManager/NetworkManager.conf

rm hostapd.conf > /dev/null 2>&1
sudo service network-manager restart > /dev/null 2>&1
sudo /etc/init.d/dnsmasq stop > /dev/null 2>&1
sudo pkill dnsmasq
sudo iptables --flush
sudo iptables --flush -t nat
sudo iptables --delete-chain
sudo iptables --table nat --delete-chain
iwconfig wlan0 mode managed > /dev/null 2>&1
sudo ifconfig wlan0 up > /dev/null 2>&1
iwconfig wlan1 mode managed > /dev/null 2>&1
sudo ifconfig wlan1 up > /dev/null 2>&1
iwconfig wlan2 mode managed > /dev/null 2>&1
sudo ifconfig wlan2 up > /dev/null 2>&1
airmon-ng stop wlan0mon > /dev/null 2>&1
airmon-ng stop wlan1mon > /dev/null 2>&1
airmon-ng stop wlan2mon > /dev/null 2>&1;
echo "Closing..."
