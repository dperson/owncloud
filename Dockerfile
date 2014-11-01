FROM dperson/nginx
MAINTAINER David Personette <dperson@dperson.com>

# OwnCloud file info
ENV version 7.0.2
ENV sha256sum ea07124a1b9632aa5227240d655e4d84967fb6dd49e4a16d3207d6179d031a3a

# Install php and owncloud
RUN apt-get update && \
    apt-get install -qqy curl php5 php5-cli php5-gd php5-pgsql php5-sqlite \
                php5-mysqlnd php5-curl php5-intl php5-mcrypt php5-ldap php5-gmp\
                php5-apcu php5-imagick php5-fpm php5-json smbclient && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -LOC- -s https://download.owncloud.org/community/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    tar -xf owncloud-${version}.tar.gz -C /var/www && \
    rm -r owncloud-${version}.tar.gz && \
    mkdir /var/www/owncloud/data && \
    rm /usr/bin/nginx.sh

# Configure
COPY owncloud /etc/nginx/sites-available/
COPY owncloud.sh /usr/bin/
COPY php.ini /etc/php5/fpm/
RUN rm /etc/nginx/sites-enabled/* && \
    ln -s ../sites-available/owncloud /etc/nginx/sites-enabled/

VOLUME ["/var/www/owncloud/data"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]
