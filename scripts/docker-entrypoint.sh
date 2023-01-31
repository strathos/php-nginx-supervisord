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
  echo
  echo "STARTUP: Waiting for database connection..."
  echo
  sleep 5
done

if [ -d vendor/drush ]; then
  echo
  echo "DRUSH: Rebuilding cache..."
  echo
  drush cr -y

  echo
  echo "DRUSH: Applying any database updates..."
  echo
  drush updb -y

  if [ -d config/sync ]; then
    echo
    echo "DRUSH: Importing config..."
    echo
    drush cim -y

    echo
    echo "DRUSH: Rebuilding cache..."
    echo
    drush cr -y
  fi

fi

echo
echo "STARTUP: Starting supervisord..."
echo
exec "${@}"
