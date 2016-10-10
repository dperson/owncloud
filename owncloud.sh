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

### proxy: Set the trusted_proxies for owncloud
# Arguments:
#   proxy) for example web
# Return: properly configured trusted_proxies
proxy() { local proxy="${1:-""}" file=/var/www/owncloud/config/config.php
    [[ -e $file ]] || sleep 20
    grep -q trusted_proxies $file ||
        sed -i "/^);/i\  'trusted_proxies' => ['$proxy']," $file
    grep -q forwarded_for_headers $file ||
        sed -i "/^);/i\  'forwarded_for_headers' => ['X-Forwarded-For']," $file
    grep -q overwritehost $file ||
        sed -i "/^);/i\  'overwritehost' => '$(hostname -f)'," $file
    grep -q overwriteprotocol $file ||
        sed -i "/^);/i\  'overwriteprotocol' => 'https'," $file
}

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
    -p \"<proxy>\" Configure trusted_proxies
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container

The 'command' (if provided and valid) will be run instead of ownCloud
" >&2
    exit $RC
}

while getopts ":hp:t:" opt; do
    case "$opt" in
        h) usage ;;
        p) proxy "$OPTARG" ;;
        t) timezone "$OPTARG" ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ "${PROXY:-""}" ]] && proxy "$PROXY"
[[ "${TZ:-""}" ]] && timezone "$TZ"
[[ "${USERID:-""}" =~ ^[0-9]+$ ]] && usermod -u $USERID -o www-data
[[ "${GROUPID:-""}" =~ ^[0-9]+$ ]] && groupmod -g $GROUPID -o www-data

[[ -f /var/www/owncloud/config/config.php ]] && {
    grep -q APCu /var/www/owncloud/config/config.php ||
        sed -i '/^);/i\  '"'memcache.local' => '\\\\OC\\\\Memcache\\\\APCu'," \
                    /var/www/owncloud/config/config.php
}
tar -xf /owncloud-*.tar.bz2 -C /var/www owncloud
mkdir -p /run/lighttpd /var/www/owncloud/data
[[ -p /tmp/log ]] || mkfifo -m 0660 /tmp/log
find /var/www/owncloud -print0 | xargs -0 chmod a-s,u=rwX,g=rX,o-rwx
chown -Rh root:www-data /var/www/owncloud /tmp/log
chown -Rh www-data. /run/lighttpd /var/cache/lighttpd /var/www/owncloud/*/
find /var/www/owncloud -name .htaccess -exec chown -Rh root:www-data {} \;

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
elif ps -ef | egrep -v grep | grep -q lighttpd; then
    echo "Service already running, please restart container to apply changes"
else
    tail -F /tmp/log &
    exec lighttpd -D -f /etc/lighttpd/lighttpd.conf
fi