#!/usr/bin/env bash

# Initialize variables:
LAST_SPINNER_PID=""
OLLAMA_BINARY="$(pwd)/bin/ollama"
COLLECTOR_BINARY="$(pwd)/bin/collector"
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
    docker run --pull always -d -p 3001:8080 --add-host=host.docker.internal:host-gateway -v ollama-webui:/app/backend/data \
        --name ollama-webui --restart always ghcr.io/ollama-webui/ollama-webui:main
    sleep 5
    open http://localhost:3001
fi

read -rp "Do you want to start performance statistics monitor? y/n [n]: " USE_PSM
if [[ $USE_PSM =~ ^[Yy]$ ]]; then
    cd performance-statistics && swift build && cp $(swift build --show-bin-path)/collector ../bin/collector && cd ..
    "$COLLECTOR_BINARY" >/dev/null 2>&1 &
    docker rm -f prometheus >/dev/null 2>&1
    docker run -d -p 9090:9090 --name prometheus -v $PWD/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
    docker rm -f grafana >/dev/null 2>&1
    docker run -d -p 3000:3000 --name grafana \
        -v "$(pwd)/grafana/datasources:/etc/grafana/provisioning/datasources" \
        -v "$(pwd)/grafana/dashboards:/var/lib/grafana/dashboards" \
        -e "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/dashboard.json" \
        -e "GF_SECURITY_ADMIN_USER=admin" \
        -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
        -e "GF_AUTH_ANONYMOUS_ENABLED=true" \
        -e "GF_AUTH_ANONYMOUS_ORG_ROLE=Admin" \
        grafana/grafana-enterprise
    sleep 5
    open http://localhost:3000
fi
