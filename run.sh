#!/bin/bash
# ============================================
# Zero Human Corp — Run Container
# ============================================
# Builds and runs the single ZHC container with
# all volume mounts for state persistence and CLI auth.

set -e

IMAGE_NAME="zhc"
CONTAINER_NAME="zhc"
PORT="${DASHBOARD_PORT:-4200}"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"

# Stop existing container if running
if docker ps -q -f name="$CONTAINER_NAME" 2>/dev/null | grep -q .; then
    echo "Stopping existing $CONTAINER_NAME container..."
    docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME"
fi

# Remove stopped container with same name
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Build if image doesn't exist or --build flag passed
if [ "$1" = "--build" ] || ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "Building $IMAGE_NAME image..."
    docker build -t "$IMAGE_NAME" .
fi

echo "Starting $CONTAINER_NAME..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$PORT":4200 \
    -p "$GATEWAY_PORT":18789 \
    -v "$(pwd)/memory:/zhc/memory" \
    -v "$(pwd)/economy:/zhc/economy" \
    -v "$(pwd)/symphony:/zhc/symphony" \
    -v "$HOME/.claude:/root/.claude:ro" \
    -v "$HOME/.codex:/root/.codex:ro" \
    -v "$HOME/.openclaw:/root/.openclaw" \
    --env-file .env \
    --restart unless-stopped \
    "$IMAGE_NAME"

echo ""
echo "Zero Human Corp is running."
echo "  Dashboard:        http://localhost:$PORT"
echo "  Task Board:       http://localhost:$PORT/tasks"
echo "  OpenClaw Gateway: http://localhost:$GATEWAY_PORT"
echo "  Logs:             docker logs -f $CONTAINER_NAME"
echo "  Stop:             docker stop $CONTAINER_NAME"
