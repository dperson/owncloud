FROM debian:jessie
MAINTAINER David Personette <dperson@gmail.com>

# Install php and ownCloud
RUN export DEBIAN_FRONTEND='noninteractive' && \
    export url='https://download.owncloud.org/community' && \
    export version='9.0.2' && \
    export sha256sum='845c43fe981fa0fd07fc3708f41f1ea15ecb11c2a15c65a4de19' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends ca-certificates curl && \
    echo "deb http://packages.dotdeb.org jessie all" \
                >>/etc/apt/sources.list.d/dotdeb.list && \
    curl -Ls https://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends bzip2 lighttpd openssl \
                php7.0-apcu php7.0-cgi php7.0-gd php7.0-intl php7.0-mcrypt \
                php7.0-mysql php7.0-opcache php7.0-pgsql php7.0-sqlite3 \
                php7.0-bz2 php7.0-curl php7.0-gmp php7.0-imagick php7.0-imap \
                php7.0-json php7.0-ldap smbclient \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    echo "downloading owncloud-${version}.tar.bz2 ..." && \
    curl -LOC- -s ${url}/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    tar -xf owncloud-${version}.tar.bz2 -C /var/www owncloud && \
    mkdir -p /var/www/owncloud/data && \
    conf=/etc/lighttpd/lighttpd.conf && \
    sed -i '/server.errorlog/s|var/log/lighttpd/error.log|dev/stderr|' $conf &&\
    sed -i '/server.document-root/s|/html||' $conf && \
    sed -i '/mod_rewrite/a \ \t"mod_setenv",' $conf && \
    echo '\nsetenv.add-response-header += ( "X-XSS-Protection" => "1; mode=block" )' \
                >>$conf && \
    echo 'setenv.add-response-header += ( "X-Content-Type-Options" => "nosniff" )' \
                >>$conf && \
    echo 'setenv.add-response-header += ( "X-Robots-Tag" => "none" )' >>$conf&&\
    echo 'setenv.add-response-header += ( "X-Frame-Options" => "SAMEORIGIN" )' \
                >>$conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud/(?:\.htaccess|data|config|db_structure\.xml|README)" {' \
                >>$conf && \
    echo '\turl.access-deny = ("")' >>$conf && \
    echo '}' >>$conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud($|/)" {' >>$conf && \
    echo '\tdir-listing.activate = "disable"' >>$conf && \
    echo '}' >>$conf && \
    /bin/echo -e 'url.redirect  = ("^/$" => "/owncloud")' >>$conf && \
    unset conf && \
    sed -i 's|var/log/lighttpd/access.log|dev/stdout|' \
                /etc/lighttpd/conf-available/10-accesslog.conf && \
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
    lighttpd-enable-mod accesslog && \
    lighttpd-enable-mod fastcgi-php && \
    for i in /etc/php/7.0/*/php.ini; do \
        sed -i 's|^;*\(doc_root\) *=.*|\1 = "/var/www"|' $i; \
        sed -i 's/^;*\(expose_php\) *=.*/\1 = On/' $i; \
        sed -i 's/^;*\(max_execution_time\) *=.*/\1 = 3600/' $i; \
        sed -i 's/^;*\(max_input_time\) *=.*/\1 = 3600/' $i; \
        sed -i 's/^;*\(output_buffering\) *=.*/\1 = 0/' $i; \
        sed -i 's/^;*\(post_max_size\) *=.*/\1 = 16G/' $i; \
        sed -i 's/^;*\(upload_max_filesize\) *=.*/\1 = 16G/' $i; \
        sed -i 's/^;*\(opcache.enable\) *=.*/\1 = 1/' $i; \
        sed -i 's/^;*\(opcache.enable_cli\) *=.*/\1 = 1/' $i; \
        sed -i 's/^;*\(opcache.fast_shutdown\) *=.*/\1 = 1/' $i; \
        sed -i 's/^;*\(opcache.interned_strings_buffer\) *=.*/\1 = 8/' $i; \
        sed -i 's/^;*\(opcache.max_accelerated_files\) *=.*/\1 = 4000/' $i; \
        sed -i 's/^;*\(opcache.memory_consumption\) *=.*/\1 = 128/' $i; \
        sed -i 's/^;*\(opcache.revalidate_freq\) *=.*/\1 = 60/' $i; \
    done && \
    echo '\n[apc]\napc.enable_cli = 1' >>/etc/php/7.0/mods-available/apcu.ini&&\
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

VOLUME ["/var/cache/lighttpd", "/var/www/owncloud"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]