[![logo](https://raw.githubusercontent.com/dperson/owncloud/master/logo.png)](http://owncloud.org/)

# ownCloud

ownCloud docker container

# What is ownCloud?

ownCloud is a software system for what is commonly termed "file hosting". As
such, ownCloud is very similar to the widely used Dropbox, with the primary
difference being that ownCloud is free and open-source, and thereby allowing
anyone to install and operate it without charge on a private server, with no
limits on storage space (except for hard disk capacity) or the number of
connected clients.

# How to use this image

This ownCloud container was built with Nginx. It defaults to SQLite for the DB,
but you can choose PostgreSQL or MySQL, for more performance.

## Hosting a ownCloud instance on port 8000

    sudo docker run -it --name owncloud -p 8000:80 -d dperson/owncloud

OR with a DB:

    sudo docker run -it --name postgres -d postgres
    sudo docker run -it --name owncloud --link postgresql:db -p 8000:80 -d \
                dperson/owncloud

AND/OR set the host name (important for the WebDAV feature):

    sudo docker run -it -h host.domain.com --name owncloud -p 8000:80 -d \
                dperson/owncloud

AND/OR set local storage:

    sudo docker run -it --name owncloud -p 8000:80 \
                -v /path/to/owncloud/directory:/var/www/owncloud/data -d \
                dperson/owncloud

## Configuration

    sudo docker run -it --rm dperson/owncloud -h

    Usage: owncloud.sh [-opt] [command]
    Options (fields in '[]' are optional, '<>' are required):
        -h          This help
        -t ""       Configure timezone
                    possible arg: "[timezone]" - zoneinfo timezone for container

    The 'command' (if provided and valid) will be run instead of owncloud

ENVIRONMENT VARIABLES (only available with `docker run`)

 * `TZ` - As above, configure the zoneinfo timezone, IE `EST5EDT`
 * `USERID` - Set the UID for the app user
 * `GROUPID` - Set the GID for the app user

## Examples

Any of the commands can be run at creation with `docker run` or later with
`docker exec -it owncloud.sh` (as of version 1.3 of docker).

### Setting the Timezone

    sudo docker run -it --name owncloud -d dperson/owncloud -t EST5EDT

OR using `environment variables`

    sudo docker run -it --name owncloud -e TZ=EST5EDT -d dperson/owncloud

Will get you the same settings as

    sudo docker run -it --name owncloud -p 8000:80 -d dperson/owncloud
    sudo docker exec -it owncloud owncloud.sh -t EST5EDT ls -AlF /etc/localtime
    sudo docker restart owncloud

# User Feedback

## Issues

If you have any problems with or questions about this image, please contact me
through a [GitHub issue](https://github.com/dperson/owncloud/issues).