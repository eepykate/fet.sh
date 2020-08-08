#!/bin/sh
#
#  this is my attempt at trying to make a fetch using only posix shell
#   without any external commands
#

## Terminal
ppid() {
	while read -r line; do
		case $line in
			PPid*) echo "${line##*:?}"; break;;
		esac
	done < /proc/"$1"/status
}

while [ ! "$term" ]; do
	read -r name < "/proc/${ppid:=$$}/comm"
	case $name in
		*sh) ;;
		"${0##*/}") ;;
		*[Ll]ogin*|*init*) term=linux;;
		*) term="$name";;
	esac
	ppid=$(ppid "$ppid")
done

## WM
# requires the WM to include 'wm'
pg() {
	ab=
	for i in /proc/[0-9]*; do
		ab="$ab ${i##*/}"
		read -r a < "$i"/comm
		case $a in
			*$1*) echo "$a" "${i##*/}"; break;;
		esac
	done
}
[ "$DISPLAY" ] && {
	xorg="$(pg Xorg)"
	xorg="${xorg##* }"
	aa="$(pg wm)"
	# make sure it was started near enough after the X server
	[ "${aa##* }" -gt "$xorg" ] &&
		[ "${aa##* }" -lt "$((xorg + 20))" ] &&
		wm="${aa%% *}"
}

## Distro
. /etc/os-release   # lol EZ

## Memory
while read -r line; do
	case $line in
		MemTotal*) mem="${line##*: }"; break;;
	esac
done < /proc/meminfo
mem="${mem##*  }"
mem="${mem%% *}"

mem="$(( mem / 1000 ))"

## Processor
# can't really test on AMD. Please make an issue if it doesn't work
while read -r line; do
	case $line in
		vendor_id*) vendor="${line##*: }";;
		model\ name*) cpu="${line##*: }"; break;;
	esac
done < /proc/cpuinfo
vendor="${vendor##*Authentic}"
vendor="${vendor##*Genuine}"
cpu="${cpu##*) }"
cpu="${cpu%% @*}"
cpu="${cpu%% CPU}"
cpu="${cpu##CPU }"
cpu="${cpu##*AMD }"
cpu="${cpu%% with*}"

## Uptime
# the simple math is shamefully stolen from aosync
IFS=. read -r uptime _ < /proc/uptime
d="$((uptime / 60 / 60 / 24))"
h="$((uptime / 60 / 60 % 24))"
m="$((uptime / 60 % 60))"

## Kernel
read -r version < /proc/version
set -- $version
kernel="${3%%-*}"

## GTK
# why not..?
while read -r line; do
	case $line in
		gtk-theme*) gtk="${line##*=}"; break;;
	esac
done < "${XDG_CONFIG_HOME:-$HOME/.config}"/gtk-3.0/settings.ini

## Motherboard // laptop
read -r model < /sys/devices/virtual/dmi/id/product_name

## Packages
# horribly inefficient, I know.
[ -d /var/lib/pacman/local ] && {
	pkgs=0
	for _ in /var/lib/pacman/local/*; do
		pkgs=$(( pkgs + 1 ))
	done
}

[ -d /var/db/xbps ] && {
	pkgs=0
	for _ in /var/db/xbps/.*; do
		pkgs=$(( pkgs + 1 ))
	done
}

[ -d /var/db/pkg ] && {
	pkgs=0
	for _ in /var/db/pkg/*/*; do
		pkgs=$(( pkgs + 1 ))
	done
}

print() {
	printf '\033[34m%6s\033[0m | %s\n' "$1" "$2"
}

print os "$ID"
print sh "${SHELL##*/}"
[ "$wm" ] && print wm "$wm"
print up "${d}d ${h}:${m}"
[ "$gtk" ] && print gtk "$gtk"
print cpu "$vendor $cpu"
print mem "${mem}MB"
print host "$model"
print kern "$kernel"
print term "$term"
[ "$pkgs" ] && print "pkgs" "$pkgs"
