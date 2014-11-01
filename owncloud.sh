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

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() {
    local RC=${1:-0}

    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help

The 'command' (if provided and valid) will be run instead of nginx
" >&2
    exit $RC
}

while getopts ":h" opt; do
    case "$opt" in
        h) usage ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

chown -Rh www-data. /var/www/owncloud

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
else
    service php5-fpm start
    exec nginx -g "daemon off;"
fi
