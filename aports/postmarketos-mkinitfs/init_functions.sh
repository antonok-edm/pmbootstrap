#!/bin/sh
# This file will be in /init_functions.sh inside the initramfs.

log() {
	echo "[$1] $2" >> /tmp/boot.log
}

mount_subpartitions() {
	for i in /dev/mmcblk*; do
		case "$(kpartx -l "$i" 2> /dev/null | wc -l)" in
			2)
				echo "mount subpartitions of $i"
				kpartx -afs "$i"
				break
				;;
			*)
				continue
				;;
		esac
	done
}

find_root_partition() {
	DEVICE=$(blkid | grep "crypto_LUKS" | tail -1 | cut -d ":" -f 1)

	if [ -z "$DEVICE" ]; then
		DEVICE=$(blkid | grep "pmOS_root" | tail -1 | cut -d ":" -f 1)
	fi

	log "info" "root partition is $DEVICE"

	echo $DEVICE
}

unlock_root_partition() {
	log "info" "unlock_root_partition()"
	while ! [ -e /dev/mapper/root ]; do
		partition="$(find_root_partition)"
		if [ -z "$partition" ]; then
			echo "Could not find the root partition."
			echo "Maybe you need to insert the sdcard, if your device has"
			echo "any? Trying again in one second..."
			sleep 1
		else
			if $(cryptsetup isLuks "$partition"); then
				cryptsetup luksOpen "$partition" root || continue
				log "info" "unlocked $partition"
			else
				log "info" "unencrypted $partition"
				break
			fi
		fi
	done
}

# $1: path to ppm.gz file
show_splash() {
	log "info" "show_splash $1"
	gzip -c -d "$1" > /tmp/splash.ppm
	fbsplash -s /tmp/splash.ppm
}

mount_proc_sys_dev() {
	# mdev
	mount -t proc -o nodev,noexec,nosuid proc /proc
	mount -t sysfs -o nodev,noexec,nosuid sysfs /sys

	# /dev/pts (needed for telnet)
	mkdir -p /dev/pts
	mount -t devpts devpts /dev/pts
}

start_mdev() {
	echo /sbin/mdev > /proc/sys/kernel/hotplug
	mdev -s
}

usb_setup_android() {
    # only run once
    _marker="/tmp/_usb_setup_android"
    [ -e "$_marker" ] && return
    touch "$_marker"

    # only run, when we have the android usb driver
	SYS=/sys/class/android_usb/android0
	[ -e "$SYS" ] || return

    # do the setup
	printf "%s" "0"		> "$SYS/enable"
	printf "%s" "18D1"	> "$SYS/idVendor"
	printf "%s" "D001"	> "$SYS/idProduct"
	printf "%s"	"rndis"	> "$SYS/functions"
	printf "%s" "1"		> "$SYS/enable"
}

dhcpcd_start() {
    # only run once
    [ -e /etc/udhcpd.conf ] && return

	# get usb interface
	INTERFACE=""
	ifconfig rndis0 "$IP" && INTERFACE=rndis0
	if [ -z $INTERFACE ]; then
		ifconfig usb0 "$IP" && INTERFACE=usb0
	fi

	# create /etc/udhcpd.conf
	{
		echo "start 172.16.42.2"
		echo "end 172.16.42.254"
		echo "lease_file /var/udhcpd.leases"
		echo "interface $INTERFACE"
		echo "option subnet 255.255.255.0"
	} > /etc/udhcpd.conf

    # start the dhcpcd daemon (forks into background)
	udhcpd
}
