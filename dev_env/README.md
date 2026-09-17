# 49er Robotics Development Environment

Docker-based development environment for the 49er Robotics / IGVC software stack.

The development environment is based on **ROS 2 Jazzy** and is published as a multi-platform Docker image supporting both `linux/amd64` and `linux/arm64`.

## Overview

The `dev_env` image provides a consistent development environment across team members' computers and the robot's ARM64 hardware.

The image includes:

* ROS 2 Jazzy
* ROS 2 packages used by the IGVC software stack
* ZED ROS 2 interfaces
* ROS 2 Zenoh middleware
* Docker CLI
* Python development tools
* `r2s`
* `robot-folders`
* Git and common development utilities
* Zsh and Oh My Zsh
* Development and debugging utilities

The image is intended to be used through the project's development environment configuration, such as the VS Code Dev Container workflow.

## Published Image

The current published image is:

```text
ghcr.io/gold-rush-robotics/dev_env:9
```

The image supports:

| Platform      | Architecture                        |
| ------------- | ----------------------------------- |
| `linux/amd64` | x86-64 PCs                          |
| `linux/arm64` | ARM64 systems such as NVIDIA Jetson |

Docker automatically selects the appropriate architecture when pulling the image.

```bash
docker pull ghcr.io/gold-rush-robotics/dev_env:9
```

## Prerequisites

### Docker

Docker with Buildx and Bake support is required.

Verify Docker:

```bash
docker --version
docker buildx version
docker buildx bake --help
```

### Git

Git is required to clone the repository and use the build script.

Verify Git:

```bash
git --version
```

### GitHub Container Registry

A GitHub account with permission to publish to the `gold-rush-robotics` GitHub Container Registry is required when publishing images.

Authenticate with GHCR:

```bash
docker login ghcr.io
```

When prompted:

* **Username:** your GitHub username
* **Password:** a GitHub Personal Access Token (PAT) with the permissions required to publish packages

You only need to authenticate when publishing to GHCR. Authentication is not required to build the image locally.

## Building

The repository uses Docker Buildx Bake for image configuration and a `build.sh` script to handle build environment setup.

The script automatically:

1. Checks that Docker is available.
2. Creates the required Buildx builder if it does not already exist.
3. Selects the builder.
4. Bootstraps the builder.
5. Checks whether ARM64 support is available.
6. Installs ARM64 emulation if necessary.
7. Runs the Docker Bake configuration.

### Standard build

To build the multi-platform image without publishing it:

```bash
./build.sh
```

The image is built for:

```text
linux/amd64
linux/arm64
```

When using the `docker-container` Buildx driver, a multi-platform build is not automatically loaded into the local Docker image store. The resulting image may remain in the BuildKit cache unless an output is specified.

### Build and publish

The normal release workflow is:

```bash
docker login ghcr.io
./build.sh --push
```

This builds both supported architectures and publishes the resulting multi-platform image to:

```text
ghcr.io/gold-rush-robotics/dev_env:9
```

### Building a single architecture

A single architecture can be selected through the Bake configuration without modifying `docker-bake.hcl`.

AMD64:

```bash
./build.sh --set '*.platforms=linux/amd64'
```

ARM64:

```bash
./build.sh --set '*.platforms=linux/arm64'
```

For example, a single AMD64 image can be loaded into the local Docker image store with:

```bash
./build.sh \
    --set '*.platforms=linux/amd64' \
    --load
```

This is useful for testing the image locally on an AMD64 development machine.

## Changing the Image Version

The image version is defined in `docker-bake.hcl`.

The current version is:

```text
9
```

A different version can be supplied without modifying the Bake file:

```bash
./build.sh \
    --set VERSION=10 \
    --push
```

This publishes:

```text
ghcr.io/gold-rush-robotics/dev_env:10
```

## Testing With a Different Image Name

An alternate image name can be supplied when testing changes:

```bash
./build.sh \
    --set IMAGE=ghcr.io/gold-rush-robotics/dev_env-test \
    --push
```

This allows changes to be tested without replacing the primary development environment image.

## Verifying a Published Image

After publishing, inspect the image manifest:

```bash
docker buildx imagetools inspect \
    ghcr.io/gold-rush-robotics/dev_env:9
```

The output should contain manifests for both:

```text
linux/amd64
linux/arm64
```

To verify the image locally:

```bash
docker pull ghcr.io/gold-rush-robotics/dev_env:9
```

Docker automatically selects the appropriate architecture for the host.

You can verify the selected architecture with:

```bash
docker image inspect \
    ghcr.io/gold-rush-robotics/dev_env:9 \
    --format '{{.Architecture}}'
```

## Development Environment Usage

The `dev_env` image is intended to be consumed by the project's development environment configuration.

When used through a VS Code Dev Container configuration, the container provides the development environment while the project's source code is mounted into the container.

The image should generally **not** be modified manually inside a running container. Changes that should be shared with the team should instead be made to the Dockerfile or related configuration and published as a new image version.

## dev_env Additional Contents

### `docker-bake.hcl`

Defines the canonical Docker Buildx Bake configuration, including:

* Image name
* Image version
* Target platforms
* Dockerfile
* Build configuration

### `build.sh`

Provides the standard build entry point.

The script handles Buildx builder setup and ARM64 support before passing arguments to Docker Bake.

### `README.md`

Documents how to build, publish, verify, and use the development environment.

## Updating the Development Environment

When modifying the development environment:

1. Make the required changes to the `Dockerfile` or related configuration.
2. Build the image locally.
3. Test the affected functionality.
4. Verify both target architectures when the change may affect platform compatibility.
5. Update the image version when publishing a new release.
6. Authenticate with GHCR.
7. Publish the new multi-platform image.
8. Verify the published manifest.
9. Update the project's Dev Container configuration if it should use the new image version.

For a normal release:

```bash
docker login ghcr.io
./build.sh --push
```

## Versioning

Image versions are represented by Docker image tags:

```text
ghcr.io/gold-rush-robotics/dev_env:<version>
```

For example:

```text
ghcr.io/gold-rush-robotics/dev_env:9
ghcr.io/gold-rush-robotics/dev_env:10
```

Published versions should be treated as immutable development-environment releases. Avoid republishing different contents under an existing version unless there is a specific reason to do so.

## Troubleshooting

### Buildx builder problems

The build script automatically creates the required builder if it does not exist.

To manually inspect the builder:

```bash
docker buildx ls
```

Or:

```bash
docker buildx inspect multi-platform-builder --bootstrap
```

The `dev_env` image is part of the [`docker_images`](../) repository.

