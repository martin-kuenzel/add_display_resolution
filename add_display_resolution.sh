#!/bin/bash
# $1=x, $2=y, $3=DEVICE (eg. VGA-1)
IFS=$'\n'
[ "$(whoami)" != "root" ] && { echo "not root"; exit 1; }

DEV=$3
[ -z $3 ] && DEV="VGA-1"; # defaults to the most common, which is VGA-1, but don't count on it :P

MODELINE=$( cvt $1 $2 | tail -1 | sed 's|^[^[:space:]]*[[:space:]]*||' ); 
MODE=$(IFS=$'\n'; echo $MODELINE | cut -d\  -f 1|sed 's|"||g')
sh -c "xrandr --newmode $MODELINE && xrandr --addmode $DEV $MODE"

exit 0;
