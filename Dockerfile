FROM php:7.3-alpine

#RUN apk --no-cache add bash php7 php7-fpm php7-mysqli php7-json php7-openssl php7-curl \
#    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
#    php7-mbstring php7-gd nginx supervisor curl ffmpeg libjpeg-turbo-dev freetype-dev 
RUN apk --no-cache add bash shadow apache2 php7-apache2 php7-ldap \
    php7-gd php7-pdo_mysql php7-opcache php7-mbstring php7-zip php7-xml php7-curl php7-ctype \
    php7-session php7-json mariadb-client

COPY aux-files/filerun-optimization.ini /etc/php7/conf.d/

RUN whoami && curl -LO http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar xzvf ioncube_loaders_lin_x86-64.tar.gz \
#    && PHP_EXT_DIR=$(php -i | grep extension_dir | awk '{print $3}') \
#    && PHP_EXT_DIR=$(php-config --extension-dir) \
    && PHP_EXT_DIR=/usr/lib/php7/modules/ \
    && cp "ioncube/ioncube_loader_lin_7.3.so" $PHP_EXT_DIR \
    && echo "zend_extension=ioncube_loader_lin_7.3.so" >> /etc/php7/conf.d/00_ioncube_loader_lin_7.3.ini \
    && rm -rf ioncube ioncube_loaders_lin_x86-64.tar.gz

RUN curl -o /filerun.zip -L https://filerun.com/download-latest-php73 \
    && mkdir /user-files \
    && chown xfs:xfs /user-files

ARG NG_VER='1.1.4'

RUN curl -o /ng.zip -L https://github.com/mayswind/AriaNg/releases/download/${NG_VER}/AriaNg-${NG_VER}.zip

ENV FR_DB_HOST db
ENV FR_DB_PORT 3306
ENV FR_DB_NAME filerun
ENV FR_DB_USER filerun
ENV FR_DB_PASS filerun
ENV APACHE_RUN_USER nobody
ENV APACHE_RUN_USER_ID 65534
ENV APACHE_RUN_GROUP nobody
ENV APACHE_RUN_GROUP_ID 65534

COPY aux-files/db.sql /filerun.setup.sql
COPY aux-files/autoconfig.php /

VOLUME ["/var/www/html", "/user-files"]

COPY aux-files/entrypoint.sh /
COPY aux-files/wait-for-it.sh /
COPY aux-files/import-db.sh /
RUN chmod +x /wait-for-it.sh
RUN chmod +x /import-db.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["httpd","-D","FOREGROUND"]
