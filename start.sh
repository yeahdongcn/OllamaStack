#!/usr/bin/env bash

# Initialize variables:
LAST_SPINNER_PID=""
OLLAMA_BINARY="$(pwd)/bin/ollama"
OLLAMA_PID="$(pwd)/ollama.pid"

# Kill background processes on exit
trap exit_trap EXIT
function exit_trap {
    # Kill the last spinner process
    kill_spinner
}

# Draw a spinner so the user knows something is happening
function spinner {
    local delay=0.1
    local spinstr='/-\|'
    printf "..."
    while [ true ]; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
}

function kill_spinner {
    if [ ! -z "$LAST_SPINNER_PID" ]; then
        kill >/dev/null 2>&1 $LAST_SPINNER_PID
        wait $LAST_SPINNER_PID 2>/dev/null
        printf "\b\b\bdone\n"
        LAST_SPINNER_PID=""
    fi
}

# Echo text to the log file, summary log file and stdout
# echo_summary "something to say"
function echo_summary {
    kill_spinner
    echo -n -e $@
    spinner &
    LAST_SPINNER_PID=$!
}

# Create dir from OLLAMA_BINARY
mkdir -p $(dirname "$OLLAMA_BINARY")

# Download ollama
echo_summary "Downloading ollama to $(dirname "$OLLAMA_BINARY")"
if [ ! -f "$OLLAMA_BINARY" ]; then
    curl -sL https://api.github.com/repos/jmorganca/ollama/releases/latest |
        grep "browser_download_url.*ollama-darwin" |
        cut -d : -f 2,3 |
        tr -d \" |
        wget -O "$OLLAMA_BINARY" -qi -
fi
kill_spinner

chmod +x "$OLLAMA_BINARY"
"$OLLAMA_BINARY" serve >/dev/null 2>&1 &
echo $! >"$OLLAMA_PID"
echo "ollama started"

docker rm -f litellm-proxy >/dev/null 2>&1
docker run --mount type=bind,source="$(pwd)"/litellm-config.yaml,target=/config.yaml,readonly \
    -p 8000:8000 --add-host=host.docker.internal:host-gateway \
    -d --name litellm-proxy ghcr.io/yeahdongcn/litellm-proxy:main --drop_params --config /config.yaml
echo "litellm started"

read -rp "Do you want to use predefined mods config? y/n [n]: " USE_MODS
if [[ $USE_MODS =~ ^[Yy]$ ]]; then
    mv ~/Library/Application\ Support/mods/mods.yml ~/Library/Application\ Support/mods/mods.yml.backup
    cp mods.yml ~/Library/Application\ Support/mods/mods.yml
fi

read -rp "Do you want to start web UI? y/n [n]: " USE_WEBUI
if [[ $USE_WEBUI =~ ^[Yy]$ ]]; then
    mkdir -p ollama-webui
    docker rm -f ollama-webui >/dev/null 2>&1
    docker run --pull always -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v ollama-webui:/app/backend/data \
        --name ollama-webui --restart always ghcr.io/ollama-webui/ollama-webui:main
    sleep 5
    open http://localhost:3000
fi
