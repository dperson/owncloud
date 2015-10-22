FROM debian:jessie
MAINTAINER David Personette <dperson@dperson.com>

# Install php and ownCloud
RUN export DEBIAN_FRONTEND='noninteractive' && \
    export version='8.2.0' && \
    export sha256sum='fcfe99cf1c3aa06ff369e5b1a602147c08dd977af11800fe06c6' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends bzip2 curl php5 php5-gd \
                php5-pgsql php5-sqlite php5-mysqlnd php5-curl php5-intl \
                php5-mcrypt php5-ldap php5-gmp php5-apcu php5-imagick \
                php5-cgi php5-json smbclient lighttpd openssl \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    curl -LOC- -ks \
        https://download.owncloud.org/community/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    tar -xf owncloud-${version}.tar.bz2 -C /var/www owncloud && \
    mkdir -p /var/www/owncloud/data && \
    sed -i '/server.errorlog/s|^|#|' /etc/lighttpd/lighttpd.conf && \
    sed -i '/server.document-root/s|/html||' /etc/lighttpd/lighttpd.conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud/data/" {' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo '\turl.access-deny = ("")'  >>/etc/lighttpd/lighttpd.conf && \
    echo '}' >>/etc/lighttpd/lighttpd.conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud($|/)" {' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo '\tdir-listing.activate = "disable"' >>/etc/lighttpd/lighttpd.conf && \
    echo '}' >>/etc/lighttpd/lighttpd.conf && \
    /bin/echo -e 'url.redirect  = ("^/$" => "/owncloud")' >> \
                /etc/lighttpd/lighttpd.conf && \
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
    for i in /etc/php5/*/php.ini; do \
        sed -i '/always_populate_raw_post_data/s/^;//' $i; \
        sed -i '/^output_buffering/s/4096/0/' $i; \
        sed -i '/^expose_php/s/Off/On/' $i; \
        sed -i '/^post_max_size/s/8M/16G/' $i; \
        sed -i '/^upload_max_filesize/s/2M/16G/' $i; \
        sed -i '/^max_execution_time/s/[0-9][0-9]*/3600/' $i; \
        sed -i '/^max_input_time/s/[0-9][0-9]*/3600/' $i; \
    done && \
    mkdir -p /run/lighttpd && \
    find /var/www/owncloud -type f -print0 | xargs -0 chmod 0640 && \
    find /var/www/owncloud -type d -print0 | xargs -0 chmod 0750 && \
    { chmod 0644 /var/www/owncloud/.htaccess \
                /var/www/owncloud/data/.htaccess || :; } && \
    { chown -Rh root:www-data /var/www/owncloud \
                /var/www/owncloud/data/.htaccess || :; } && \
    chown -Rh www-data. /run/lighttpd /var/www/owncloud/apps \
                /var/www/owncloud/config /var/www/owncloud/data && \
    apt-get purge -qqy curl && \
    apt-get autoremove -qqy && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* owncloud-${version}.tar.bz2
COPY owncloud.sh /usr/bin/

VOLUME ["/run", "/tmp", "/var/cache", "/var/lib", "/var/log", "/var/tmp", \
            "/var/www/owncloud/apps", "/var/www/owncloud/config", \
            "/var/www/owncloud/data"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]
