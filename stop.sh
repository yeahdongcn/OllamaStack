#!/usr/bin/env bash

# Initialize variables:
OLLAMA_PID="$(pwd)/ollama.pid"

kill -9 $(cat $OLLAMA_PID)
echo "Stopped ollama"
docker rm -f litellm-proxy >/dev/null 2>&1
echo "Stopped litellm-proxy"
docker rm -f ollama-webui >/dev/null 2>&1
echo "Stopped ollama-webui"
