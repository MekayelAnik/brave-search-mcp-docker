#!/bin/bash
set -e
/usr/local/bin/banner.sh

# Default values
readonly DEFAULT_PUID=1000
readonly DEFAULT_PGID=1000
readonly DEFAULT_PORT=8040
readonly DEFAULT_PROTOCOL="SHTTP"
readonly FIRST_RUN_FILE="/tmp/first_run_complete"

# Brave Search default configuration values
readonly DEFAULT_TRANSPORT="stdio"
readonly DEFAULT_LOG_LEVEL="info"

# Function to trim whitespace using parameter expansion
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# Validate positive integers
is_positive_int() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ]
}

# Validate directory path
validate_directory() {
    local dir="$1"
    [[ -n "$dir" ]] && [[ "$dir" =~ ^/ ]] && [[ ! "$dir" =~ \.\. ]] && [[ "${#dir}" -le 255 ]]
}

# First run handling
handle_first_run() {
    local uid_gid_changed=0

    # Handle PUID/PGID logic
    if [[ -z "$PUID" && -z "$PGID" ]]; then
        PUID="$DEFAULT_PUID"
        PGID="$DEFAULT_PGID"
        echo "PUID and PGID not set. Using defaults: PUID=$PUID, PGID=$PGID"
    elif [[ -n "$PUID" && -z "$PGID" ]]; then
        if is_positive_int "$PUID"; then
            PGID="$PUID"
        else
            echo "Invalid PUID: '$PUID'. Using default: $DEFAULT_PUID"
            PUID="$DEFAULT_PUID"
            PGID="$DEFAULT_PGID"
        fi
    elif [[ -z "$PUID" && -n "$PGID" ]]; then
        if is_positive_int "$PGID"; then
            PUID="$PGID"
        else
            echo "Invalid PGID: '$PGID'. Using default: $DEFAULT_PGID"
            PUID="$DEFAULT_PUID"
            PGID="$DEFAULT_PGID"
        fi
    else
        if ! is_positive_int "$PUID"; then
            echo "Invalid PUID: '$PUID'. Using default: $DEFAULT_PUID"
            PUID="$DEFAULT_PUID"
        fi
        
        if ! is_positive_int "$PGID"; then
            echo "Invalid PGID: '$PGID'. Using default: $DEFAULT_PGID"
            PGID="$DEFAULT_PGID"
        fi
    fi

    # Check existing UID/GID conflicts
    local current_user current_group
    current_user=$(id -un "$PUID" 2>/dev/null || true)
    current_group=$(getent group "$PGID" | cut -d: -f1 2>/dev/null || true)

    [[ -n "$current_user" && "$current_user" != "node" ]] &&
        echo "Warning: UID $PUID already in use by $current_user - may cause permission issues"

    [[ -n "$current_group" && "$current_group" != "node" ]] &&
        echo "Warning: GID $PGID already in use by $current_group - may cause permission issues"

    # Modify UID/GID if needed
    if [ "$(id -u node)" -ne "$PUID" ]; then
        if usermod -o -u "$PUID" node 2>/dev/null; then
            uid_gid_changed=1
        else
            echo "Error: Failed to change UID to $PUID. Using existing UID $(id -u node)"
            PUID=$(id -u node)
        fi
    fi

    if [ "$(id -g node)" -ne "$PGID" ]; then
        if groupmod -o -g "$PGID" node 2>/dev/null; then
            uid_gid_changed=1
        else
            echo "Error: Failed to change GID to $PGID. Using existing GID $(id -g node)"
            PGID=$(id -g node)
        fi
    fi

    [ "$uid_gid_changed" -eq 1 ] && echo "Updated UID/GID to PUID=$PUID, PGID=$PGID"
    touch "$FIRST_RUN_FILE"
}

# Validate and set PORT
validate_port() {
    # Ensure PORT has a value
    PORT=${PORT:-$DEFAULT_PORT}
    
    # Check if PORT is a positive integer
    if ! is_positive_int "$PORT"; then
        echo "Invalid PORT: '$PORT'. Using default: $DEFAULT_PORT"
        PORT="$DEFAULT_PORT"
    elif [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo "Invalid PORT: '$PORT'. Using default: $DEFAULT_PORT"
        PORT="$DEFAULT_PORT"
    fi
    
    # Check if port is privileged
    if [ "$PORT" -lt 1024 ] && [ "$(id -u)" -ne 0 ]; then
        echo "Warning: Port $PORT is privileged and might require root"
    fi
}

# Build MCP server command with environment variables
build_mcp_server_cmd() {
    # Start with the base command
    MCP_SERVER_CMD="npx -y @brave/brave-search-mcp-server"
    
    # Build environment variable arguments array
    BRAVE_ENV_ARGS=()
    
    # Add BRAVE_API_KEY (required)
    if [[ -n "${BRAVE_API_KEY:-}" ]]; then
        BRAVE_ENV_ARGS+=(env "BRAVE_API_KEY=$BRAVE_API_KEY")
    fi
    
    # Add transport configuration (optional)
    if [[ -n "${BRAVE_MCP_TRANSPORT:-}" ]]; then
        BRAVE_ENV_ARGS+=(env "BRAVE_MCP_TRANSPORT=$BRAVE_MCP_TRANSPORT")
        MCP_SERVER_CMD="$MCP_SERVER_CMD --transport $BRAVE_MCP_TRANSPORT"
    fi
    
    # Add log level configuration (optional)
    if [[ -n "${BRAVE_MCP_LOG_LEVEL:-}" ]]; then
        BRAVE_ENV_ARGS+=(env "BRAVE_MCP_LOG_LEVEL=$BRAVE_MCP_LOG_LEVEL")
        MCP_SERVER_CMD="$MCP_SERVER_CMD --logging-level $BRAVE_MCP_LOG_LEVEL"
    fi
    
    # Add enabled tools whitelist (optional)
    if [[ -n "${BRAVE_MCP_ENABLED_TOOLS:-}" ]]; then
        BRAVE_ENV_ARGS+=(env "BRAVE_MCP_ENABLED_TOOLS=$BRAVE_MCP_ENABLED_TOOLS")
        # Convert comma-separated list to multiple --enabled-tools arguments
        IFS=',' read -ra TOOLS <<< "$BRAVE_MCP_ENABLED_TOOLS"
        for tool in "${TOOLS[@]}"; do
            tool=$(trim "$tool")
            [[ -n "$tool" ]] && MCP_SERVER_CMD="$MCP_SERVER_CMD --enabled-tools $tool"
        done
    fi
    
    # Add disabled tools blacklist (optional)
    if [[ -n "${BRAVE_MCP_DISABLED_TOOLS:-}" ]]; then
        BRAVE_ENV_ARGS+=(env "BRAVE_MCP_DISABLED_TOOLS=$BRAVE_MCP_DISABLED_TOOLS")
        # Convert comma-separated list to multiple --disabled-tools arguments
        IFS=',' read -ra TOOLS <<< "$BRAVE_MCP_DISABLED_TOOLS"
        for tool in "${TOOLS[@]}"; do
            tool=$(trim "$tool")
            [[ -n "$tool" ]] && MCP_SERVER_CMD="$MCP_SERVER_CMD --disabled-tools $tool"
        done
    fi
    
    # Combine env args with the base command
    if [[ ${#BRAVE_ENV_ARGS[@]} -gt 0 ]]; then
        MCP_SERVER_CMD="${BRAVE_ENV_ARGS[@]} $MCP_SERVER_CMD"
    fi
}

# Validate CORS patterns
validate_cors() {
    CORS_ARGS=()
    ALLOW_ALL_CORS=false
    local cors_value

    if [[ -n "${CORS:-}" ]]; then
        IFS=',' read -ra CORS_VALUES <<< "$CORS"
        for cors_value in "${CORS_VALUES[@]}"; do
            cors_value=$(trim "$cors_value")
            [[ -z "$cors_value" ]] && continue

            if [[ "$cors_value" =~ ^(all|\*)$ ]]; then
                ALLOW_ALL_CORS=true
                CORS_ARGS=(--cors)
                echo "Caution! CORS allowing all origins - security risk in production!"
                break
            elif [[ "$cors_value" =~ ^/.*/$ ]] ||
                 [[ "$cors_value" =~ ^https?:// ]] ||
                 [[ "$cors_value" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:[0-9]+)?$ ]] ||
                 [[ "$cors_value" =~ ^https?://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:[0-9]+)?$ ]] ||
                 [[ "$cors_value" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(:[0-9]+)?$ ]]
            then
                CORS_ARGS+=(--cors "$cors_value")
            else
                echo "Warning: Invalid CORS pattern '$cors_value' - skipping"
            fi
        done
    fi
}

# Generate client configuration example
generate_client_config_example() {
    echo ""
    echo "=== BRAVE SEARCH MCP TOOL LIST ==="
    echo "To enable auto-approval in your MCP client, add this to your configuration:"
    echo ""
    echo "\"TOOL LIST\": ["
    echo "  \"brave_web_search\","
    echo "  \"brave_local_search\","
    echo "  \"brave_video_search\","
    echo "  \"brave_image_search\","
    echo "  \"brave_news_search\","
    echo "  \"brave_summarizer\""
    echo "]"
    echo ""
    echo "=== END TOOL LIST ==="
    echo ""
}

# Validate and set Brave Search environment variables
validate_brave_env() {
    # STRICT VALIDATION: BRAVE_API_KEY is REQUIRED
    if [[ -z "${BRAVE_API_KEY:-}" ]]; then
        echo "❌ ERROR: BRAVE_API_KEY environment variable is REQUIRED."
        echo ""
        echo "The Brave Search MCP server cannot start without an API key."
        echo ""
        echo "You can obtain an API key by:"
        echo "  1. Visiting: https://brave.com/search/api/"
        echo "  2. Creating an account if you don't have one"
        echo "  3. Choosing a plan (Free or Pro)"
        echo "  4. Generating a new API key from the dashboard"
        echo ""
        echo "Then set the environment variable:"
        echo "  docker run -e BRAVE_API_KEY=your-api-key ..."
        echo ""
        return 1
    fi

    # Validate API key format (basic check - should be non-empty and reasonable length)
    if [[ ${#BRAVE_API_KEY} -lt 10 ]]; then
        echo "⚠️  Warning: BRAVE_API_KEY seems too short (${#BRAVE_API_KEY} characters)"
    fi

    # Validate transport if set (optional)
    if [[ -n "${BRAVE_MCP_TRANSPORT:-}" ]]; then
        local transport_lower=$(echo "$BRAVE_MCP_TRANSPORT" | tr '[:upper:]' '[:lower:]')
        if [[ "$transport_lower" != "stdio" && "$transport_lower" != "http" ]]; then
            echo "⚠️  Warning: Invalid BRAVE_MCP_TRANSPORT: '$BRAVE_MCP_TRANSPORT'. Using default: $DEFAULT_TRANSPORT"
            export BRAVE_MCP_TRANSPORT="$DEFAULT_TRANSPORT"
        fi
    fi

    # Validate log level if set (optional)
    if [[ -n "${BRAVE_MCP_LOG_LEVEL:-}" ]]; then
        local valid_levels="debug info notice warning error critical alert emergency"
        local level_lower=$(echo "$BRAVE_MCP_LOG_LEVEL" | tr '[:upper:]' '[:lower:]')
        if ! echo "$valid_levels" | grep -wq "$level_lower"; then
            echo "⚠️  Warning: Invalid BRAVE_MCP_LOG_LEVEL: '$BRAVE_MCP_LOG_LEVEL'. Using default: $DEFAULT_LOG_LEVEL"
            export BRAVE_MCP_LOG_LEVEL="$DEFAULT_LOG_LEVEL"
        fi
    fi

    # Validate enabled/disabled tools format (optional)
    if [[ -n "${BRAVE_MCP_ENABLED_TOOLS:-}" && -n "${BRAVE_MCP_DISABLED_TOOLS:-}" ]]; then
        echo "⚠️  Warning: Both BRAVE_MCP_ENABLED_TOOLS and BRAVE_MCP_DISABLED_TOOLS are set."
        echo "   BRAVE_MCP_ENABLED_TOOLS takes precedence (whitelist mode)."
    fi

    return 0
}

# Display Brave Search configuration summary
display_config_summary() {
    echo ""
    echo "=== BRAVE SEARCH MCP SERVER CONFIGURATION ==="
    
    # Always show API configuration
    echo "🔑 API Key: ${BRAVE_API_KEY:0:8}...${BRAVE_API_KEY: -4} (length: ${#BRAVE_API_KEY})"
    
    # Show transport configuration
    local transport_display="${BRAVE_MCP_TRANSPORT:-$DEFAULT_TRANSPORT}"
    echo "🔄 Transport: $transport_display"
    
    # Show log level configuration
    local log_level_display="${BRAVE_MCP_LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
    echo "📊 Log Level: $log_level_display"
    
    # Show tools configuration if customized
    if [[ -n "${BRAVE_MCP_ENABLED_TOOLS:-}" ]]; then
        echo "✅ Enabled Tools (whitelist): $BRAVE_MCP_ENABLED_TOOLS"
    elif [[ -n "${BRAVE_MCP_DISABLED_TOOLS:-}" ]]; then
        echo "❌ Disabled Tools (blacklist): $BRAVE_MCP_DISABLED_TOOLS"
    else
        echo "🔧 Tools: All enabled (default)"
    fi
    
    # Always show server configuration
    echo "📡 Server:"
    echo "   - Port: $PORT"
    echo "   - Protocol: $PROTOCOL_DISPLAY"
    
    echo "=========================================="
    echo ""
}

# Main execution
main() {
    # Trim all input parameters
    [[ -n "${PUID:-}" ]] && PUID=$(trim "$PUID")
    [[ -n "${PGID:-}" ]] && PGID=$(trim "$PGID")
    [[ -n "${PORT:-}" ]] && PORT=$(trim "$PORT")
    [[ -n "${PROTOCOL:-}" ]] && PROTOCOL=$(trim "$PROTOCOL")
    [[ -n "${CORS:-}" ]] && CORS=$(trim "$CORS")
    
    # Trim Brave Search specific environment variables
    [[ -n "${BRAVE_API_KEY:-}" ]] && BRAVE_API_KEY=$(trim "$BRAVE_API_KEY")
    [[ -n "${BRAVE_MCP_TRANSPORT:-}" ]] && BRAVE_MCP_TRANSPORT=$(trim "$BRAVE_MCP_TRANSPORT")
    [[ -n "${BRAVE_MCP_LOG_LEVEL:-}" ]] && BRAVE_MCP_LOG_LEVEL=$(trim "$BRAVE_MCP_LOG_LEVEL")
    [[ -n "${BRAVE_MCP_ENABLED_TOOLS:-}" ]] && BRAVE_MCP_ENABLED_TOOLS=$(trim "$BRAVE_MCP_ENABLED_TOOLS")
    [[ -n "${BRAVE_MCP_DISABLED_TOOLS:-}" ]] && BRAVE_MCP_DISABLED_TOOLS=$(trim "$BRAVE_MCP_DISABLED_TOOLS")

    # First run handling
    if [[ ! -f "$FIRST_RUN_FILE" ]]; then
        handle_first_run
    fi

    # Validate configurations
    validate_port
    validate_cors
    
    # Validate Brave Search environment - this will exit if configuration is invalid
    if ! validate_brave_env; then
        echo "❌ Brave Search MCP Server cannot start due to configuration errors."
        exit 1
    fi

    # Build MCP server command with environment variables
    build_mcp_server_cmd

    # Generate client configuration example
    generate_client_config_example

    # Protocol selection
    local PROTOCOL_UPPER=${PROTOCOL:-$DEFAULT_PROTOCOL}
    PROTOCOL_UPPER=${PROTOCOL_UPPER^^}

    case "$PROTOCOL_UPPER" in
        "SHTTP"|"STREAMABLEHTTP")
            CMD_ARGS=(npx --yes supergateway --port "$PORT" --streamableHttpPath /mcp --outputTransport streamableHttp "${CORS_ARGS[@]}" --healthEndpoint /healthz --stdio "$MCP_SERVER_CMD")
            PROTOCOL_DISPLAY="SHTTP/streamableHttp"
            ;;
        "SSE")
            CMD_ARGS=(npx --yes supergateway --port "$PORT" --ssePath /sse --outputTransport sse "${CORS_ARGS[@]}" --healthEndpoint /healthz --stdio "$MCP_SERVER_CMD")
            PROTOCOL_DISPLAY="SSE/Server-Sent Events"
            ;;
        "WS"|"WEBSOCKET")
            CMD_ARGS=(npx --yes supergateway --port "$PORT" --messagePath /message --outputTransport ws "${CORS_ARGS[@]}" --healthEndpoint /healthz --stdio "$MCP_SERVER_CMD")
            PROTOCOL_DISPLAY="WS/WebSocket"
            ;;
        *)
            echo "Invalid PROTOCOL: '$PROTOCOL'. Using default: $DEFAULT_PROTOCOL"
            CMD_ARGS=(npx --yes supergateway --port "$PORT" --streamableHttpPath /mcp --outputTransport streamableHttp "${CORS_ARGS[@]}" --healthEndpoint /healthz --stdio "$MCP_SERVER_CMD")
            PROTOCOL_DISPLAY="SHTTP/streamableHttp"
            ;;
    esac

    # Display configuration summary
    display_config_summary

    # Debug mode handling
    case "${DEBUG_MODE:-}" in
        [1YyTt]*|[Oo][Nn]|[Yy][Ee][Ss]|[Ee][Nn][Aa][Bb][Ll][Ee]*)
            echo "DEBUG MODE: Installing nano and pausing container"
            apk add --no-cache nano 2>/dev/null || echo "Warning: Failed to install nano"
            echo "Container paused for debugging. Exec into container to investigate."
            exec tail -f /dev/null
            ;;
        *)
            # Normal execution
            echo "🚀 Launching Brave Search MCP Server with protocol: $PROTOCOL_DISPLAY on port: $PORT"
            
            # Check for npx availability
            if ! command -v npx &>/dev/null; then
                echo "❌ Error: npx not available. Cannot start server."
                exit 1
            fi

            # Final check - ensure API key is set
            if [[ -z "${BRAVE_API_KEY:-}" ]]; then
                echo "❌ CRITICAL: BRAVE_API_KEY is not set."
                echo "   The server cannot start without a Brave Search API key."
                exit 1
            fi

            # Display the actual command being executed for debugging
            if [[ "${DEBUG_MODE:-}" == "verbose" ]]; then
                echo "🔧 DEBUG - Final command: ${CMD_ARGS[*]}"
            fi

            if [ "$(id -u)" -eq 0 ]; then
                echo "👤 Running as user: node (PUID: $PUID, PGID: $PGID)"
                exec su-exec node "${CMD_ARGS[@]}"
            else
                if [ "$PORT" -lt 1024 ]; then
                    echo "❌ Error: Cannot bind to privileged port $PORT without root"
                    exit 1
                fi
                echo "👤 Running as current user"
                exec "${CMD_ARGS[@]}"
            fi
            ;;
    esac
}

# Run the script with error handling
if main "$@"; then
    exit 0
else
    echo "❌ Brave Search MCP Server failed to start"
    exit 1
fi
