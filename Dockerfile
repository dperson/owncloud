FROM dperson/nginx
MAINTAINER David Personette <dperson@dperson.com>

# ownCloud file info
ENV DEBIAN_FRONTEND noninteractive

# Install php and ownCloud
RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends php5 php5-cli php5-gd \
                php5-pgsql php5-sqlite php5-mysqlnd php5-curl php5-intl \
                php5-mcrypt php5-ldap php5-gmp php5-apcu php5-imagick php5-fpm \
                php5-json smbclient && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /etc/nginx/sites-enabled/default

# Config files
ADD https://download.owncloud.org/community/owncloud-7.0.4.tar.bz2 /var/www
COPY owncloud /etc/nginx/sites-enabled/
COPY owncloud.sh /usr/bin/
COPY php.ini /etc/php5/fpm/

VOLUME ["/var/www/owncloud/data"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]
