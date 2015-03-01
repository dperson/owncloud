FROM debian:jessie
MAINTAINER David Personette <dperson@dperson.com>

# Install php and ownCloud
RUN export DEBIAN_FRONTEND='noninteractive' && \
    export version='8.0.0' && \
    export sha256sum='0c62cb06fe4c3eb107bccc4302f2bb3b9f7e5373cf7c9dd307fe' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends bzip2 curl php5 php5-gd \
                php5-pgsql php5-sqlite php5-mysqlnd php5-curl php5-intl \
                php5-mcrypt php5-ldap php5-gmp php5-apcu php5-imagick \
                php5-cgi php5-json smbclient lighttpd && \
    apt-get clean && \
    curl -LOC- -ks \
        https://download.owncloud.org/community/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    tar -xf owncloud-${version}.tar.bz2 -C /var/www owncloud && \
    mkdir -p /var/www/owncloud/data && \
    sed -i '/server.errorlog/i server.accesslog            = "/dev/stdout"' \
                /etc/lighttpd/lighttpd.conf && \
    sed -i '/server.errorlog/s|".*"|"/dev/stderr"|' \
                /etc/lighttpd/lighttpd.conf && \
    sed -i '/server.document-root/s|/html||' /etc/lighttpd/lighttpd.conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud/data/" {' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo '\turl.access-deny = ("")'  >>/etc/lighttpd/lighttpd.conf && \
    echo '}' >>/etc/lighttpd/lighttpd.conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud($|/)" {' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo '\tdir-listing.activate = "disable"' >>/etc/lighttpd/lighttpd.conf && \
    echo '}' >>/etc/lighttpd/lighttpd.conf && \
    sed -i '/^#cgi\.assign/,$s/^#//; /"\.pl"/i \ \t".cgi"  => "/usr/bin/perl",'\
                /etc/lighttpd/conf-available/10-cgi.conf && \
    sed -i -e '/CHILDREN/s/[0-9][0-9]*/16/' \
                -e '/max-procs/a \ \t\t"idle-timeout" => 20,' \
                /etc/lighttpd/conf-available/15-fastcgi-php.conf && \
    grep -q 'allow-x-send-file' \
                /etc/lighttpd/conf-available/15-fastcgi-php.conf || { \
        sed -i '/idle-timeout/a \ \t\t"allow-x-send-file" => "enable",' \
                    /etc/lighttpd/conf-available/15-fastcgi-php.conf && \
        sed -i '/"bin-environment"/a \ \t\t\t"MOD_X_SENDFILE2_ENABLED" => "1",'\
                    /etc/lighttpd/conf-available/15-fastcgi-php.conf; } && \
    lighttpd-enable-mod fastcgi-php && \
    sed -i '/^output_buffering/s/4096/0/' /etc/php5/cgi/php.ini && \
    sed -i '/^expose_php/s/Off/On/' /etc/php5/cgi/php.ini && \
    sed -i '/^post_max_size/s/8M/16G/' /etc/php5/cgi/php.ini && \
    sed -i '/^upload_max_filesize/s/2M/16G/' /etc/php5/cgi/php.ini && \
    sed -i '/^max_execution_time/s/[0-9][0-9]*/3600/' /etc/php5/cgi/php.ini && \
    sed -i '/^max_input_time/s/[0-9][0-9]*/3600/' /etc/php5/cgi/php.ini && \
    rm -rf /var/lib/apt/lists/* /tmp/* owncloud-${version}.tar.bz2

# Config files
COPY owncloud.sh /usr/bin/

VOLUME ["/var/www/owncloud/apps", "/var/www/owncloud/config", \
            "/var/www/owncloud/data"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]
