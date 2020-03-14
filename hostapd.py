#!/usr/bin/env python
import signal
import sys
from os import system

NetworkManager = """[main]
plugins=keyfile

[keyfile]"""

def signal_handler(sig, frame):
	print("\nClosing...\n")
	FileWrite = open("/etc/NetworkManager/NetworkManager.conf", 'w')
	FileWrite.write(NetworkManager)
	system("sudo mv /etc/NetworkManager/NetworkManager.conf.backup /etc/NetworkManager/NetworkManager.conf; rm hostapd.conf; sudo service network-manager restart; sudo /etc/init.d/dnsmasq stop > /dev/null 2>&1; sudo pkill dnsmasq; sudo iptables --flush; sudo iptables --flush -t nat; sudo iptables --delete-chain; sudo iptables --table nat --delete-chain; iwconfig wlan0 mode managed > /dev/null 2>&1; sudo ifconfig wlan0 up > /dev/null 2>&1; iwconfig wlan1 mode managed > /dev/null 2>&1; sudo ifconfig wlan1 up > /dev/null 2>&1; iwconfig wlan2 mode managed > /dev/null 2>&1; sudo ifconfig wlan2 up > /dev/null 2>&1; airmon-ng stop wlan0mon > /dev/null 2>&1; airmon-ng stop wlan1mon > /dev/null 2>&1; airmon-ng stop wlan2mon > /dev/null 2>&1;")

signal.signal(signal.SIGINT, signal_handler)
print('\nPress Ctrl+C to quit...\n')
system("sudo hostapd hostapd.conf")
print("\nPress Ctrl+C again.")
signal.pause()

