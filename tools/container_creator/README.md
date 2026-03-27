# Container Creator

A Docker-based development environment featuring automated setup and persistent storage for ML/development workloads.

## Overview

Container Creator provides a simple Docker development environment with:
- **Smart container management** - Automatically handles container states (create, start, stop, remove)
- **Volume-based storage** - Workspace and datasets are mounted from host for persistence
- **Intel XPU support** - Built on Intel's optimized base image
- **Proxy-friendly** - Corporate network support with configurable proxy settings
- **One-command operations** - Simple script interface for all container operations

## Prerequisites

- Docker and Docker Compose installed
- Linux environment (tested on Ubuntu)
  - Base Linux container must be XPU compatible.
- Sufficient disk space for datasets and workspace
- Network access for image pulls and package installations

## Quick Start

1. Clone this repo:

   ```bash
   git clone https://github.com/aagalleg/torch-xpu-ops.git
   cd torch-xpu-ops/tools/container_creator
   ```
2. Create a .env file in tools/container_creator and set your variables there. For example:

   ```bash
   # Set the base image used by container
   BASE_IMAGE=your-image-name:1.0.0
   # Set the image name to be created
   IMAGE_NAME=test/xpu-dev:latest
   # Set the path to workspace dir in host
   WORKSPACE=/your_user/workspace
   # Set the path to dataset in host
   DATASET_PATH=/path/to/your/dataset
   # Set container name. Name must not be repeated between containers.
   CONTAINER_NAME=your_container_name
   # Set name of the project where user containers are created. Set it to your user.
   PROJECT_NAME=your_project_name

   #Set proxy variables if necessary
   # http_proxy=
   # https_proxy=
   # no_proxy=
   ```

   Or export all the variables:
   ```bash
   export BASE_IMAGE=your-image-name:1.0.0
   export IMAGE_NAME=test/xpu-dev:latest
   export WORKSPACE=/your_user/workspace
   export DATASET_PATH=/path/to/your/dataset
   export CONTAINER_NAME=your_container_name
   export PROJECT_NAME=your_project_name
   ```
   NOTE: User must provide XPU compatible base image

3. Build the docker image:
   ```bash
   ./create_container.sh --build
   ```

4. Start your development container:
   ```bash
   ./create_container.sh --start
   ```

5. Access the container shell:
   ```bash
   ./create_container.sh --shell
   ```


## Script Commands

The `create_container.sh` script provides five main operations:

### Build Docker image

```bash
./create_container.sh --build
```

Use this option to build Docker images with PyTorch XPU. Activate the “pytorch” conda environment if needed.

### Start Container
```bash
./create_container.sh --start
```
**Smart behavior:**
- `--start` needs variables in `.env` file to work.
- If container doesn't exist → Creates new container from image `${IMAGE_NAME}`
- If container exists but stopped → Starts the existing container  
- If container is already running → Reports status and exits

### Access Shell
```bash
./create_container.sh --shell [CONTAINER_NAME]
```
**Options:**
- No name provided → Uses `CONTAINER_NAME` from `.env` file
- Name provided → Connects to specified container

**Behavior:**
- If container is running → Connects directly to bash shell
- If container is stopped → Shows message to start it first
- If container doesn't exist → Shows error message

### Stop Container
```bash
./create_container.sh --stop CONTAINER_NAME
```
- Stops the specified running container
- Container data and state are preserved
- Can be restarted later with `--start`
- User needs to provide `$CONTAINER_NAME` to prevent stopping wrong containers by mistake

### Remove Container
```bash
./create_container.sh --remove CONTAINER_NAME
```
- **⚠️ DESTRUCTIVE:** Permanently removes the container
- All container data is lost (host-mounted volumes are preserved)
- User needs to provide `$CONTAINER_NAME` to prevent removing wrong containers by mistake
- Use with caution

### Help
```bash
./create_container.sh --help
```
Shows usage information and available commands.

## Configuration

### Environment File (`.env`)
All configuration is managed through the `.env` file:

```bash
BASE_IMAGE=your-image-name:1.0.0               # Docker image to use as base
IMAGE_NAME=test/xpu-dev:latest            # Name for the created image
WORKSPACE=/your_user/workspace            # Host workspace path  
DATASET_PATH=/path/to/your/dataset        # Host datasets path
CONTAINER_NAME=your_container_name        # Container name
PROJECT_NAME=your_project_name            # Docker Compose project name

# Optional proxy settings
# http_proxy=http://proxy.company.com:8080
# https_proxy=http://proxy.company.com:8080  
# no_proxy=localhost,127.0.0.1
```

### Key Configuration Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `BASE_IMAGE` | Base Docker image name and tag | `xpu-dev-img:1.0.0` |
| `IMAGE_NAME` | Created Docker image name and tag  | `test/xpu-dev:latest` |
| `WORKSPACE` | Host directory mounted as `/workspace` | `/home/user/projects` |
| `DATASET_PATH` | Host directory mounted as `/datasets` | `/data/ml-datasets` |
| `CONTAINER_NAME` | Name for your container | `my_dev_container` |
| `PROJECT_NAME` | Docker Compose project (must be unique) | `myproject` |

**⚠️ Important:** `PROJECT_NAME` must be unique across all users to avoid container conflicts.

## Container Specifications

- **Base Image:** Needs a Intel XPU optimized Ubuntu 24.04 as base image
- **Network Mode:** Host networking for maximum performance  
- **Privileges:** Privileged mode enabled for hardware access
- **Memory:** 12GB shared memory allocated
- **Working Directory:** `/workspace`
- **Persistence:** Container runs `tail -f /dev/null` to stay alive

### Volume Mounts
- `${WORKSPACE}` → `/workspace` (your code and projects)
- `${DATASET_PATH}` → `/datasets` (ML datasets and data)

## Troubleshooting

### Configuration Issues

**Container name conflicts:**
- Ensure `CONTAINER_NAME` and `PROJECT_NAME` are unique
- Check existing containers: `docker ps -a`

**Wrong container targeted:**
- Verify container name: `docker ps -a | grep your_image_name`
- Check `.env` file values: `cat .env`

### Network Issues

**Corporate proxy problems:**
```bash
# Set proxy variables in .env. Example:
http_proxy=http://proxy.company.com:8080
https_proxy=http://proxy.company.com:8080
no_proxy=localhost,127.0.0.1,.company.com
```
