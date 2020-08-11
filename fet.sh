#!/bin/sh
#
#  this is my attempt at trying to make a fetch using only posix shell
#   without any external commands
#

# supress errors
exec 2>/dev/null
set --

## Terminal
while [ ! "$term" ]; do
	while IFS=':	' read -r key val; do
		case $key in
			PPid) ppid=$val; break;;
		esac
	done < "/proc/${ppid:-$PPID}/status"

	read -r name < "/proc/$ppid/comm"
	case $name in
		*sh) ;;
		"${0##*/}") ;;
		*[Ll]ogin*|*init*) term=linux;;
		*) term="$name";;
	esac
done

## WM/DE
if [ "$XDG_CURRENT_DESKTOP" ]; then
	wm="$XDG_CURRENT_DESKTOP"
elif [ "$DESKTOP_SESSION" ]; then
	wm="$DESKTOP_SESSION"
elif [ "$DISPLAY" ]; then
	for i in /proc/*/comm; do
		read -r c < "$i"
		case $c in
			awesome|xmonad|qtile|i3*|*box*|*wm*) wm="$c"; break;;
		esac
	done
fi

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
cpu="${cpu% *-Core*}"

## Uptime
# the simple math is shamefully stolen from aosync
IFS=. read -r uptime _ < /proc/uptime
d=$((uptime / 60 / 60 / 24))
up=$(printf %02d:%02d $((uptime / 60 / 60 % 24)) $((uptime / 60 % 60)))

## Kernel
read -r _ _ version _ < /proc/version
kernel="${version%%-*}"
case $version in
	*Microsoft*) [ "$ID" ] && ID="fake $ID";;
esac

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
[ -d /var/lib/pacman/local ] && set -- /var/lib/pacman/local/*
[ -d /var/db/xbps ] && set -- /var/db/xbps/.*
[ -d /var/db/pkg ] && set -- /var/db/pkg/*/*
[ $# -gt 0 ] && pkgs=$#

print() {
	printf '\033[34m%6s\033[0m | %s\n' "$1" "$2"
}

[ "$ID" ] && print os "$ID"
[ "$SHELL" ] && print sh "${SHELL##*/}"
[ "$wm" ] && print wm "$wm"
[ "$d" ]  && print up "${d}d $up"
[ "$gtk" ] && print gtk "${gtk# }"
[ "$cpu" ] && print cpu "$vendor $cpu"
[ "$mem" ] && print mem "${mem}MB"
[ "$model" ] && print host "$model"
[ "$kernel" ] && print kern "$kernel"
[ "$term" ] && print term "$term"
[ "$pkgs" ] && print "pkgs" "$pkgs"
