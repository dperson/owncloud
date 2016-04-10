FROM debian:jessie
MAINTAINER David Personette <dperson@dperson.com>

# Install php and ownCloud
RUN export DEBIAN_FRONTEND='noninteractive' && \
    export version='9.0.1' && \
    export sha256sum='44c98ffa3b957faf3af884cafa1d88c05762b65452592768a926' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends ca-certificates curl && \
    echo "deb http://packages.dotdeb.org jessie all" \
                >>/etc/apt/sources.list.d/dotdeb.list && \
    curl -Ls https://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends bzip2 lighttpd openssl \
                php7.0-gd php7.0-mysql php7.0-pgsql php7.0-sqlite3 php7.0-curl \
                php7.0-intl php7.0-mcrypt php7.0-ldap php7.0-gmp php7.0-opcache\
                php7.0 php7.0-cgi php7.0-json php7.0-imap smbclient \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    echo "downloading owncloud-${version}.tar.bz2 ..." && \
    curl -LOC- -s \
        https://download.owncloud.org/community/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    tar -xf owncloud-${version}.tar.bz2 -C /var/www owncloud && \
    mkdir -p /var/www/owncloud/data && \
    sed -i '/server.errorlog/s|^|#|' /etc/lighttpd/lighttpd.conf && \
    sed -i '/server.document-root/s|/html||' /etc/lighttpd/lighttpd.conf && \
    sed -i '/mod_rewrite/a \ \t"mod_setenv",' /etc/lighttpd/lighttpd.conf && \
    echo '\nsetenv.add-response-header += ( "X-XSS-Protection" => "1; mode=block" )' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo 'setenv.add-response-header += ( "X-Content-Type-Options" => "nosniff" )' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo 'setenv.add-response-header += ( "X-Robots-Tag" => "none" )' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo 'setenv.add-response-header += ( "X-Frame-Options" => "SAMEORIGIN" )' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud/(?:\.htaccess|data|config|db_structure\.xml|README)" {' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo '\turl.access-deny = ("")'  >>/etc/lighttpd/lighttpd.conf && \
    echo '}' >>/etc/lighttpd/lighttpd.conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud($|/)" {' \
                >>/etc/lighttpd/lighttpd.conf && \
    echo '\tdir-listing.activate = "disable"' >>/etc/lighttpd/lighttpd.conf && \
    echo '}' >>/etc/lighttpd/lighttpd.conf && \
    /bin/echo -e 'url.redirect  = ("^/$" => "/owncloud")' \
                >>/etc/lighttpd/lighttpd.conf && \
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
    for i in /etc/php/7.0/*/php.ini; do \
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
    { chown -Rh root:www-data /var/www/owncloud || :; } && \
    chown -Rh www-data. /run/lighttpd /var/www/owncloud/apps \
                /var/www/owncloud/config /var/www/owncloud/data \
                /var/www/owncloud/themes && \
    { chown -Rh root:www-data /var/www/owncloud/data/.htaccess || :; } && \
    apt-get purge -qqy ca-certificates curl && \
    apt-get autoremove -qqy && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* owncloud-${version}.tar.bz2
COPY owncloud.sh /usr/bin/

VOLUME ["/var/www/owncloud/apps", "/var/www/owncloud/config", \
            "/var/www/owncloud/data", "/var/www/owncloud/themes"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]