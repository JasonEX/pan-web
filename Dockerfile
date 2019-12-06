FROM php:7.3-alpine

RUN apk --no-cache add bash shadow apache2 apache2-proxy php7-apache2 php7-ldap \
    php7-gd php7-pdo_mysql php7-opcache php7-mbstring php7-zip php7-xml php7-curl php7-ctype \
    php7-session php7-json mariadb-client

ARG ENABLE_SSL
ENV ENABLE_SSL ${ENABLE_SSL}
RUN [ -n "${ENABLE_SSL}" ] && apk add --no-cache apache2-ssl && echo "SSL enabled" || echo "SSL not enabled"
RUN [ -n "${ENABLE_SSL}" ] && sed -i 's/-SSLv3/-SSLv3 +TLSv1.3/g' /etc/apache2/conf.d/ssl.conf \
    && sed -i 's/^DocumentRoot.*$/DocumentRoot "\/var\/www\/html"/g' /etc/apache2/conf.d/ssl.conf \
    && sed -i 's/^SSLCertificateFile.*$/SSLCertificateFile \/user-ssl\/server.pem/g' /etc/apache2/conf.d/ssl.conf \
    && sed -i 's/^SSLCertificateKeyFile.*$/SSLCertificateKeyFile \/user-ssl\/server.key/g' /etc/apache2/conf.d/ssl.conf || :

ARG ENABLE_IMAGE_PREVIEW
ARG ENABLE_VIDEO_PREVIEW
RUN [ -n "${ENABLE_IMAGE_PREVIEW}" ] && apk add --no-cache graphicsmagick && echo "Image preview enabled" || echo "Image preview not enabled"
RUN [ -n "${ENABLE_VIDEO_PREVIEW}" ] && apk add --no-cache ffmpeg && echo "Video preview enabled" || echo "Video preview not enabled"

COPY aux-files/filerun-optimization.ini /etc/php7/conf.d/

RUN curl -LO http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
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
ENV ARIA2_HOST aria2
ENV ARIA2_PORT 6800
ENV ARIA2_RPC_SECRET ""
ENV WEB_PORT ${ENABLE_SSL:+443}
ENV WEB_PORT ${WEB_PORT:-80}

COPY aux-files/db.sql /filerun.setup.sql
COPY aux-files/autoconfig.php /
COPY aux-files/ws-reverse-proxy.conf /wrp-template.conf

VOLUME ["/var/www/html", "/user-files"]

COPY aux-files/wait-for-it.sh aux-files/import-db.sh aux-files/entrypoint.sh /
RUN chmod +x /wait-for-it.sh /import-db.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["httpd","-D","FOREGROUND"]
