[![logo](http://owncloud.org/wp-content/themes/owncloudorgnew/assets/img/common/logo_owncloud.svg)](http://owncloud.org/)

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

## Hosting a ownCloud instance on port 8000

    sudo docker run --name owncloud -p 8000:80 -d dperson/owncloud

## Configuration

    sudo docker run -it --rm dperson/owncloud -h

    Usage: owncloud.sh [-opt] [command]
    Options (fields in '[]' are optional, '<>' are required):
        -h          This help
        -T ""       Configure timezone
                    possible arg: "[timezone]" - zoneinfo timezone for container

    The 'command' (if provided and valid) will be run instead of owncloud

## Examples

Any of the commands can be run at creation with `docker run` or later with
`docker exec owncloud.sh` (as of version 1.3 of docker).

    sudo docker run --name owncloud -p 8000:80 -d dperson/owncloud
    sudo docker exec owncloud owncloud.sh -T EST5EDT ls -AlF /etc/localtime
    sudo docker start owncloud

# User Feedback

## Issues

If you have any problems with or questions about this image, please contact me
through a [GitHub issue](https://github.com/dperson/owncloud/issues).
