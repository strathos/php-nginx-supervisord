# Alpine + php-fpm + nginx + supervisord

This image is based on Alpine Linux and bundles php-fpm, Nginx and Supervisord
in a one image.

## Why?

As php applications usually run a separate php-fpm and a web server, it's hard
to include static files to a build. I know this is against container philosophy
to have multiple applications in a single container, but with php there really
isn't a good way to handle this.

This image is mainly intended for Drupal and the included packages are according
to their documentation.

## How?

The configuration is based on how Wodby does things. That's why the source code
should be in a directory called src and it should be mounted/copied to
/var/www/html/web inside the container.

User inside the container is www-data with UID and GID of 1000 by default. These
can be changed with environment variables PUID and PGID.

Nginx is listening on 8080 and running as www-data (non-root).

Nginx and php-fpm are connected via Unix socket (unix:/run/php-fpm.sock) instead
of TCP socket. However as the parent Dockerfile exposes the port 9000, it will
be listed as exposed even though nothing is listening on it.

Included tools are Composer and the runner for Drush.

Example docker-compose.yml file for development work:

```yaml
services:
  app:
    image: strathos/php-nginx-supervisord:latest
    container_name: app
    #environment:
    #  PUID: 1001
    #  PGID: 1001
    ports:
      - 8080:8080
    volumes:
      - ./src:/var/www/html/web
```

## Image build

The `extensions` stage compiles PHP extensions. The final `runtime` stage starts
from the same pinned PHP base and installs the pinned runtime packages, then
copies only extension binaries and their ini files from the builder. Compilers,
development headers, and PECL build artifacts stay in the builder. Runtime tools
such as Git, Composer, and image utilities remain available.

The runtime stage checks that all required extensions load, so a missing shared
library fails the build on either target architecture. When adding an
extension, add its runtime libraries to the pinned runtime package list and
include the module in the loading check.

## Dependency updates

The Dockerfile pins the PHP and Composer images by version and multi-platform
digest, every explicitly installed Alpine package (including build
dependencies), and every PECL extension. Bundled PHP extensions use the sources
in the pinned PHP image. Imagick is installed from a pinned PECL release.

`renovate.json` tracks container images, Alpine packages, PHP extensions, and
GitHub Actions. PHP extension updates use PECL's release endpoints, with
prerelease exceptions configured where needed for compatibility. Alpine package
updates are grouped so runtime and development packages can advance together.

Builds run on pull requests, pushes to main, and manual dispatch. Only main
pushes and manual builds publish the image. Pull requests build amd64 only and
skip QEMU setup. Pushes to main and manual builds build and publish both amd64
and arm64. Local ACT runs use the host platform.

Allowed PHP, Alpine, and Composer versions are defined in `renovate.json` and
the Dockerfile. Some upgrade paths are restricted for compatibility; versions
outside those limits require updating the configuration before Renovate can
propose them.

When upgrading Alpine, update the PHP image tag and the APK registry branch in
`renovate.json` together, refresh the package pins, and verify builds on all
supported architectures.
