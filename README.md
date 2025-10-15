# Brave Search MCP Server
### Multi-Architecture Docker Image for Distributed Deployment

<div align="left">

<img alt="brave-search-mcp" src="https://img.shields.io/badge/Brave%20Search-MCP-FB542B?style=for-the-badge&logo=brave&logoColor=white" width="400">

[![Docker Pulls](https://img.shields.io/docker/pulls/mekayelanik/brave-search-mcp.svg?style=flat-square)](https://hub.docker.com/r/mekayelanik/brave-search-mcp)
[![Docker Stars](https://img.shields.io/docker/stars/mekayelanik/brave-search-mcp.svg?style=flat-square)](https://hub.docker.com/r/mekayelanik/brave-search-mcp)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)

**[NPM Package](https://www.npmjs.com/package/@brave/brave-search-mcp-server)** • **[GitHub Repository](https://github.com/mekayelanik/brave-search-mcp-docker)** • **[Docker Hub](https://hub.docker.com/r/mekayelanik/brave-search-mcp)**

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [MCP Client Setup](#mcp-client-setup)
- [Available Tools](#available-tools)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)
- [Resources & Support](#resources--support)

---

## Overview

Brave Search MCP Server provides AI assistants with comprehensive search capabilities through the privacy-focused Brave Search API. Access web search, local search, news, images, videos, and AI-powered summarization—all through a secure, containerized MCP server. Seamlessly integrates with VS Code, Cursor, Windsurf, Claude Desktop, and any MCP-compatible client.

### Key Features

✨ **Comprehensive Search** - Web, local, news, images, videos, and AI summarization  
🔒 **Privacy-First** - Powered by Brave's privacy-focused search infrastructure  
🛡️ **Secure & Configurable** - API key authentication with fine-grained tool control  
⚡ **High Performance** - Built on Node.js Alpine for minimal footprint  
🌐 **CORS Ready** - Built-in CORS support for browser-based clients  
🚀 **Multiple Protocols** - HTTP, SSE, and WebSocket transport support  
🎯 **Zero Configuration** - Works out of the box with API key  
🔧 **Highly Customizable** - Fine-tune tools, logging, and transport via environment variables  
📊 **Health Monitoring** - Built-in health check endpoint

### Supported Architectures

| Architecture | Status | Notes |
|:-------------|:------:|:------|
| **x86-64** | ✅ Stable | Intel/AMD processors |
| **ARM64** | ✅ Stable | Raspberry Pi, Apple Silicon |

### Available Tags

| Tag | Stability | Use Case |
|:----|:---------:|:---------|
| `stable` | ⭐⭐⭐ | **Production (recommended)** |
| `latest` | ⭐⭐⭐ | Latest stable features |
| `1.x.x` | ⭐⭐⭐ | Version pinning |
| `beta` | ⚠️ | Testing only |

---

## Quick Start

### Prerequisites

- Docker Engine 23.0+
- **Brave Search API Key** ([Get one here](https://brave.com/search/api/))
- Network access for search operations

### Obtaining a Brave Search API Key

1. Visit [Brave Search API](https://brave.com/search/api/)
2. Sign up for a free or pro account
3. Generate your API key from the dashboard
4. Copy the key for use in your Docker deployment

### Docker Compose (Recommended)

```yaml
services:
  brave-search-mcp:
    image: mekayelanik/brave-search-mcp:stable
    container_name: brave-search-mcp
    restart: unless-stopped
    ports:
      - "8040:8040"
    environment:
      # Required
      - BRAVE_API_KEY=your-brave-api-key-here
      
      # Core settings
      - PORT=8040
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Dhaka
      - PROTOCOL=SHTTP
      - CORS=*
      
      # Brave Search settings
      - BRAVE_MCP_TRANSPORT=stdio
      - BRAVE_MCP_LOG_LEVEL=info
```

**Deploy:**

```bash
docker compose up -d
docker compose logs -f brave-search-mcp
```

### Docker CLI

```bash
docker run -d \
  --name=brave-search-mcp \
  --restart=unless-stopped \
  -p 8040:8040 \
  -e BRAVE_API_KEY=your-brave-api-key-here \
  -e PORT=8040 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e PROTOCOL=SHTTP \
  -e CORS=* \
  mekayelanik/brave-search-mcp:stable
```

### Access Endpoints

| Protocol | Endpoint | Use Case |
|:---------|:---------|:---------|
| **HTTP** | `http://host-ip:8040/mcp` | **Recommended** |
| **SSE** | `http://host-ip:8040/sse` | Real-time streaming |
| **WebSocket** | `ws://host-ip:8040/message` | Bidirectional |
| **Health** | `http://host-ip:8040/healthz` | Monitoring |

> ⏱️ Server ready in 5-10 seconds after container start

---

## Configuration

### Environment Variables

#### Core Settings

| Variable | Default | Required | Description |
|:---------|:-------:|:--------:|:------------|
| `BRAVE_API_KEY` | _(none)_ | **✅ YES** | Your Brave Search API key |
| `PORT` | `8040` | No | Server port (1-65535) |
| `PUID` | `1000` | No | User ID for file permissions |
| `PGID` | `1000` | No | Group ID for file permissions |
| `TZ` | `Asia/Dhaka` | No | Container timezone |
| `PROTOCOL` | `SHTTP` | No | Transport protocol |
| `CORS` | _(none)_ | No | Cross-Origin configuration |

#### Brave Search Settings

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `BRAVE_MCP_TRANSPORT` | `stdio` | Transport mode (`stdio`, `http`) |
| `BRAVE_MCP_LOG_LEVEL` | `info` | Logging level (`debug`, `info`, `warning`, `error`) |
| `BRAVE_MCP_ENABLED_TOOLS` | _(all)_ | Whitelist of enabled tools (comma-separated) |
| `BRAVE_MCP_DISABLED_TOOLS` | _(none)_ | Blacklist of disabled tools (comma-separated) |

#### Advanced Settings

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `DEBUG_MODE` | `false` | Enable debug mode (`true`, `false`, `verbose`) |

### Protocol Configuration

```yaml
# HTTP/Streamable HTTP (Recommended)
environment:
  - PROTOCOL=SHTTP

# Server-Sent Events
environment:
  - PROTOCOL=SSE

# WebSocket
environment:
  - PROTOCOL=WS
```

### CORS Configuration

```yaml
# Development - Allow all origins
environment:
  - CORS=*

# Production - Specific domains
environment:
  - CORS=https://example.com,https://app.example.com

# Mixed domains and IPs
environment:
  - CORS=https://example.com,192.168.1.100:3000,/.*\.myapp\.com$/

# Regex patterns
environment:
  - CORS=/^https:\/\/.*\.example\.com$/
```

> ⚠️ **Security:** Never use `CORS=*` in production environments

### Tool Configuration

#### Enable Specific Tools Only (Whitelist)

```yaml
environment:
  - BRAVE_MCP_ENABLED_TOOLS=brave_web_search,brave_local_search,brave_news_search
```

#### Disable Specific Tools (Blacklist)

```yaml
environment:
  - BRAVE_MCP_DISABLED_TOOLS=brave_image_search,brave_video_search
```

> 📝 **Note:** If both enabled and disabled tools are set, the whitelist takes precedence.

### Log Level Examples

```yaml
# Debug mode - verbose logging
environment:
  - BRAVE_MCP_LOG_LEVEL=debug

# Production - minimal logging
environment:
  - BRAVE_MCP_LOG_LEVEL=error

# Default - balanced logging
environment:
  - BRAVE_MCP_LOG_LEVEL=info
```

---

## MCP Client Setup

### Transport Compatibility

| Client | HTTP | SSE | WebSocket | Recommended |
|:-------|:----:|:---:|:---------:|:------------|
| **VS Code (Cline/Roo-Cline)** | ✅ | ✅ | ❌ | HTTP |
| **Claude Desktop** | ✅ | ✅ | ⚠️* | HTTP |
| **Cursor** | ✅ | ✅ | ⚠️* | HTTP |
| **Windsurf** | ✅ | ✅ | ⚠️* | HTTP |

> ⚠️ *WebSocket support is experimental

### VS Code (Cline/Roo-Cline)

Add to `.vscode/settings.json`:

```json
{
  "mcp.servers": {
    "brave-search": {
      "url": "http://host-ip:8040/mcp",
      "transport": "http",
      "autoApprove": [
        "brave_web_search",
        "brave_local_search",
        "brave_video_search",
        "brave_image_search",
        "brave_news_search",
        "brave_summarizer"
      ]
    }
  }
}
```

### Claude Desktop

**Config Locations:**
- **Linux:** `~/.config/Claude/claude_desktop_config.json`
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "brave-search": {
      "transport": "http",
      "url": "http://localhost:8040/mcp"
    }
  }
}
```

### Cursor

Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "brave-search": {
      "transport": "http",
      "url": "http://host-ip:8040/mcp"
    }
  }
}
```

### Windsurf (Codeium)

Add to `.codeium/mcp_settings.json`:

```json
{
  "mcpServers": {
    "brave-search": {
      "transport": "http",
      "url": "http://host-ip:8040/mcp"
    }
  }
}
```

### Claude Code

Add to `~/.config/claude-code/mcp_config.json`:

```json
{
  "mcpServers": {
    "brave-search": {
      "transport": "http",
      "url": "http://localhost:8040/mcp"
    }
  }
}
```

Or configure via CLI:

```bash
claude-code config mcp add brave-search \
  --transport http \
  --url http://localhost:8040/mcp
```

### GitHub Copilot CLI

Add to `~/.github-copilot/mcp.json`:

```json
{
  "mcpServers": {
    "brave-search": {
      "transport": "http",
      "url": "http://host-ip:8040/mcp"
    }
  }
}
```

Or use environment variable:

```bash
export GITHUB_COPILOT_MCP_SERVERS='{"brave-search":{"transport":"http","url":"http://localhost:8040/mcp"}}'
```

---

## Available Tools

### 🔍 brave_web_search
Perform comprehensive web searches using Brave Search.

**Parameters:**
- `query` (string, required): Search query
- `count` (number, optional): Number of results (default: 10, max: 20)
- `offset` (number, optional): Pagination offset
- `country` (string, optional): Country code for localized results
- `search_lang` (string, optional): Search language code
- `freshness` (string, optional): Time filter (`pd` - past day, `pw` - past week, `pm` - past month, `py` - past year)
- `text_decorations` (boolean, optional): Include text decorations in results
- `spellcheck` (boolean, optional): Enable spell checking

**Use Cases:**
- General web search and research
- Finding current information and news
- Gathering diverse perspectives
- Academic and technical research

**Example Prompts:**
- "Search for recent articles about artificial intelligence"
- "Find information about climate change from the past week"
- "Search for Python tutorials in English"

---

### 📍 brave_local_search
Search for local businesses and places.

**Parameters:**
- `query` (string, required): Search query
- `count` (number, optional): Number of results (default: 5, max: 20)

**Use Cases:**
- Finding nearby businesses and services
- Restaurant and venue discovery
- Local shopping and services
- Place-based recommendations

**Example Prompts:**
- "Find coffee shops near me"
- "Search for Italian restaurants"
- "Find local hardware stores"

---

### 🎥 brave_video_search
Search for videos across the web.

**Parameters:**
- `query` (string, required): Search query
- `count` (number, optional): Number of results (default: 10, max: 20)
- `offset` (number, optional): Pagination offset
- `country` (string, optional): Country code for localized results
- `search_lang` (string, optional): Search language code

**Use Cases:**
- Finding educational videos and tutorials
- Discovering entertainment content
- Research and documentation
- Visual learning resources

**Example Prompts:**
- "Find tutorial videos about Docker"
- "Search for cooking videos"
- "Find educational content on quantum physics"

---

### 🖼️ brave_image_search
Search for images across the web.

**Parameters:**
- `query` (string, required): Search query
- `count` (number, optional): Number of results (default: 10, max: 20)
- `offset` (number, optional): Pagination offset
- `country` (string, optional): Country code for localized results
- `search_lang` (string, optional): Search language code
- `safesearch` (string, optional): Safe search level (`strict`, `moderate`, `off`)

**Use Cases:**
- Visual research and inspiration
- Finding reference images
- Design and creative work
- Educational illustrations

**Example Prompts:**
- "Search for landscape photography"
- "Find diagrams explaining neural networks"
- "Search for logo design inspiration"

---

### 📰 brave_news_search
Search for news articles and current events.

**Parameters:**
- `query` (string, required): Search query
- `count` (number, optional): Number of results (default: 10, max: 20)
- `offset` (number, optional): Pagination offset
- `country` (string, optional): Country code for localized results
- `search_lang` (string, optional): Search language code
- `freshness` (string, optional): Time filter

**Use Cases:**
- Tracking current events
- News research and analysis
- Staying informed on specific topics
- Gathering multiple perspectives

**Example Prompts:**
- "Find recent news about space exploration"
- "Search for articles about renewable energy"
- "Get latest news on technology trends"

---

### 📝 brave_summarizer
Get AI-powered summaries of web content.

**Parameters:**
- `query` (string, required): Topic or URL to summarize
- `entity_info` (boolean, optional): Include entity information
- `summary_style` (string, optional): Summary style preference

**Use Cases:**
- Quick content digestion
- Research synthesis
- Article summarization
- Information condensation

**Example Prompts:**
- "Summarize the latest developments in AI"
- "Give me a summary of this article"
- "Summarize current trends in climate science"

---

## Advanced Usage

### Production Configuration

```yaml
services:
  brave-search-mcp:
    image: mekayelanik/brave-search-mcp:stable
    container_name: brave-search-mcp
    restart: unless-stopped
    ports:
      - "8040:8040"
    environment:
      # Required
      - BRAVE_API_KEY=${BRAVE_API_KEY}
      
      # Core settings
      - PORT=8040
      - PUID=1000
      - PGID=1000
      - TZ=UTC
      - PROTOCOL=SHTTP
      
      # Security
      - CORS=https://app.example.com,https://admin.example.com
      
      # Brave Search configuration
      - BRAVE_MCP_TRANSPORT=stdio
      - BRAVE_MCP_LOG_LEVEL=warning
      - BRAVE_MCP_ENABLED_TOOLS=brave_web_search,brave_news_search,brave_summarizer
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    
    # Health check
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "8040"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

### Reverse Proxy Setup

#### Nginx

```nginx
server {
    listen 80;
    server_name brave-search.example.com;
    
    location / {
        proxy_pass http://localhost:8040;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }
}
```

#### Traefik

```yaml
services:
  brave-search-mcp:
    image: mekayelanik/brave-search-mcp:stable
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.brave-search.rule=Host(`brave-search.example.com`)"
      - "traefik.http.routers.brave-search.entrypoints=websecure"
      - "traefik.http.routers.brave-search.tls.certresolver=myresolver"
      - "traefik.http.services.brave-search.loadbalancer.server.port=8040"
```

### Docker Network Setup

```yaml
services:
  brave-search-mcp:
    image: mekayelanik/brave-search-mcp:stable
    container_name: brave-search-mcp
    networks:
      - mcp-network
    environment:
      - BRAVE_API_KEY=${BRAVE_API_KEY}
      - PORT=8040
      - PROTOCOL=SHTTP
    
  other-service:
    image: other-service:latest
    networks:
      - mcp-network
    environment:
      - BRAVE_SEARCH_URL=http://brave-search-mcp:8040/mcp

networks:
  mcp-network:
    driver: bridge
```

### Using Environment Files

Create `.env` file:

```env
BRAVE_API_KEY=your-api-key-here
PORT=8040
PUID=1000
PGID=1000
TZ=UTC
PROTOCOL=SHTTP
CORS=https://example.com
BRAVE_MCP_LOG_LEVEL=info
```

Reference in Docker Compose:

```yaml
services:
  brave-search-mcp:
    image: mekayelanik/brave-search-mcp:stable
    env_file:
      - .env
```

---

## Troubleshooting

### Pre-Flight Checklist

- ✅ Docker 23.0+
- ✅ Valid Brave Search API key
- ✅ Port 8040 available
- ✅ Network connectivity
- ✅ Latest stable image

### Common Issues

**Container Won't Start - Missing API Key**
```bash
# Check logs for API key error
docker logs brave-search-mcp

# Error: "BRAVE_API_KEY environment variable is REQUIRED"
# Solution: Set BRAVE_API_KEY in your docker-compose.yml or docker run command
docker run -e BRAVE_API_KEY=your-key-here ...
```

**Container Won't Start - Other Issues**
```bash
# Check logs
docker logs brave-search-mcp

# Pull latest image
docker pull mekayelanik/brave-search-mcp:stable

# Restart container
docker restart brave-search-mcp
```

**Connection Refused**
```bash
# Verify container is running
docker ps | grep brave-search-mcp

# Check port binding
docker port brave-search-mcp

# Test health endpoint
curl http://localhost:8040/healthz
```

**API Key Issues**
```bash
# Verify API key is set correctly
docker exec brave-search-mcp env | grep BRAVE_API_KEY

# Test API key validity (check Brave API dashboard)
# Ensure key has proper permissions and quota
```

**CORS Errors**
```yaml
# Development - allow all
environment:
  - CORS=*

# Production - specific origins
environment:
  - CORS=https://yourdomain.com,https://app.yourdomain.com
```

**Tool Access Issues**
```yaml
# Enable specific tools only
environment:
  - BRAVE_MCP_ENABLED_TOOLS=brave_web_search,brave_news_search

# Or disable specific tools
environment:
  - BRAVE_MCP_DISABLED_TOOLS=brave_image_search
```

**Debug Mode**
```yaml
# Enable verbose debugging
environment:
  - DEBUG_MODE=verbose
  - BRAVE_MCP_LOG_LEVEL=debug

# Then check logs
docker logs -f brave-search-mcp
```

### Health Check Testing

```bash
# Basic health check
curl http://localhost:8040/healthz

# Test MCP endpoint
curl http://localhost:8040/mcp

# Test with tool listing
curl -X POST http://localhost:8040/mcp \
  -H "Content-Type: application/json" \
  -d '{"method":"tools/list"}'
```

---

## Resources & Support

### Documentation
- 📦 [NPM Package](https://www.npmjs.com/package/@brave/brave-search-mcp-server)
- 🔧 [GitHub Repository](https://github.com/mekayelanik/brave-search-mcp-docker)
- 🐳 [Docker Hub](https://hub.docker.com/r/mekayelanik/brave-search-mcp)
- 🔑 [Brave Search API](https://brave.com/search/api/)

### MCP Resources
- 📘 [MCP Protocol Specification](https://modelcontextprotocol.io)
- 🎓 [MCP Documentation](https://modelcontextprotocol.io/docs)
- 💬 [MCP Community](https://discord.gg/mcp)

### Getting Help

**Docker Image Issues:**
- [GitHub Issues](https://github.com/mekayelanik/brave-search-mcp-docker/issues)
- [Discussions](https://github.com/mekayelanik/brave-search-mcp-docker/discussions)

**General Questions:**
- Check logs: `docker logs brave-search-mcp`
- Test health: `curl http://localhost:8040/healthz`
- Review configuration in this README

### Updating

```bash
# Docker Compose
docker compose pull
docker compose up -d

# Docker CLI
docker pull mekayelanik/brave-search-mcp:stable
docker stop brave-search-mcp
docker rm brave-search-mcp
# Re-run your docker run command
```

### Version Pinning

```yaml
# Use specific version
services:
  brave-search-mcp:
    image: mekayelanik/brave-search-mcp:1.0.0

# Or use stable tag (recommended)
services:
  brave-search-mcp:
    image: mekayelanik/brave-search-mcp:stable
```

---

## Performance Tips

### Optimize for Speed

```yaml
environment:
  - BRAVE_MCP_LOG_LEVEL=error          # Minimal logging
  - BRAVE_MCP_ENABLED_TOOLS=brave_web_search,brave_news_search  # Only needed tools
```

### Resource Limits

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 256M
```

---

## Security Best Practices

1. **Never expose your API key** in public repositories or logs
2. **Never use `CORS=*` in production**
3. **Use environment files** for sensitive configuration
4. **Enable only required tools** using `BRAVE_MCP_ENABLED_TOOLS`
5. **Use reverse proxy** with rate limiting for public deployments
6. **Monitor API usage** through Brave API dashboard
7. **Keep Docker image updated**
8. **Use specific version tags** for production
9. **Run as non-root** (default PUID/PGID)
10. **Implement proper logging** levels based on environment

---

## API Rate Limits

Brave Search API has different rate limits based on your plan:

- **Free Plan:** Limited requests per month
- **Pro Plan:** Higher limits with advanced features

Monitor your usage in the [Brave API Dashboard](https://brave.com/search/api/)

---

## License

MIT License - See [LICENSE](LICENSE) for details.

**Disclaimer:** Unofficial Docker image for [@brave/brave-search-mcp-server](https://www.npmjs.com/package/@brave/brave-search-mcp-server). Users are responsible for compliance with Brave Search API terms of service and applicable laws.

---

<div align="center">

[Report Docker Image Bug](https://github.com/mekayelanik/brave-search-mcp-docker/issues) • [Request Feature](https://github.com/mekayelanik/brave-search-mcp-docker/issues) • [Contribute](https://github.com/mekayelanik/brave-search-mcp-docker/pulls)

</div>