FROM dperson/nginx
MAINTAINER David Personette <dperson@dperson.com>

# ownCloud file info
ENV version 7.0.3
ENV sha256sum 08a8949079873e253c8c9b0e60d9ecc2ccac92740a497315a8dad2919116ac20

# Install php and ownCloud
RUN TERM=dumb apt-get update -qq && \
    TERM=dumb apt-get install -qqy --no-install-recommends curl php5 php5-cli \
                php5-gd php5-pgsql php5-sqlite php5-mysqlnd php5-curl php5-intl\
                php5-mcrypt php5-ldap php5-gmp php5-apcu php5-imagick php5-fpm \
                php5-json smbclient && \
    TERM=dumb apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -LOC- -ks \
                https://download.owncloud.org/community/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    tar -xf owncloud-${version}.tar.bz2 -C /var/www && \
    mkdir /var/www/owncloud/data && \
    rm owncloud-${version}.tar.bz2 /usr/bin/nginx.sh \
                /etc/nginx/sites-enabled/default

# Config files
COPY owncloud /etc/nginx/sites-enabled/
COPY owncloud.sh /usr/bin/
COPY php.ini /etc/php5/fpm/

VOLUME ["/var/www/owncloud/data"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]
