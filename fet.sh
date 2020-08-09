#!/bin/sh
#
#  this is my attempt at trying to make a fetch using only posix shell
#   without any external commands
#

# supress errors
exec 2>/dev/null

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
	o="$ppid"
	ppid=$(ppid "$ppid")
	[ "$o" = "$ppid" ] && break
done

## WM/DE
pg() {
	unset ab var
	# i hate myself for this
	for i in "$@"; do
		var="${var:+$var|}*$i*"
	done
	for i in /proc/[0-9]*; do
		ab="$ab ${i##*/}"
		read -r a < "$i"/comm
		# this was sadly the better option...
		eval "case \$a in
			$var) echo \"\$a\" \"\${i##*/}\"; break;;
		esac"
	done
}

if [ "$XDG_CURRENT_DESKTOP" ]; then
	wm="$XDG_CURRENT_DESKTOP"
elif [ "$DESKTOP_SESSION" ]; then
	wm="$DESKTOP_SESSION"
elif [ "$DISPLAY" ]; then
	xorg="$(pg Xorg)"
	xorg="${xorg##* }"
	aa="$(pg wm monad box i3 tile)"
	# make sure it was started near enough after the X server
	[ "${aa##* }" -gt "$xorg" ] &&
		[ "${aa##* }" -lt "$((xorg + 30))" ] &&
		wm="${aa%% *}"
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
d="$((uptime / 60 / 60 / 24))"
h="$((uptime / 60 / 60 % 24))"
m="$((uptime / 60 % 60))"

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
# horribly inefficient, I know.
[ -d /var/lib/pacman/local ] && {
	set -- $(echo /var/lib/pacman/local/*)
	pkgs=$#
}

[ -d /var/db/xbps ] && {
	set -- $(echo /var/db/xbps/.*)
	pkgs=$#
}

[ -d /var/db/pkg ] && {
	set -- $(echo /var/db/pkg/*/*)
	pkgs=$#
}

print() {
	printf '\033[34m%6s\033[0m | %s\n' "$1" "$2"
}

[ "$ID" ] && print os "$ID"
[ "$SHELL" ] && print sh "${SHELL##*/}"
[ "$wm" ] && print wm "$wm"
[ "$m" ] && print up "${d}d ${h}:${m}"
[ "$gtk" ] && print gtk "$gtk"
[ "$cpu" ] && print cpu "$vendor $cpu"
[ "$mem" ] && print mem "${mem}MB"
[ "$model" ] && print host "$model"
[ "$kernel" ] && print kern "$kernel"
[ "$term" ] && print term "$term"
[ "$pkgs" ] && print "pkgs" "$pkgs"
