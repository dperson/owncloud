#!/usr/bin/env bash
#===============================================================================
#          FILE: owncloud.sh
#
#         USAGE: ./owncloud.sh
#
#   DESCRIPTION: Entrypoint for owncloud docker container
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 09/28/2014 12:11
#      REVISION: 1.0
#===============================================================================

set -o nounset                              # Treat unset variables as an error

### timezone: Set the timezone for the container
# Arguments:
#   timezone) for example EST5EDT
# Return: the correct zoneinfo file will be symlinked into place
timezone() { local timezone="${1:-EST5EDT}"
    [[ -e /usr/share/zoneinfo/$timezone ]] || {
        echo "ERROR: invalid timezone specified: $timezone" >&2
        return
    }

    if [[ -w /etc/timezone && $(cat /etc/timezone) != $timezone ]]; then
        echo "$timezone" >/etc/timezone
        ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1
    fi
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() { local RC=${1:-0}
    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container

The 'command' (if provided and valid) will be run instead of ownCloud
" >&2
    exit $RC
}

while getopts ":ht:" opt; do
    case "$opt" in
        h) usage ;;
        t) timezone "$OPTARG" ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ "${TZ:-""}" ]] && timezone "$TZ"
[[ "${USERID:-""}" =~ ^[0-9]+$ ]] && usermod -u $USERID -o www-data
[[ "${GROUPID:-""}" =~ ^[0-9]+$ ]] && groupmod -g $GROUPID -o www-data

find /var/www/owncloud -type f -print0 | xargs -0 chmod 0640
find /var/www/owncloud -type d -print0 | xargs -0 chmod 0750
chown -Rh root:www-data /var/www/owncloud 2>&1 | grep -iv 'Read-only' || :
chown -Rh www-data. /run/lighttpd /var/cache/lighttpd \
            /var/www/owncloud/{apps,config,data,themes}
chown -h root:www-data /var/www/owncloud/data/.htaccess 2>/dev/null || :

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
elif ps -ef | egrep -v grep | grep -q lighttpd; then
    echo "Service already running, please restart container to apply changes"
else
    exec lighttpd -D -f /etc/lighttpd/lighttpd.conf
fi