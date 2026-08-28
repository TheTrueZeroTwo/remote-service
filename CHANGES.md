# Changes

## 0.3.0

Generalized the default Docker Compose configuration for Docker Engine and Docker Desktop.

Removed the OpenMediaVault-specific Compose file and obsolete external htpasswd helper.

Changed host port configuration to HOST_PORT while keeping the container service on port 8000.

Made PUID and PGID optional and added safe non-root ownership detection for mounted storage.

Pinned the release image to v0.3.0 in the end-user Compose file.

Pinned the Python base image version, direct Debian packages, Python dependencies, GitHub Actions releases, CI Python patch versions, and the QEMU binfmt image.

Added VERSION, DEVELOPMENT.md, .gitattributes, and .editorconfig.

Simplified README.md to portable end-user instructions using basic Markdown formatting.

Retained automatic random Web UI credential generation, persistence, bcrypt authentication, live upload reporting, and the non-root runtime model.

## 0.2.0

Added the secured read-only PHP status console, streaming uploads, atomic commits, upload progress reporting, GHCR publication, multi-architecture builds, and extensive container tests.
