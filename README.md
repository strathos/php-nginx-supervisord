# Alpine + php-fpm + nginx + supervisord
This image is based on Alpine Linux and bundles php-fpm, Nginx and supervisord in a one image.
## Why?
As php applications usually run a separate php-fpm and a web server, it's hard to include static files to a build. I know this is against container philosophy to have multiple applications in a single container, but with php there really isn't a good way to handle this.

This image is mainly intended for Drupal and the included packages are according to their documentation.
## How?
The configuration is based on how Wodby does things. That's why the source code should be in a directory called src and it should be mounted/copied to /var/www/html/web inside the container.

User inside the container is www-data with UID and GID of 1000 by default. These can be changed with environment variables PUID and PGID.

Nginx is listening on 8080 and running as www-data (non-root).

Nginx and php-fpm are connected via Unix socket (unix:/run/php-fpm.sock) instead of TCP socket. However as the parent Dockerfile exposes the port 9000, it will be listed as exposed even though nothing is listening on it.

Included tools are Composer and the runner for Drush.

Example docker-compose.yml file for development work:
```yaml
version: '3'

services:
  app:
    image: strathos/php-nginx-supervisord:latest
    container_name: app
    #environment:
    #  PUID: 1001
    #  PGID: 1001
    ports:
      - 8888:8080
    volumes:
      - ./src:/var/www/html/web
```
