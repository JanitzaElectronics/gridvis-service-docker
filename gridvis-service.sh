#!/bin/bash
set -eu

readonly GRIDVIS_DATA_DIR=/opt/GridVisData
readonly ADMIN_PASSWORD_MARKER="$GRIDVIS_DATA_DIR/.admin-password-initialized"
readonly ADMIN_PASSWORD_CONFIG="$GRIDVIS_DATA_DIR/config/server.conf"
readonly PASSWORD_WRITER=/usr/local/lib/gridvis/write-admin-password.groovy
readonly GROOVY_JAR='/usr/local/GridVis/GridVis Service/wrapper/modules/ext/de.janitza.pasw.wrapper-groovy/org-apache-groovy/groovy.jar'
readonly TOOLS_JAR='/usr/local/GridVis/GridVis Service/baseui/modules/de-janitza-pasw-baseui-tools.jar'

error() {
    printf 'ERROR: %s\n' "$*" >&2
}

get_admin_password() {
    ADMIN_PASSWORD=''
    ADMIN_PASSWORD_SOURCE=''

    if [ "${GRIDVIS_ADMIN_PASSWORD_FILE+x}" = x ]; then
        if [ -z "$GRIDVIS_ADMIN_PASSWORD_FILE" ]; then
            error 'GRIDVIS_ADMIN_PASSWORD_FILE is set but empty'
            return 1
        fi
        if [ ! -f "$GRIDVIS_ADMIN_PASSWORD_FILE" ]; then
            error "GRIDVIS_ADMIN_PASSWORD_FILE does not exist or is not a regular file: $GRIDVIS_ADMIN_PASSWORD_FILE"
            return 1
        fi
        if [ ! -r "$GRIDVIS_ADMIN_PASSWORD_FILE" ]; then
            error "GRIDVIS_ADMIN_PASSWORD_FILE is not readable: $GRIDVIS_ADMIN_PASSWORD_FILE"
            return 1
        fi
        if ! IFS= read -r ADMIN_PASSWORD < "$GRIDVIS_ADMIN_PASSWORD_FILE" && [ -z "$ADMIN_PASSWORD" ]; then
            error "GRIDVIS_ADMIN_PASSWORD_FILE is empty: $GRIDVIS_ADMIN_PASSWORD_FILE"
            return 1
        fi
        ADMIN_PASSWORD=${ADMIN_PASSWORD%$'\r'}
        if [ -z "$ADMIN_PASSWORD" ]; then
            error "GRIDVIS_ADMIN_PASSWORD_FILE is empty: $GRIDVIS_ADMIN_PASSWORD_FILE"
            return 1
        fi
        ADMIN_PASSWORD_SOURCE='file'
    elif [ "${GRIDVIS_ADMIN_PASSWORD+x}" = x ]; then
        if [ -z "$GRIDVIS_ADMIN_PASSWORD" ]; then
            error 'GRIDVIS_ADMIN_PASSWORD is set but empty'
            return 1
        fi
        ADMIN_PASSWORD=$GRIDVIS_ADMIN_PASSWORD
        ADMIN_PASSWORD_SOURCE='environment'
    else
        random_part=$(head -c 12 /dev/urandom | base64)
        ADMIN_PASSWORD="Aa1!$random_part"
        if [ "${#ADMIN_PASSWORD}" -ne 20 ]; then
            error 'Could not generate a secure GridVis admin password'
            return 1
        fi
        ADMIN_PASSWORD_SOURCE='generated'
    fi

    case $ADMIN_PASSWORD in
        *$'\n'*|*$'\r'*)
            ADMIN_PASSWORD=''
            error 'GridVis admin passwords must not contain line breaks'
            return 1
            ;;
    esac
}

admin_password_initialization_required() {
    marker=${1:-$ADMIN_PASSWORD_MARKER}
    [ "${GRIDVIS_INITIALIZE_ADMIN_PASSWORD:-true}" != false ] && [ ! -f "$marker" ]
}

write_admin_password() {
    if [ ! -f "$PASSWORD_WRITER" ]; then
        error "Password writer is not available: $PASSWORD_WRITER"
        return 1
    fi
    if [ ! -r "$GROOVY_JAR" ] || [ ! -r "$TOOLS_JAR" ]; then
        error 'GridVis Groovy runtime or password-encryption library is not available'
        return 1
    fi

    # The password is passed via standard input, never as a command-line argument.
    if ! printf '%s\n' "$ADMIN_PASSWORD" | java -cp "$GROOVY_JAR:$TOOLS_JAR" \
            groovy.ui.GroovyMain "$PASSWORD_WRITER" "$ADMIN_PASSWORD_CONFIG"; then
        error 'Could not initialize the encrypted GridVis admin password'
        return 1
    fi
    if ! chown -R gridvis:gridvis "$GRIDVIS_DATA_DIR/config"; then
        error "Cannot set the owner of $GRIDVIS_DATA_DIR/config"
        return 1
    fi
}

create_admin_password_marker() {
    marker_tmp=$(mktemp "$ADMIN_PASSWORD_MARKER.tmp.XXXXXX") || {
        error "Cannot create the admin-password marker in $GRIDVIS_DATA_DIR"
        return 1
    }
    if ! chown gridvis:gridvis "$marker_tmp" || ! mv -f "$marker_tmp" "$ADMIN_PASSWORD_MARKER"; then
        rm -f "$marker_tmp" || true
        error "Admin password was initialized, but marker file could not be written: $ADMIN_PASSWORD_MARKER"
        return 1
    fi
}

initialize_admin_password() {
    get_admin_password
    generated_password=''
    if [ "$ADMIN_PASSWORD_SOURCE" = generated ]; then
        generated_password=$ADMIN_PASSWORD
    fi

    if ! write_admin_password; then
        ADMIN_PASSWORD=''
        generated_password=''
        return 1
    fi
    ADMIN_PASSWORD=''
    if ! create_admin_password_marker; then
        generated_password=''
        return 1
    fi

    if [ "$ADMIN_PASSWORD_SOURCE" = generated ]; then
        printf 'Generated GridVis admin password: %s\n' "$generated_password"
        printf 'Please change this generated password after your first login.\n'
    else
        printf 'GridVis admin password initialized from %s.\n' "$ADMIN_PASSWORD_SOURCE"
    fi
    generated_password=''
}

build_service_parameters() {
    FEATURE_PARAMS=''
    if [ "${FEATURE_TOGGLES:-NONE}" != NONE ]; then
        IFS=';' read -ra ADDR <<< "$FEATURE_TOGGLES"
        for i in "${ADDR[@]}"; do
            FEATURE_PARAMS="$FEATURE_PARAMS -J-D${i}=true"
        done
    fi
    if [ "${SERVICE_PARAMS:-NONE}" != NONE ]; then
        FEATURE_PARAMS="$FEATURE_PARAMS $SERVICE_PARAMS"
    fi
    GROOVY_PARAM=''
    if [ -n "${STARTUP_GROOVY:-}" ] && [ "$STARTUP_GROOVY" != NONE ]; then
        GROOVY_PARAM="--groovy $STARTUP_GROOVY"
    fi
}

start_xvfb() {
    LOG_DIR=$GRIDVIS_DATA_DIR/var/log
    mkdir -p "$LOG_DIR"
    Xvfb :1 -screen 0 800x600x24+32 -nolisten tcp -nolisten unix \
        &> "$LOG_DIR/xvfb.log" &
    export DISPLAY=:1
}

run_server() {
    build_service_parameters
    sed -i -E -e "s/Xmx[0-9]+m/Xmx${MAX_RAM_SIZE_MB:-1024}m/g" \
        '/usr/local/GridVis/GridVis Service/etc/server.conf'
    start_xvfb
    export TZ=${USER_TIMEZONE:-UTC}

    # These variables intentionally retain the existing word-splitting behavior.
    # shellcheck disable=SC2086
    exec /usr/local/GridVis/GridVis\ Service/bin/server \
        -J-Duser.timezone="${USER_TIMEZONE:-UTC}" \
        --locale "${USER_LANG:-en}" \
        -J-Dfile.encoding="${FILE_ENCODING:-UTF-8}" \
        -J-Dnetbeans.logger.console=true \
        $FEATURE_PARAMS $GROOVY_PARAM
}

main() {
    if [ "$(id -u)" -eq 0 ]; then
        if admin_password_initialization_required "$ADMIN_PASSWORD_MARKER"; then
            initialize_admin_password
        fi
        unset GRIDVIS_ADMIN_PASSWORD GRIDVIS_ADMIN_PASSWORD_FILE
        exec env HOME=/home/gridvis setpriv --reuid=gridvis --regid=gridvis \
            --init-groups "$0"
    fi

    run_server
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
