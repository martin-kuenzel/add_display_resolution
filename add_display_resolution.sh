#!/bin/bash
IFS=$'\n'

_help(){
cat <<HLP
Add new display resolutions to outputs 
this might be helpful in case that particular resolutions are not natively recognized by the window managers display settings

Warning ... using bad resolution settings might damage your hardware!

    h: display this help text
    x: x resolution
    y: y resolution
    d: output to use
    p: [0,1] only print the xrandr commands at the end ? (default 0)
    examples:
        $(basename $0) -x 1920 -y 1600 -d VGA-1 -p # only prints the commands for the assignment
        $(basename $0) -x 1920 -y 1600 -d VGA-1
HLP
}

# run the xrandr command at the end ?
RES_DRY=0

while getopts 'hpx:y:d:' OPT; do 
    case $OPT in 
        x) RES_X=$OPTARG;;
        y) RES_Y=$OPTARG;;
        d) RES_OUTPUT=$OPTARG;;
        p) RES_DRY=1;;
        h) _help && exit 0;;
    esac; 
done;

# the script requires root permissions to be run
[ "$(whoami)" != "root" ] && ( echo "you need to be root to run this script"; exit 1; )

# check for existance of all required options
( [ -z $RES_X ] || [ -z $RES_Y ] || [ -z $RES_OUTPUT ]; ) && ( _help; exit 1; )

# create the modeline to be used
echo -n "Creating modeline ... "
MODELINE=$( cvt $RES_X $RES_Y | tail -1 | sed 's|^[^[:space:]]*[[:space:]]*||' );
MODE=$(IFS=$'\n'; echo $MODELINE | cut -d\  -f 1|sed 's|"||g')
echo "received $MODE"

# construct the xrandr commandline string
XRANDR_COMMAND="xrandr --newmode $MODELINE 2>/dev/null; xrandr --addmode $RES_OUTPUT $MODE"

[ $RES_DRY -eq 1 ] && cat <<T 
Try to run the following command to add the resolution:
$XRANDR_COMMAND
T

# if option -r was given, we will try to add the mode for the output
[ $RES_DRY -eq 0 ] && (
    echo -en "\nTrying to add $MODE to the given output $RES_OUTPUT ... "

    # try to delete the mode, so we don't run in any errors if it allready exists
    xrandr --delmode $RES_OUTPUT "$MODE" 2>/dev/null;
    
    ## WORTH MENTIONING THAT THIS WOULD REMOVE THE MODE ENTIRELY (NOT ONLY FOR THE GIVEN OUTPUT)
    #xrandr --rmmode "$MODE" 2>/dev/null; 

    # try to run the add command for the mode and the given output
    OUTPUT=""
    OUTPUT=$(sh -c "$XRANDR_COMMAND" 2>&1)
    ( [ $? -eq 0 ] && echo "Success"; ) || (
        echo -e "Error\n\n$OUTPUT\n";
        echo -e "There was an error while trying to add the mode $MODE for $RES_OUTPUT, maybe output $RES_OUTPUT doesn't exist ?";
    )
)

exit 0;
