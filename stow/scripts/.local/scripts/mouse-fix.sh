#!/bin/bash
for id in $(xinput list --id-only 'pointer'); do
    xinput set-prop "$id" "libinput Natural Scrolling Enabled" 0 2>/dev/null
done
