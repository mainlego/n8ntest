# Default Dockerfile for n8n service
FROM n8nio/n8n:latest

USER root

# Install dependencies
RUN apk add --no-cache \
    curl \
    postgresql-client

# Create directories
RUN mkdir -p /home/node/.n8n /home/node/workflows && \
    chown -R node:node /home/node/.n8n /home/node/workflows

# Copy workflow files
COPY --chown=node:node workflows/*.json /home/node/workflows/

# Copy database init script
COPY --chown=node:node database/init.sql /home/node/init.sql

# Copy initialization script
COPY --chown=node:node render/init-n8n.sh /home/node/init-n8n.sh
RUN chmod +x /home/node/init-n8n.sh

USER node
WORKDIR /home/node

EXPOSE 5678

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:5678/healthz || exit 1

CMD ["/bin/sh", "-c", "/home/node/init-n8n.sh && n8n start"]