#!/bin/sh
#
#   fet.sh
# a fetch in pure POSIX shell
#

# supress errors
exec 2>/dev/null
set --
_() {  # [ a = b ] with globbing
	case $1 in
		$2) return
	esac;! :
}

## Terminal
while [ ! "$term" ]; do
	# loop over lines in /proc/pid/status until it reaches PPid
	# then save that to a variable and exit the file
	while read -r line; do
		_ "$line" "PPid*" && ppid=${line##*:?} && break
	done < "/proc/${ppid:-$PPID}/status"

	# get name of binary
	read -r name < "/proc/$ppid/comm"
	case $name in
		*sh|"${0##*/}") ;;  # skip shells
		*[Ll]ogin*|*init*) break;;  # exit when the top is reached
		*) term="$name"  # anything else can be assumed to be the terminal
	esac
done

## WM/DE
# standard variables, mostly used for DEs
if [ "$XDG_CURRENT_DESKTOP" ]; then
	wm="$XDG_CURRENT_DESKTOP"
elif [ "$DESKTOP_SESSION" ]; then
	wm="$DESKTOP_SESSION"
elif [ "$DISPLAY" ]; then
	# non-standard WMs
	# loop over all processes and check the binary name
	for i in /proc/*/comm; do
		read -r c < "$i"
		case $c in
			awesome|xmonad|qtile|i3*|*box*|*wm*) wm="$c"; break;;
		esac
	done
fi

## Distro
o=/etc/os-release
[ -f $o ] && . $o   # a common file that has variables about the distro

## Memory
# loop over lines in /proc/meminfo until it reaches MemTotal,
# then convert the amount (second word) from KB to MB
while read -r line; do
	_ "$line" "MemTotal*" && set -- $line && break
done < /proc/meminfo
mem="$(( $2 / 1000 ))MB"

## Processor
while read -r line; do
	case $line in
		vendor_id*) vendor="${line##*: } ";;
		model\ name*) cpu="${line##*: }"; break;;
	esac
done < /proc/cpuinfo
vendor="${vendor##*Authentic}"
vendor="${vendor##*Genuine}"
# this is so messy due to so many inconsistencies in the model names
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
[ "$d" -gt 0 ] && up="${d}d $up"

## Kernel
read -r _ _ version _ < /proc/version
kernel="${version%%-*}"
_ "$version" "*Microsoft*" && ID="fake $ID"

## GTK
while read -r line; do
	_ "$line" "gtk-theme*" && gtk="${line##*=}" && break
done < "${XDG_CONFIG_HOME:-$HOME/.config}"/gtk-3.0/settings.ini

## Motherboard // laptop
read -r model < /sys/devices/virtual/dmi/id/product_name

## Packages
# clean environment, then make every file in the dir an argument,
# then save the argument count to $pkgs
set --
[ -d /var/db/kiss/installed ] && set -- /var/db/kiss/installed/*
[ -d /var/lib/pacman/local  ] && set -- /var/lib/pacman/local/*
[ -d /var/db/xbps ] && set -- /var/db/xbps/.*
[ -d /var/db/pkg  ] && set -- /var/db/pkg/*/*  # gentoo
[ $# -gt 0 ] && pkgs=$#

col() {
	printf '  '
	for i in 1 2 3 4 5 6; do
		printf '\033[9%sm▅▅' "$i"
	done
	printf '\033[0m\n'
}

print() {
	[ "$2" ] && printf '\033[9%sm%6s\033[0m%b%s\n' \
		"${accent:-4}" "$1" "${separator:- ~ }" "$2"
}

read -r host < /proc/sys/kernel/hostname

# default value
: "${info:=n user os sh wm up gtk cpu mem host kern pkgs term col n}"

for i in $info; do
	case $i in
		n) echo;;
		os) print os "$ID";;
		sh) print sh "${SHELL##*/}";;
		wm) print wm "$wm";;
		up) print up "$up";;
		gtk) print gtk "${gtk# }";;
		cpu) print cpu "$vendor$cpu";;
		mem) print mem "$mem";;
		host) print host "$model";;
		kern) print kern "$kernel";;
		pkgs) print pkgs "$pkgs";;
		term) print term "$term";;
		user) printf '%7s@%s\n' "$USER" "$host";;
		col) col;;
	esac
done
