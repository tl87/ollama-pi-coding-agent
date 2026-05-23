#!/usr/bin/env bash
CONTAINER_NAME="ollama-pi"
IMAGE_NAME="ollama-pi-agent"
MODE_LABEL="ollama-pi.mode"

MODELS=(
  "gemma4:e2b"
  "qwen3:14b"
  "qwen3.5:4b"
  "qwen3.5:2b"
  "qwen3.5:0.8b"
  "devstral-small-2:24b"
  "gpt-oss:20b"
)

COMMON_ARGS=(
  -d
  -p 11434:11434
  -v "$(pwd):/workspace:Z"
  --user pi
  --name "$CONTAINER_NAME"
  --pids-limit=4096
  --memory=20g
  --cpus=10
  --restart=on-failure:5
)

get_container_mode() {
  podman inspect -f "{{ index .Config.Labels \"$MODE_LABEL\" }}" \
    "$CONTAINER_NAME" 2>/dev/null
}

wait_and_attach() {
  sleep 1
  if ! podman exec "$CONTAINER_NAME" true 2>/dev/null; then
    echo "Container failed to start. Logs:"
    podman logs "$CONTAINER_NAME"
    exit 1
  fi
  podman exec -it "$CONTAINER_NAME" bash
}

start_container() {
  local mode="$1"   # "hardened" or "relaxed"

  if podman container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    local existing_mode
    existing_mode="$(get_container_mode)"

    if [ -n "$existing_mode" ] && [ "$existing_mode" != "$mode" ]; then
      echo "ERROR: Container '$CONTAINER_NAME' already exists in '$existing_mode' mode,"
      echo "       but you asked to start it in '$mode' mode."
      echo "       Run '$0 clean' first if you want to recreate it in '$mode' mode."
      exit 1
    fi

    echo "Container exists ($mode mode) — starting..."
    podman start "$CONTAINER_NAME" >/dev/null
    wait_and_attach
    return
  fi

  echo "Creating container in '$mode' mode..."

  if [ "$mode" = "hardened" ]; then
    podman run "${COMMON_ARGS[@]}" \
      --label "$MODE_LABEL=hardened" \
      --cap-drop=ALL \
      --security-opt=no-new-privileges \
      "$IMAGE_NAME"
  else
    podman run "${COMMON_ARGS[@]}" \
      --label "$MODE_LABEL=relaxed" \
      --cap-drop=ALL \
      --cap-add=CHOWN \
      --cap-add=DAC_OVERRIDE \
      --cap-add=FOWNER \
      --cap-add=SETUID \
      --cap-add=SETGID \
      "$IMAGE_NAME"
  fi

  wait_and_attach
}

case "$1" in
  build)
    echo "Building image..."
    podman buildx build . --tag "$IMAGE_NAME" -f ./src/Dockerfile
    ;;

  start-hardened)
    start_container "hardened"
    ;;

  start-relaxed)
    start_container "relaxed"
    ;;

  stop)
    echo "Stopping container..."
    podman stop "$CONTAINER_NAME"
    ;;

  attach)
    echo "Attaching to container shell..."
    if ! podman exec "$CONTAINER_NAME" true 2>/dev/null; then
      echo "Container is not running. Start it first."
      exit 1
    fi
    podman exec -it "$CONTAINER_NAME" bash
    ;;

  clean)
    echo "Removing container..."
    podman rm -f "$CONTAINER_NAME"
    ;;

  models)
    echo "Installing models..."
    for model in "${MODELS[@]}"; do
      echo "Pulling $model..."
      podman exec -it "$CONTAINER_NAME" ollama pull "$model"
    done
    ;;

  status)
    if podman container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
      mode="$(get_container_mode)"
      state="$(podman inspect -f '{{.State.Status}}' "$CONTAINER_NAME")"
      echo "Container: $CONTAINER_NAME"
      echo "State:     $state"
      echo "Mode:      ${mode:-unknown}"
    else
      echo "Container '$CONTAINER_NAME' does not exist."
    fi
    ;;

  *)
    echo "Usage: $0 {build|start-hardened|start-relaxed|stop|attach|models|status|clean}"
    exit 1
    ;;
esac
