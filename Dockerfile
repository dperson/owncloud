FROM debian:jessie
MAINTAINER David Personette <dperson@gmail.com>

# Install php and ownCloud
RUN export DEBIAN_FRONTEND='noninteractive' && \
    export version='9.0.2' && \
    export sha256sum='845c43fe981fa0fd07fc3708f41f1ea15ecb11c2a15c65a4de19' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends ca-certificates curl && \
    echo "deb http://packages.dotdeb.org jessie all" \
                >>/etc/apt/sources.list.d/dotdeb.list && \
    curl -Ls https://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends bzip2 openssl \
                php7.0-apcu php7.0-fpm php7.0-gd php7.0-intl php7.0-mcrypt \
                php7.0-mysql php7.0-opcache php7.0-pgsql php7.0-sqlite3 \
                php7.0-curl php7.0-gmp php7.0-imap php7.0-json php7.0-ldap \
                php7.0-redis php7.0-memcached smbclient \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    echo "downloading owncloud-${version}.tar.bz2 ..." && \
    curl -LOC- -s \
        https://download.owncloud.org/community/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    mkdir -p /var/www && \
    tar -xf owncloud-${version}.tar.bz2 -C /var/www owncloud && \
    mkdir -p /var/www/owncloud/data && \
    for i in /etc/php/7.0/*/php.ini; do \
        sed -i '/^output_buffering/s/4096/0/' $i; \
        sed -i '/^expose_php/s/Off/On/' $i; \
        sed -i '/^post_max_size/s/8M/16G/' $i; \
        sed -i '/^upload_max_filesize/s/2M/16G/' $i; \
        sed -i '/^max_execution_time/s/[0-9][0-9]*/3600/' $i; \
        sed -i '/^max_input_time/s/[0-9][0-9]*/3600/' $i; \
    done && \
    { echo 'opcache.enable_cli=1'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.revalidate_freq=60'; } \
                >>/etc/php/mods-available/opcache.ini && \
    find /var/www/owncloud -type f -print0 | xargs -0 chmod 0640 && \
    find /var/www/owncloud -type d -print0 | xargs -0 chmod 0750 && \
    { chown -Rh root:www-data /var/www/owncloud || :; } && \
    chown -Rh www-data. /var/www/owncloud/apps /var/www/owncloud/config \
                /var/www/owncloud/data /var/www/owncloud/themes && \
    { chown -Rh root:www-data /var/www/owncloud/data/.htaccess || :; } && \
    apt-get purge -qqy ca-certificates curl && \
    apt-get autoremove -qqy && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* owncloud-${version}.tar.bz2
COPY owncloud.sh /usr/bin/

VOLUME ["/var/www/owncloud"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]