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

exec "${@}"
