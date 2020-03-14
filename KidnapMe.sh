#!/bin/sh

echo "\nChecking for hostapd..."
if command -v hostapd > /dev/null 2>&1 ; then
    echo "hostapd is installed.\n"
else
    echo "hostapd is NOT installed. Installing..."
    apt-get install hostapd > /dev/null 2>&1
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
    apt-get install dnsmasq > /dev/null 2>&1
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
    apt-get install aircrack-ng > /dev/null 2>&1
    if command -v aircrack-ng > /dev/null 2>&1 ; then
		echo "aircrack-ng installed successfully.\n"
	else
		echo "aircrack-ng FAILED to install. Closing...\n"
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

echo -n "Channel: "
read CHANNEL

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
sudo killall dnsmasq
sudo pkill dnsmasq
sudo dnsmasq 

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


#Not quite finished with this... UNDER CONSTRUCTION!!!
#read -p "Deauth interface (Blank if no deauth): " DEAUTH
#if [ -z "$DEAUTH" ]; then
#	echo "No deauth-ing..."
#else
#	airmon-ng start $DEAUTH > /dev/null 2>&1
#	DEAUTH="$DEAUTHmon"
#	echo "RUNNING: airodump-ng $DEAUTH"
#	gnome-terminal --command "airodump-ng $DEAUTH" > /dev/null 2>&1
#	read -p "Target BSSID: " T_BSSID
#	read -p "Target client (Blank if all): " T_MAC
#	if [ -z "$T_MAC" ]; then
#	echo "No target client..."
#	else
#		T_MAC=" -c $T_MAC "
#	fi
#	echo "RUNNING: aireplay-ng --deauth 1000 -a $T_BSSID $T_MAC --ignore-negative-one $DEAUTH"
#	gnome-terminal --command "aireplay-ng --deauth 1000 -a $T_BSSID $T_MAC --ignore-negative-one $DEAUTH" > /dev/null 2>&1
#fi



#LET'S GO#
#Loophole to allow for CTRL + C. Bash doesn't...
python hostapd.py
#LET'S GO#
#LET'S GO#
