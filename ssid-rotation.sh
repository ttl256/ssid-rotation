#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

#Output to file or stdout?
if [ $# == 0 ]; then
	file=/dev/stdout
	noFile=1
else
	file=/home/wlanpi/$1
fi

declare -i counter

if [ -f $file ]; then
	echo "Such file already exists and its contents will be wiped"
	echo "Proceed? y/n: " && read line
	if [[ $line != "y" ]]; then
		exit 1
	fi
fi

#Actual script begins
touch $file && cat /dev/null > $file
echo "Press Enter to start"

#The loop will be called every time we read <CR> from stdin
while read line
do
	#Generate 6 bytes in hex for SSID
	random_set=$(xxd -p -l 6 /dev/urandom)

	systemctl stop hostapd
	#hostapd behavior is more predictible if we let it sleep for a bit
	sleep 1
	sed -i /^ssid/s/=.*/"=LAB $random_set"/ /etc/hostapd/hostapd.conf
	systemctl start hostapd && counter=$counter+1
	#Output counter to a file if provided
	if [[ $noFile != 1 ]]; then
		echo $counter > $file
	fi	

	echo "SSID: \"LAB $random_set\""
	echo "Counter: $counter"

done < /dev/stdin
