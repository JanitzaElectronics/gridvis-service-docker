#!/bin/bash

FEATURE_PARAMS=''
if [ "$FEATURE_TOGGLES" != "NONE" ]
then
    IFS=';' read -ra ADDR <<< "$FEATURE_TOGGLES"
    for i in "${ADDR[@]}"; do
        FEATURE_PARAMS="$FEATURE_PARAMS -J-D${i}=true"
    done
fi
if [ "$HUB_PARAMS" != "NONE" ]
then
    FEATURE_PARAMS="$FEATURE_PARAMS $HUB_PARAMS"
fi
GROOVY_PARAM=''
if [ -n "$STARTUP_GROOVY" ] && [ "$STARTUP_GROOVY" != "NONE" ]
then                                                                           
    GROOVY_PARAM="--groovy $STARTUP_GROOVY"                         
fi
sed -i -E -e "s/Xmx[0-9]+m/Xmx${MAX_RAM_SIZE_MB}m/g" /usr/local/GridVisHub/etc/hub.conf
exec /usr/local/GridVisHub/bin/hub -J-Duser.timezone="${USER_TIMEZONE:-UTC}" --locale "${USER_LANG:-en}" -J-Dfile.encoding="${FILE_ENCODING:-UTF-8}" $FEATURE_PARAMS $GROOVY_PARAM
