# Development

This document describes the development and release workflow for the container-focused LNReader Remote Service.

# Project Version

The current project version is stored in VERSION and mirrored in pyproject.toml and the default image tag in docker-compose.yml.

Current version:

```text
0.3.0
```

Version changes should update those locations together.

# Runtime Architecture

Nginx listens on container port 8000.

Gunicorn serves the LNReader-compatible Python API on 127.0.0.1:8001.

PHP-FPM serves the read-only status console on 127.0.0.1:9000.

Supervisor manages Nginx, Gunicorn, and PHP-FPM after the entrypoint completes root-only initialization and drops privileges to the lnreader user.

Persistent backup data and generated Web UI credentials are stored under /home/lnreader/.LNReader inside the container.

Runtime state and service logs are stored under /run/lnreader.

# Version Pins

The production Python dependency versions are stored in requirements-docker.txt and pyproject.toml.

The test dependency versions are stored in requirements-test.txt and pyproject.toml.

The Dockerfile pins the Python base image to the 3.13.15 Bookworm slim release and pins the directly installed Debian package versions.

The GitHub Actions workflow uses explicit action release versions instead of floating major-version aliases. The QEMU binfmt image is also versioned explicitly.

When changing a pin, update the relevant validation checks in scripts/validate.py and run the complete test suite before committing.

# Local Setup

Create a virtual environment outside or inside the repository.

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-test.txt
```

# Tests

Run static validation.

```bash
python scripts/validate.py
```

Run Python tests.

```bash
python -m pytest -vv -ra
```

Run the live HTTP integration test.

```bash
python scripts/live-http-test.py
```

Run Web UI tests when PHP and htpasswd are installed.

```bash
./scripts/webui-test.sh
```

Run everything available on the current system.

```bash
./scripts/test-verbose.sh
```

# Docker Development

Build the local image.

```bash
docker build --progress=plain -t lnreader-remote-service:local .
```

Run the container smoke test.

```bash
./scripts/container-smoke-test.sh lnreader-remote-service:local
```

Run the user-facing Compose configuration.

```bash
docker compose up -d
```

Stop it.

```bash
docker compose down
```

# Portable Defaults

The default storage location is ./data.

The default host port is 8000 and the internal service port remains 8000.

PUID and PGID are optional. When they are blank, the entrypoint keeps a non-root identity and attempts to reuse an existing non-root owner of the mounted storage directory where practical.

Users on Docker Desktop do not need Linux UID or GID settings.

# Release Process

Run the full tests first.

```bash
./scripts/test-verbose.sh
```

Verify the working tree.

```bash
git status --short
git diff --check
```

Commit the release changes.

```bash
git add -A
git commit -m "Release v0.3.0"
```

Push main.

```bash
git push origin main
```

Create and push the release tag.

```bash
git tag -a v0.3.0 -m "LNReader Remote Service v0.3.0"
git push origin v0.3.0
```

The tag workflow publishes versioned GHCR tags. The main branch also publishes latest.

# Repository History Reset

A maintainer who intentionally wants a single root commit can create an orphan branch from the final working tree and force-push it.

This rewrites branch history and should only be done deliberately.

```bash
git status --short
git checkout --orphan clean-main
git add -A
git commit -m "LNReader Remote Service v0.3.0"
git branch -M main
git push --force origin main
```

After the history reset, recreate the release tag.

```bash
git tag -f -a v0.3.0 -m "LNReader Remote Service v0.3.0"
git push --force origin v0.3.0
```

GitHub can still identify the repository as a fork even when main contains only one root commit. Removing the fork relationship requires repository-level action outside Git history.

# Upstream

The API implementation is derived from the MIT-licensed LNReader remote-service project.

https://github.com/lnreader/remote-service

Changes to upstream-compatible routes should preserve client compatibility unless a deliberate breaking release is being made.
