#!/bin/bash

# Resolve script directory for reliable .env sourcing
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

COMPOSE_ARGS=(
    --project-directory "${SCRIPT_DIR}"
    -f "${SCRIPT_DIR}/docker-compose.yml"
)

# Default action
ACTION="start"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            ACTION="build"
            shift
            ;;
        --start)
            ACTION="start"
            shift
            ;;
        --shell)
            ACTION="shell"
            if [ -n "$2" ]; then
                CONTAINER_NAME="$2"
                shift 2
            else
                # Source the .env file to get environment variables
                source "${SCRIPT_DIR}/.env"
                shift 1
            fi
            ;;
        --stop)
            echo "Stopping Docker container..."
            ACTION="stop"
            if [ -n "$2" ]; then
                CONTAINER_NAME="$2"
                shift 2
            else
                echo "No container specified for stopping. Please provide a container name."
                exit 1
            fi
            ;;
        --remove)
            echo "Removing Docker container..."
            ACTION="remove"
            if [ -n "$2" ]; then
                CONTAINER_NAME="$2"
                shift 2
            else
                echo "No container specified for removal. Please provide a container name."
                exit 1
            fi
            ;;
        --help|-h)
            echo "Usage: $0 [--build|--start|--stop|--shell|--remove] [--help]"
            echo "  --build   Build the docker image"
            echo "  --start   Start the container"
            echo "  --stop    Stop the container"
            echo "  --shell   Run container and access shell"
            echo "  --remove  Remove the container"
            echo "  --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Execute based on action
case $ACTION in
    "build")
        echo "Building Docker container..."
        # Source the .env file to get CONTAINER_NAME
        source "${SCRIPT_DIR}/.env"
        echo "Creating container: ${CONTAINER_NAME}"
        docker compose "${COMPOSE_ARGS[@]}" --progress plain build create_container
        ;;
    "start")
        echo "Starting Docker container..."
        # Source the .env file to get CONTAINER_NAME
        source "${SCRIPT_DIR}/.env"

        if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            echo "Container ${CONTAINER_NAME} found."
            
            # Check if container is already running
            if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
                echo "Container ${CONTAINER_NAME} is already running."
            else
                echo "Container ${CONTAINER_NAME} exists but is stopped. Starting it..."
                docker start "${CONTAINER_NAME}"
                if [ $? -eq 0 ]; then
                    echo "Container ${CONTAINER_NAME} started successfully."
                else
                    echo "Failed to start container ${CONTAINER_NAME}."
                fi
            fi
        else
            echo "Creating container: ${CONTAINER_NAME}"
            docker compose "${COMPOSE_ARGS[@]}" -p "${PROJECT_NAME}" run -d --name "${CONTAINER_NAME}" create_container
        fi
        ;;
    "shell")
        echo "Starting container and accessing shell..."
        
        # Check if container exists
        if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            echo "Container ${CONTAINER_NAME} found."
            
            # Check if container is running
            if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
                echo "Container ${CONTAINER_NAME} is already running. Accessing shell..."
                docker exec -it "${CONTAINER_NAME}" bash
            else
                echo "Container has stopped. Start container ${CONTAINER_NAME}."
            fi
        else
            echo "Container ${CONTAINER_NAME} doesn't exist."
            exit 1
        fi
        ;;
    "stop")
        echo "Stopping container: ${CONTAINER_NAME}"
        docker stop "${CONTAINER_NAME}"
        ;;
    "remove")
        echo "Removing container: ${CONTAINER_NAME}"
        docker rm "${CONTAINER_NAME}"
        ;;
esac
