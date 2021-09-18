#!/bin/bash

CONFIG_PATH=~/.config/ddc-scripts
ABOUT='configuration file for https:/github.com/ybnd/ddc-scripts'


config_edit() {     
    CONFIG=$(jq "$@" "$CONFIG_PATH")
    echo "$CONFIG" > $CONFIG_PATH
}

config_read() {
    cat $CONFIG_PATH | jq -r "$@"
}

config_read_optional() {
    VALUE=$(cat $CONFIG_PATH | jq -r "$@")
    if [[ -z $VALUE ]]; then
        echo "$VALUE"
    else
        echo "?"
    fi
}

displays() {
    config_read '.displays | keys[]'
}

aliases() {
    config_read '.aliases | keys[]'
}

dealias() {
    VALUE_IN="$1"
    if [[ -z "$VALUE_IN" ]]; then
	echo ""
    elif [[ $(aliases) == *"$VALUE_IN"* ]]; then
        echo $(config_read ".aliases.\"$VALUE_IN\"")
    else
        echo "$VALUE_IN"
    fi
}

init() {
    echo "{}" > "$CONFIG_PATH"
    
    config_edit ".about = \"$ABOUT\""
    config_edit ".vcp.brightness = 10"     # todo: should include info & prompt the user to adjust configuration in case it doesn't match up with expectations
    config_edit ".vcp.input_source = 60"
    config_edit ".aliases = {}"
    config_edit ".displays = {}"
}

detect_displays() {
    # Clear previous displays so we don't get duplicates
    if [[ 0 -ne "$(config_read '.displays | length')" ]]; then 
        config_edit ".displays = {}"
    fi

    # We use i2c buses instead of ddcutil's display IDs since those don't work properly when called in parallel
    ddcutil detect | sed -rn 's/.*\/dev\/i2c-([[:digit:]])/\1/p' | while read DISPLAY; do
        config_edit ".displays.\"$DISPLAY\" |= {}"
        config_edit ".displays.\"$DISPLAY\".name |= \"Display $DISPLAY\""
    done
}

ddc_adjust() {
    CONTROL="$1"
    VCP=$(config_read ".vcp.\"$CONTROL\"")
    TO="$2"

    displays | while read DISPLAY ; do
        NAME=$(config_read ".displays.\"$DISPLAY\".name")
        FROM=$(config_read ".displays.\"$DISPLAY\".\"$CONTROL\"")
        
	if [[ -z "$TO" ]]; then
	    echo "$NAME: $CONTROL $FROM"
	elif [[ $FROM -ne $TO ]]; then
            echo "$NAME: $CONTROL $FROM -> $TO"
            # don't wait for ddcutil to finish so the adjustment happens more or less in parallel
            ddcutil -b "$DISPLAY" setvcp "$VCP" "$TO" &
            
            config_edit ".displays.\"$DISPLAY\".\"$CONTROL\" |= \"$TO\""
        else
            echo "$NAME: $CONTROL $TO"
        fi
    done
}


if [[ ! -f "$CONFIG_PATH" || -z $(cat "$CONFIG_PATH") ]]; then
    init
fi

if [[ 0 -eq "$(config_read '.displays | length')" ]]; then 
    detect_displays
fi
