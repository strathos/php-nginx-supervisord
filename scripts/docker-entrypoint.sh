#!/usr/bin/env bash
set -e

if [ -n "${PUID-}" ]; then
  usermod -u "${PUID}" www-data
  chown www-data:www-data /home/www-data
  chown -R www-data:www-data /var/www
fi

if [ -n "${PGID-}" ]; then
  groupmod -g "${PGID}" www-data
  chown -R www-data:www-data /home/www-data
  chown -R www-data:www-data /var/www
fi

until nc -z -v -w30 "${DB_HOST}" 3306; do
  echo "Waiting for database connection..."
  sleep 5
done

if [ -f composer.json ]; then
  drush updb -y
  drush cim -y
  drush cr -y
fi

exec "${@}"
