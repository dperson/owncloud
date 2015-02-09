FROM dperson/nginx
MAINTAINER David Personette <dperson@dperson.com>

# ownCloud file info
ENV DEBIAN_FRONTEND noninteractive
ENV version 8.0.0
ENV sha256sum 0c62cb06fe4c3eb107bccc4302f2bb3b9f7e5373cf7c9dd307fea8e823e6342f

# Install php and ownCloud
RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends curl php5 php5-cli php5-gd \
                php5-pgsql php5-sqlite php5-mysqlnd php5-curl php5-intl \
                php5-mcrypt php5-ldap php5-gmp php5-apcu php5-imagick php5-fpm \
                php5-json smbclient && \
    apt-get clean && \
    curl -LOC- -ks \
        https://download.owncloud.org/community/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    tar -xf owncloud-${version}.tar.bz2 -C /var/www && \
    mkdir /var/www/owncloud/data && \
    rm -rf /var/lib/apt/lists/* /tmp/* owncloud-${version}.tar.bz2 \
                /etc/nginx/sites-enabled/default

# Config files
COPY owncloud /etc/nginx/sites-enabled/
COPY owncloud.sh /usr/bin/
COPY php.ini /etc/php5/fpm/

VOLUME ["/var/www/owncloud/data"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]
