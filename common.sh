#!/bin/bash

CONFIG_DIR=$HOME/.config/ddc-scripts
CONFIG_PATH=$CONFIG_DIR/config.json
DISPLAYS=$CONFIG_DIR/displays
JOBS=$CONFIG_DIR/pids
ABOUT='configuration file for https:/github.com/ybnd/ddc-scripts'

debug() {
    if [[ -n $DDC_SCRIPTS_DEBUG ]]; then
        echo "ddc-scripts -- $1"
    fi
}


config_edit() {
    debug "Writing to config: $@"
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

dealias() {
    VALUE_IN="$1"
    if [[ -z "$VALUE_IN" ]]; then
	    echo ""
    else
        DEALIASED=$(config_read ".aliases.\"$VALUE_IN\" | values")
        if [[ -n $DEALIASED ]]; then
            echo "$DEALIASED"
        else
            echo "$VALUE_IN"
        fi
    fi
}

display_code() {
    config_read ".displays[] | select(.name == \"$1\") | .code" || echo $1
}

init() {
    debug "Initializing"
    mkdir -p $CONFIG_DIR

    # Clear previous configuration
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
    rm $DISPLAYS

    # We use i2c buses instead of ddcutil's display IDs since those don't work properly when called in parallel
    ddcutil detect | sed -rn 's/.*\/dev\/i2c-([[:digit:]])/\1/p' | while read DISPLAY; do
        config_edit ".displays.\"$DISPLAY\" |= {}"
        config_edit ".displays.\"$DISPLAY\".code |= \"$DISPLAY\""
        config_edit ".displays.\"$DISPLAY\".name |= \"Display $DISPLAY\""
        echo $DISPLAY >> $DISPLAYS
    done
}

ddc_adjust() {
    debug "ddc_adjust $@"
    CONTROL="$1"
    TO=$2

    while read DISPLAY ; do
        _ddc_adjust $DISPLAY $CONTROL $TO &
    done < $DISPLAYS

    jobs -p > $JOBS
    while read JOB ; do 
        wait $JOB || echo "Failed!"
    done < $JOBS

    rm $JOBS
}

_ddc_adjust() {
    debug "_ddc_adjust $@"

    DISPLAY="$1"
    CONTROL="$2"
    TO="$3"

    VCP=$(config_read ".vcp.\"$CONTROL\"")
    NAME=$(config_read ".displays.\"$DISPLAY\".name")
    # todo: messy sed
    FROM=$(ddcutil -b "$DISPLAY" getvcp "$VCP" | sed -r 's/[^=]+= *([^=]+)[\),].*/\1/')

    if [[ -z "$TO" ]]; then
        echo "$NAME: $CONTROL $FROM"
    elif [[ $FROM -ne $TO ]]; then
        echo "$NAME: $CONTROL $FROM -> $TO"
        ddcutil -b "$DISPLAY" setvcp "$VCP" "$TO"
    else
        echo "$NAME: $CONTROL $TO"
    fi
}


if [[ ! -d "$CONFIG_DIR" || ! -f "$CONFIG_PATH" || -z $(cat "$CONFIG_PATH") ]]; then
    init
fi

if [[ ! -f "$DISPLAYS" || -z $(cat "$DISPLAYS") ]]; then 
    detect_displays
fi
