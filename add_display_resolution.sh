#!/bin/bash
IFS=$'\n'

_help(){
cat <<HLP
Add new display resolutions to outputs 
this might be helpful in case that particular resolutions are not natively recognized by the window managers display settings

Warning ... using bad resolution settings might damage your hardware!

    -h: display this help text
    
    -x: the x resolution
    -y: the y resolution
    -o: the output to use

    -C: [0,1] use whiptail GUI (default 0) ( the options x,y and d wont be used if this is activated )
    -P: [0,1] only print the xrandr commands at the end ? (default 0)
    
    -O: try to get a list of all available outputs from xrandr and print it
    
    examples:
        $(basename $0) -x 1920 -y 1600 -o VGA-1 -P # only prints the commands for the assignment
        $(basename $0) -x 1920 -y 1600 -o VGA-1
HLP
}

_list_outputs(){
    echo -e "\nPossible outputs are:"
    xrandr 2>&1|sed -re '/^[[:space:]]/d'|tail +2|awk '{print $1}'
}

## USE ZENITY FOR GTK LIKE MENU
# zenity  --forms --add-entry 'x' --add-entry 'y' --add-list 'Output' --list-values "$(echo $(xrandr 2>&1|sed -re '/^[[:space:]]/d'|tail +2|awk '{print "|"$1}'|grep -v '^|*$')|sed -re 's/(^\||\s)//g')" | cut -d\| -f1

# run the xrandr command at the end ?
RES_DRY=0

# use the whiptail GUI ?
RES_USE_WHIPTAIL=0

while getopts 'x:y:o:hPOC' OPT; do 
    case $OPT in 
        h) _help && exit 0;;
        
        x) RES_X=$OPTARG;;
        y) RES_Y=$OPTARG;;
        o) RES_OUTPUT=$OPTARG;;

        P) RES_DRY=1;;
        O) _list_outputs && exit 0;;
        C) RES_USE_WHIPTAIL=1 ;;
    esac; 
done;

# the script requires root permissions to be run
[ "$(whoami)" != "root" ] && { echo "you need to be root to run this script"; exit 1; }

## use whiptail if option -C is given
[ $RES_USE_WHIPTAIL -eq 1 ] && {
    for i in $(xrandr 2>&1|sed -re '/^[[:space:]]/d'|tail +2|awk '{print $1}'|sed -r 's/^(.*)$/\1\n/'); do
        RES_OUTPUTS_AVAILABLE+=($i "")
    done
    
    ## why "3>&1 1>&2 2>&3" !!?? (-.-) $1 and $2 get swapped by whiptail and 
    ## due to the assignment of the variables nothing is shown and the terminal gets stuck (found here https://stackoverflow.com/a/1970254)
    RES_X=$(whiptail --title "add_display_resolution" --inputbox "x" 0 50 3>&1 1>&2 2>&3 );
    RES_Y=$(whiptail --title "add_display_resolution" --inputbox "y" 0 50 3>&1 1>&2 2>&3);
    RES_OUTPUT=$(whiptail --title "add_display_resolution" --menu "select output" 0 50 0 "${RES_OUTPUTS_AVAILABLE[@]}" 3>&1 1>&2 2>&3);
}


# check for existance of all required options
( [ -z $RES_X ] || [ -z $RES_Y ] || [ -z $RES_OUTPUT ]; ) && { tput setaf 1; echo -e "\n\tWrong use! both x and y resolution and the output need to be specified.!\n"; tput sgr0; _help; exit 1; }

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
[ $RES_DRY -eq 0 ] && {
    echo -en "Trying to add $MODE to the given output $RES_OUTPUT ... "

    # try to delete the mode, so we don't run in any errors if it already exists
    xrandr --delmode $RES_OUTPUT "$MODE" 2>/dev/null;
    
    ## WORTH MENTIONING THAT THIS WOULD REMOVE THE MODE ENTIRELY (NOT ONLY FOR THE GIVEN OUTPUT)
    #xrandr --rmmode "$MODE" 2>/dev/null; 

    # try to run the add command for the mode and the given output
    OUTPUT=""
    OUTPUT=$(sh -c "$XRANDR_COMMAND" 2>&1)
    ( [ $? -eq 0 ] && echo "Success"; ) || {
        echo -e "Error\n\n$OUTPUT\n";
        echo -e "There was an error while trying to add the mode $MODE for $RES_OUTPUT, maybe output $RES_OUTPUT doesn't exist ?";
        _list_outputs
        exit 1;
    }
}

exit 0;
