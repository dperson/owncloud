FROM debian:stretch
MAINTAINER David Personette <dperson@gmail.com>

# Install php and ownCloud
    #echo "deb http://packages.dotdeb.org stretch all" \
    #            >>/etc/apt/sources.list.d/dotdeb.list && \
    #curl -Ls https://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
    #php7.0-apcu-bc php7.0-imagick
RUN export DEBIAN_FRONTEND='noninteractive' && \
    export url='https://download.owncloud.org/community' && \
    export version='9.1.1' && \
    export sha256sum='a6bf3531ebb7e09a11aaae641bc3af933f339261424782841c64' && \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends bzip2 ca-certificates curl \
                lighttpd openssl smbclient php7.0-bz2 php7.0-cgi php7.0-curl \
                php7.0-gd php7.0-gmp php7.0-imap php7.0-intl php7.0-json \
                php7.0-ldap php7.0-mbstring php7.0-mcrypt php7.0-mysql \
                php7.0-opcache php7.0-pgsql php7.0-sqlite3 php7.0-xml \
                php7.0-zip \
                $(apt-get -s dist-upgrade|awk '/^Inst.*ecurity/ {print $2}') &&\
    echo "downloading owncloud-${version}.tar.bz2 ..." && \
    curl -LOsC- ${url}/owncloud-${version}.tar.bz2 && \
    sha256sum owncloud-${version}.tar.bz2 | grep -q "$sha256sum" && \
    conf=/etc/lighttpd/lighttpd.conf dir=/etc/lighttpd/conf-available \
                header=setenv.add-response-header \
                match='(?:\.htaccess|data|config|db_structure\.xml|README)' && \
    sed -i '/server.errorlog/s|^|#|' $conf && \
    sed -i '/server.document-root/s|/html||' $conf && \
    sed -i '/mod_rewrite/a\ \t"mod_setenv",' $conf && \
    echo "\\n$header"' += ( "X-XSS-Protection" => "1; mode=block" )' >>$conf &&\
    echo "$header"' += ( "X-Content-Type-Options" => "nosniff" )' >>$conf && \
    echo "$header"' += ( "X-Robots-Tag" => "none" )' >>$conf&& \
    echo "$header"' += ( "X-Frame-Options" => "SAMEORIGIN" )' >>$conf && \
    echo '\n$HTTP["url"] =~ "^/owncloud($|/)" {' >>$conf && \
    echo '\tdir-listing.activate = "disable"\n}' >>$conf && \
    echo '$HTTP["url"] =~ "^/owncloud/'"$match"'" {' >>$conf && \
    echo '\turl.access-deny = ("")\n}' >>$conf && \
    echo '\nurl.redirect  = ("^/$" => "/owncloud")' >>$conf && \
    sed -i 's|var/log/lighttpd/access.log|tmp/log|' $dir/10-accesslog.conf && \
    sed -i '/^#cgi\.assign/,$s/^#//; /"\.pl"/i\ \t".cgi"  => "/usr/bin/perl",' \
                $dir/10-cgi.conf && \
    sed -i -e '/CHILDREN/s/[0-9][0-9]*/16/' \
                -e '/max-procs/a\ \t\t"idle-timeout" => 20,' \
                $dir/15-fastcgi-php.conf && \
    grep -q 'allow-x-send-file' $dir/15-fastcgi-php.conf || { \
        sed -i '/idle-timeout/a\ \t\t"allow-x-send-file" => "enable",' \
                    $dir/15-fastcgi-php.conf && \
        sed -i '/"bin-environment"/a\ \t\t\t"MOD_X_SENDFILE2_ENABLED" => "1",' \
                    $dir/15-fastcgi-php.conf; } && \
    unset conf dir header match && \
    lighttpd-enable-mod accesslog && \
    lighttpd-enable-mod fastcgi-php && \
    for i in /etc/php/7.0/*/php.ini; do \
        sed -i 's|^;*\(doc_root\) *=.*|\1 = "/var/www"|' $i; \
        sed -i '/php_errors\.log/s|^;*\(error_log\) *=.*|\1 = /tmp/log|' $i; \
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
    apt-get purge -qqy ca-certificates curl && \
    apt-get autoremove -qqy && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
COPY owncloud.sh /usr/bin/

VOLUME ["/var/cache/lighttpd", "/var/www/owncloud"]

EXPOSE 80

ENTRYPOINT ["owncloud.sh"]