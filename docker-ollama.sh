#!/usr/bin/env bash
CONTAINER_NAME="ollama-pi"
IMAGE_NAME="ollama-pi-agent"

MODELS=(
  "gemma4:e2b"
  "qwen3:14b"
  "qwen3.5:4b"
  "qwen3.5:2b"
  "qwen3.5:0.8b"
  "devstral-small-2:24b"
  "gpt-oss:20b"
)

case "$1" in
  build)
    echo "Building image..."
    docker buildx build --tag ollama-pi-agent .
    ;;
  start)
    echo "Starting container..."
    if docker container exists "$CONTAINER_NAME"; then
      echo "Container exists — starting..."
      docker start "$CONTAINER_NAME"
      if ! docker exec "$CONTAINER_NAME" true 2>/dev/null; then
        echo "Container failed to start. Logs:"
        docker logs "$CONTAINER_NAME"
        exit 1
      fi
      docker exec -it "$CONTAINER_NAME" bash
    else
      echo "Container does not exist — creating..."
      docker run -d \
        -p 11434:11434 \
        -v "$(pwd)":/workspace:Z \
        --user pi \
        --name "$CONTAINER_NAME" \
        "$IMAGE_NAME"
      sleep 1
      if ! docker exec "$CONTAINER_NAME" true 2>/dev/null; then
        echo "Container failed to start. Logs:"
        docker logs "$CONTAINER_NAME"
        exit 1
      fi
      docker exec -it "$CONTAINER_NAME" bash
    fi
    ;;
  stop)
    echo "Stopping container..."
    docker stop "$CONTAINER_NAME"
    ;;
  attach)
    echo "Attaching to container shell..."
    if ! docker exec "$CONTAINER_NAME" true 2>/dev/null; then
      echo "Container is not running. Start it first."
      exit 1
    fi
    docker exec -it "$CONTAINER_NAME" bash
    ;;
  clean)
    echo "Removing container..."
    docker rm -f "$CONTAINER_NAME"
    ;;
  models)
    echo "Installing models..."
    for model in "${MODELS[@]}"; do
      echo "Pulling $model..."
      docker exec -it "$CONTAINER_NAME" ollama pull "$model"
    done
    ;;
  *)
    echo "Usage: $0 {build|start|stop|attach|models|clean}"
    exit 1
    ;;
esac
