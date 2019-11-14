#!/bin/bash
set -eux

sed -i 's#^DocumentRoot ".*#DocumentRoot "/var/www/html"#g' /etc/apache2/httpd.conf
sed -i 's#Directory "/var/www/localhost/htdocs"#Directory "/var/www/html"#g' /etc/apache2/httpd.conf
sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf

# Check if user exists
if ! id -u ${APACHE_RUN_USER} > /dev/null 2>&1; then
	echo "The user ${APACHE_RUN_USER} does not exist, creating..."
	addgroup ${APACHE_RUN_GROUP}
	adduser -G ${APACHE_RUN_GROUP} -D ${APACHE_RUN_USER}
fi

groupmod -o -g ${APACHE_RUN_GROUP_ID} ${APACHE_RUN_GROUP}
usermod -o -u ${APACHE_RUN_USER_ID} ${APACHE_RUN_USER}
groupmod -o -g ${APACHE_RUN_GROUP_ID} apache
usermod -o -u ${APACHE_RUN_USER_ID} apache

# Install FileRun on first run
if [ ! -e /var/www/html/index.php ];  then
	echo "[FileRun fresh install]"
	unzip /filerun.zip -d /var/www/html/
	mkdir /var/www/html/ng/
	unzip /ng.zip -d /var/www/html/ng/
	rm /filerun.zip
	rm /ng.zip
	mv /autoconfig.php /var/www/html/system/data/
	chown -R ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /var/www/html
	chown ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /user-files
	mysql_host="${FR_DB_HOST:-mysql}"
	mysql_port="${FR_DB_PORT:-3306}"
	/wait-for-it.sh $mysql_host:$mysql_port -t 120 -- /import-db.sh
fi

exec "$@"
