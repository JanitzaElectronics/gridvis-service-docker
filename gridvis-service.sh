#!/bin/bash

FEATURE_PARAMS=''
if [ "$FEATURE_TOGGLES" != "NONE" ]
then
    IFS=';' read -ra ADDR <<< "$FEATURE_TOGGLES"
    for i in "${ADDR[@]}"; do
        FEATURE_PARAMS="$FEATURE_PARAMS -J-D${i}=true"
    done
fi
if [ "$SERVICE_PARAMS" != "NONE" ]
then
    FEATURE_PARAMS="$FEATURE_PARAMS $SERVICE_PARAMS"
fi
GROOVY_PARAM=''
if [ -n "$STARTUP_GROOVY" ] && [ "$STARTUP_GROOVY" != "NONE" ]
then                                                                           
    GROOVY_PARAM="--groovy $STARTUP_GROOVY"                         
fi
sed -i -E -e "s/Xmx[0-9]+m/Xmx${MAX_RAM_SIZE_MB}m/g" /usr/local/GridVis/GridVis\ Service/etc/server.conf
LOG_DIR=/opt/GridVisData/var/log
mkdir -p "$LOG_DIR"
Xvfb :1 -screen 0 800x600x24+32 -nolisten tcp -nolisten unix &> "$LOG_DIR/xvfb.log" &
export DISPLAY=:1
export TZ=${USER_TIMEZONE:-UTC}
exec /usr/local/GridVis/GridVis\ Service/bin/server -J-Duser.timezone="${USER_TIMEZONE:-UTC}" --locale "${USER_LANG:-en}" -J-Dfile.encoding="${FILE_ENCODING:-UTF-8}" $FEATURE_PARAMS $GROOVY_PARAM
