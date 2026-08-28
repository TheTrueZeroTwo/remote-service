# LNReader Remote Service

A container-focused distribution of the LNReader Remote Service backup API with a secured read-only status console.

The project is derived from the MIT-licensed LNReader remote-service project and keeps the LNReader-compatible backup routes while providing a prebuilt multi-architecture container.

Upstream project:

https://github.com/lnreader/remote-service

# Quick Start

**Requirements**

Docker Engine with Docker Compose, or Docker Desktop with Compose support.

**Start the service**

```bash
docker compose up -d
```

No .env file and no password file are required.

The default deployment stores data in the local data directory and exposes the service on host port 8000.

# First Login

On first start the container creates a random password for the default Web UI user named admin.

The password is saved in the persistent LNReader storage directory and is not regenerated during normal container restarts or recreations.

**Show the generated login**

```bash
docker compose logs 2>&1 | sed -n '/LNReader Web UI credentials generated automatically/,+15p'
```

**Recover the saved login later**

```bash
docker compose exec lnreader sh -c '
printf "Username: "; cat /home/lnreader/.LNReader/.webui-auth/username; echo
printf "Password: "; cat /home/lnreader/.LNReader/.webui-auth/password; echo
'
```

# URLs

The LNReader API uses the base address of the host running Docker.

For a system at 192.168.1.10 with the default port, use this address in LNReader:

```text
http://192.168.1.10:8000
```

The default status console is:

```text
http://192.168.1.10:8000/lnr-vault-7f3c9/
```

The status-console path is not part of the server address entered in LNReader.

# Optional Configuration

Copy the example file only when you want to change a default.

```bash
cp .env.example .env
```

The default Compose file works without this step.

**Host port**

```env
HOST_PORT=8000
```

**Storage location**

The default is a data directory beside the Compose file.

```env
STORAGE_PATH=./data
```

A Linux host can use an absolute path.

```env
STORAGE_PATH=/srv/lnreader
```

Docker Desktop on macOS can use a normal macOS path.

```env
STORAGE_PATH=/Users/example/LNReader
```

Docker Desktop on Windows can use a Docker-compatible path.

```env
STORAGE_PATH=C:/Users/example/LNReader
```

**Web UI username and password**

Leave WEB_UI_PASSWORD blank to use the automatically generated password.

```env
WEB_UI_USERNAME=admin
WEB_UI_PASSWORD=
```

To choose or change the login, set both values and recreate the service.

```env
WEB_UI_USERNAME=admin
WEB_UI_PASSWORD='replace-with-a-long-random-password'
```

```bash
docker compose up -d --force-recreate
```

The password is converted to bcrypt for Nginx authentication and the selected credential is persisted in the storage directory.

**Public URL**

Set a complete URL when the service is behind a reverse proxy.

```env
PUBLIC_URL=https://lnreader.example.com
```

**Linux UID and GID**

PUID and PGID are optional. Leave them blank on most systems.

```env
PUID=
PGID=
```

On Linux, set them only when the storage directory must use a specific host UID and GID.

```bash
id -u
id -g
```

```env
PUID=1000
PGID=1000
```

The service refuses UID 0 or GID 0 and runs the application processes as a non-root user.

# Updating

The default Compose file pins the release image instead of following latest automatically.

Current release:

```text
ghcr.io/thetruezerotwo/remote-service:v0.3.0
```

When a newer release is available, update LNREADER_IMAGE in .env or update the image value in docker-compose.yml, then run:

```bash
docker compose pull
docker compose up -d
```

The latest tag is also published from the main branch for users who intentionally want the newest development build.

# Status Console

The status console is read-only and contains no JavaScript.

It displays API health, storage usage, stored backups, the most recent backup, current upload progress, container uptime, image version, and the LNReader application URL.

# Security

The status console uses bcrypt HTTP Basic Auth.

A generated password is stored in plaintext inside the persistent storage directory so the first-start credential can be recovered. The credential directory uses restrictive file permissions. Treat the LNReader storage directory as sensitive data.

HTTP Basic Auth does not encrypt traffic. Use HTTPS or a trusted encrypted VPN on untrusted networks.

The LNReader backup API remains unauthenticated for client compatibility. Do not expose raw port 8000 directly to the public Internet unless external network controls provide the protection you require.

# API Compatibility

```text
GET /
GET /healthz
GET /list
POST /upload/<backup_name>&&<filename>
GET /download/<backup_name>&&<filename>
```

Uploads are streamed and committed atomically after the complete request body is received.

# Testing

Install the pinned test dependencies.

```bash
python3 -m pip install -r requirements-test.txt
```

Run the complete local test driver.

```bash
./scripts/test-verbose.sh
```

Docker tests run when a usable Docker engine is available. GitHub Actions repeats the Python, PHP, authentication, container, security, and multi-architecture publication checks before publishing an image.

# Development

Developer setup, architecture, version pins, testing, and release instructions are documented in DEVELOPMENT.md.

# License

Copyright 2023 LNReader and subsequent contributors.

Licensed under the MIT License. See LICENSE.
