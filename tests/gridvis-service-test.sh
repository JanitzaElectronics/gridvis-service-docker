#!/bin/bash
set -eu

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck disable=SC1091
source "$REPOSITORY_ROOT/gridvis-service.sh"

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/gridvis-service-test.XXXXXX")
trap 'chmod -R u+w "$TEST_ROOT" 2>/dev/null || true; rm -rf "$TEST_ROOT"' EXIT
PASSED=0
SKIPPED=0

pass() {
    PASSED=$((PASSED + 1))
    printf 'ok %d - %s\n' "$PASSED" "$1"
}

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    case $1 in
        *"$2"*) ;;
        *) fail "expected output to contain: $2" ;;
    esac
}

assert_not_contains() {
    case $1 in
        *"$2"*) fail "output disclosed: $2" ;;
        *) ;;
    esac
}

reset_password_environment() {
    unset GRIDVIS_ADMIN_PASSWORD GRIDVIS_ADMIN_PASSWORD_FILE \
        GRIDVIS_INITIALIZE_ADMIN_PASSWORD
    ADMIN_PASSWORD=''
    ADMIN_PASSWORD_SOURCE=''
}

capture_get_admin_password() {
    PASSWORD_OUTPUT_FILE="$TEST_ROOT/get-admin-password.output"
    get_admin_password > "$PASSWORD_OUTPUT_FILE" 2>&1
}

reset_password_environment
GRIDVIS_ADMIN_PASSWORD='ValidEnvironment1!'
export GRIDVIS_ADMIN_PASSWORD
capture_get_admin_password
output=$(< "$PASSWORD_OUTPUT_FILE")
[ "$ADMIN_PASSWORD" = 'ValidEnvironment1!' ] || fail 'environment password mismatch'
[ "$ADMIN_PASSWORD_SOURCE" = environment ] || fail 'environment source mismatch'
assert_not_contains "$output" 'ValidEnvironment1!'
pass 'new volume password from environment is not logged'

reset_password_environment
GRIDVIS_ADMIN_PASSWORD=$'ValidEnvironment1!\nsecond-line'
export GRIDVIS_ADMIN_PASSWORD
if capture_get_admin_password; then
    fail 'multi-line environment password returned success'
fi
output=$(< "$PASSWORD_OUTPUT_FILE")
assert_contains "$output" 'must not contain line breaks'
assert_not_contains "$output" 'ValidEnvironment1!'
pass 'multi-line password fails without disclosure'

reset_password_environment
printf '%s\n' 'ValidFileSecret1!' > "$TEST_ROOT/password"
GRIDVIS_ADMIN_PASSWORD='LowerPriority1!'
GRIDVIS_ADMIN_PASSWORD_FILE="$TEST_ROOT/password"
export GRIDVIS_ADMIN_PASSWORD GRIDVIS_ADMIN_PASSWORD_FILE
capture_get_admin_password
output=$(< "$PASSWORD_OUTPUT_FILE")
[ "$ADMIN_PASSWORD" = 'ValidFileSecret1!' ] || fail 'file password mismatch'
[ "$ADMIN_PASSWORD_SOURCE" = file ] || fail 'file source mismatch'
assert_not_contains "$output" 'ValidFileSecret1!'
assert_not_contains "$output" 'LowerPriority1!'
pass 'password file has precedence and is not logged'

reset_password_environment
capture_get_admin_password
output=$(< "$PASSWORD_OUTPUT_FILE")
[ "$ADMIN_PASSWORD_SOURCE" = generated ] || fail 'generated source mismatch'
[ "${#ADMIN_PASSWORD}" -eq 20 ] || fail 'generated password length mismatch'
case $ADMIN_PASSWORD in
    Aa1!*) ;;
    *) fail 'generated password lacks mandatory character classes' ;;
esac
[ -z "$output" ] || fail 'password generation produced unexpected output'
pass 'generated password is secure and satisfies GridVis length policy'

output=$(
    get_admin_password() {
        ADMIN_PASSWORD='GeneratedPassword1!'
        ADMIN_PASSWORD_SOURCE='generated'
    }
    write_admin_password() {
        return 0
    }
    create_admin_password_marker() {
        return 0
    }
    initialize_admin_password
)
assert_contains "$output" 'Generated GridVis admin password: GeneratedPassword1!'
assert_contains "$output" 'Please change this generated password after your first login.'
pass 'generated password output recommends changing it after first login'

reset_password_environment
marker="$TEST_ROOT/marker"
: > "$marker"
if admin_password_initialization_required "$marker"; then
    fail 'existing marker did not skip bootstrap'
fi
pass 'restart with marker skips bootstrap'

reset_password_environment
existing_userdir="$TEST_ROOT/existing-userdir"
mkdir -p "$existing_userdir/var"
: > "$existing_userdir/var/preferences.xml"
if admin_password_initialization_required "$TEST_ROOT/existing-volume-marker" "$existing_userdir"; then
    fail 'existing userdir configuration without marker required bootstrap'
fi
pass 'non-empty existing userdir without marker skips bootstrap'

if ! admin_password_preserved_for_existing_userdir "$TEST_ROOT/existing-volume-marker" "$existing_userdir"; then
    fail 'existing userdir was not identified as password-preserving'
fi
output=$(log_admin_password_preserved)
assert_contains "$output" 'configured admin password was not changed'
pass 'existing userdir reports password preservation'

reset_password_environment
new_userdir="$TEST_ROOT/new-userdir"
mkdir -p "$new_userdir"
if ! admin_password_initialization_required "$TEST_ROOT/new-userdir-marker" "$new_userdir"; then
    fail 'new userdir without configuration skipped bootstrap'
fi
pass 'new userdir without configuration requires bootstrap'

reset_password_environment
GRIDVIS_INITIALIZE_ADMIN_PASSWORD=false
export GRIDVIS_INITIALIZE_ADMIN_PASSWORD
if admin_password_initialization_required "$TEST_ROOT/disabled-marker"; then
    fail 'disabled initialization requested bootstrap'
fi
pass 'disabled initialization skips bootstrap'

reset_password_environment
: > "$TEST_ROOT/empty-password"
GRIDVIS_ADMIN_PASSWORD_FILE="$TEST_ROOT/empty-password"
export GRIDVIS_ADMIN_PASSWORD_FILE
if capture_get_admin_password; then
    fail 'empty password file returned success'
fi
output=$(< "$PASSWORD_OUTPUT_FILE")
assert_contains "$output" 'is empty'
pass 'empty password file fails'

reset_password_environment
GRIDVIS_ADMIN_PASSWORD_FILE="$TEST_ROOT/missing-password"
export GRIDVIS_ADMIN_PASSWORD_FILE
if capture_get_admin_password; then
    fail 'missing password file returned success'
fi
output=$(< "$PASSWORD_OUTPUT_FILE")
assert_contains "$output" 'does not exist or is not a regular file'
pass 'missing password file fails'

reset_password_environment
GRIDVIS_ADMIN_PASSWORD=''
export GRIDVIS_ADMIN_PASSWORD
if capture_get_admin_password; then
    fail 'empty environment password returned success'
fi
output=$(< "$PASSWORD_OUTPUT_FILE")
assert_contains "$output" 'GRIDVIS_ADMIN_PASSWORD is set but empty'
pass 'empty environment password fails'

reset_password_environment
printf '%s\n' 'UnreadableSecret1!' > "$TEST_ROOT/unreadable-password"
chmod 000 "$TEST_ROOT/unreadable-password"
GRIDVIS_ADMIN_PASSWORD_FILE="$TEST_ROOT/unreadable-password"
export GRIDVIS_ADMIN_PASSWORD_FILE
if [ "$(id -u)" -eq 0 ]; then
    SKIPPED=$((SKIPPED + 1))
    printf 'ok - unreadable password file # SKIP root can read mode 000 files\n'
else
    if capture_get_admin_password; then
        fail 'unreadable password file returned success'
    fi
    output=$(< "$PASSWORD_OUTPUT_FILE")
    assert_contains "$output" 'is not readable'
    assert_not_contains "$output" 'UnreadableSecret1!'
    pass 'unreadable password file fails without disclosure'
fi

printf 'passed=%d skipped=%d\n' "$PASSED" "$SKIPPED"
