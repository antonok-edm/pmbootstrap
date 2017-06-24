#!/bin/sh
IP=172.16.42.1
TELNET_PORT=23

telnetd_start() {
	# Start telnet in background, and only allow to unlock the root
	# partition on connect. Install the usb-shell hook to get a full
	# shell for debugging.
	{
		echo '#!/bin/sh'
		echo '. /init_functions.sh'
		echo 'unlock_root_partition'
		echo 'killall cryptsetup telnetd'
	} > /telnet_connect.sh
	chmod +x /telnet_connect.sh
	telnetd -b "${IP}:${TELNET_PORT}" -l /telnet_connect.sh
}

partition="$(find_root_partition)"
if cryptsetup isLuks "$partition"; then
	log "info" "password needed to decrypt $partition, launching telnetd"
	show_splash /splash1.ppm.gz # usb unlock message
	usb_setup_android
	dhcpcd_start
	telnetd_start
fi

