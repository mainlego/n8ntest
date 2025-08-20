# Default Dockerfile for n8n service
FROM n8nio/n8n:latest

# Health check for Render
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1

EXPOSE 5678

# Use the default entrypoint and command from base image
# The official n8n image already has everything configured