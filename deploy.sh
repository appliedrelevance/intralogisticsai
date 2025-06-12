#!/bin/bash

# Clean Frappe Docker Deployment Script
# Based on the working pwd.yml pattern

set -e

log() { echo "[$(date +'%H:%M:%S')] $1"; }
error() { echo "[ERROR] $1"; exit 1; }

DEPLOY_TYPE=${1:-"basic"}
log "Starting deployment: $DEPLOY_TYPE"

# Check directory
[ ! -f "compose.yaml" ] && error "Must run from frappe_docker directory"

# Complete cleanup
log "Complete cleanup"
docker compose down --volumes --remove-orphans 2>/dev/null || true
docker system prune -af --volumes >/dev/null 2>&1

# Create proper .env file
log "Creating .env"
cat > .env << EOF
DB_PASSWORD=123
ERPNEXT_VERSION=v15.64.1
EOF

if [ "$DEPLOY_TYPE" = "with-plc" ]; then
    log "Setting up PLC integration"
    cat >> .env << EOF
CUSTOM_IMAGE=frappe-epibus
CUSTOM_TAG=latest
PULL_POLICY=never
EOF
    
    # Build EpiBus image
    if ! ./development/build-epibus-image.sh; then
        log "EpiBus build failed, falling back to basic deployment"
        DEPLOY_TYPE="basic"
        cat > .env << EOF
DB_PASSWORD=123
ERPNEXT_VERSION=v15.64.1
EOF
    fi
fi

# Deploy based on type
if [ "$DEPLOY_TYPE" = "with-plc" ]; then
    log "Deploying with PLC features"
    # Create compose file with PLC features
    cat > deploy.yml << EOF
version: "3"

services:
  backend:
    image: \${CUSTOM_IMAGE:-frappe/erpnext}:\${CUSTOM_TAG:-\$ERPNEXT_VERSION}
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs
    environment:
      DB_HOST: db
      DB_PORT: "3306"
      MYSQL_ROOT_PASSWORD: 123
      MARIADB_ROOT_PASSWORD: 123

  configurator:
    image: \${CUSTOM_IMAGE:-frappe/erpnext}:\${CUSTOM_TAG:-\$ERPNEXT_VERSION}
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: none
    entrypoint: [bash, -c]
    command:
      - >
        ls -1 apps > sites/apps.txt;
        bench set-config -g db_host \$\$DB_HOST;
        bench set-config -gp db_port \$\$DB_PORT;
        bench set-config -g redis_cache "redis://\$\$REDIS_CACHE";
        bench set-config -g redis_queue "redis://\$\$REDIS_QUEUE";
        bench set-config -g redis_socketio "redis://\$\$REDIS_QUEUE";
        bench set-config -gp socketio_port \$\$SOCKETIO_PORT;
    environment:
      DB_HOST: db
      DB_PORT: "3306"
      REDIS_CACHE: redis-cache:6379
      REDIS_QUEUE: redis-queue:6379
      SOCKETIO_PORT: "9000"
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  create-site:
    image: \${CUSTOM_IMAGE:-frappe/erpnext}:\${CUSTOM_TAG:-\$ERPNEXT_VERSION}
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: none
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs
    entrypoint: [bash, -c]
    command:
      - >
        wait-for-it -t 120 db:3306;
        wait-for-it -t 120 redis-cache:6379;
        wait-for-it -t 120 redis-queue:6379;
        export start=\`date +%s\`;
        until [[ -n \`grep -hs ^ sites/common_site_config.json | jq -r ".db_host // empty"\` ]] && 
          [[ -n \`grep -hs ^ sites/common_site_config.json | jq -r ".redis_cache // empty"\` ]] && 
          [[ -n \`grep -hs ^ sites/common_site_config.json | jq -r ".redis_queue // empty"\` ]];
        do
          echo "Waiting for sites/common_site_config.json to be created";
          sleep 5;
          if (( \`date +%s\`-start > 120 )); then
            echo "could not find sites/common_site_config.json with required keys";
            exit 1
          fi
        done;
        echo "sites/common_site_config.json found";
        bench new-site --mariadb-user-host-login-scope='%' --admin-password=admin --db-root-username=root --db-root-password=123 --install-app erpnext --install-app epibus --set-default frontend;

  db:
    image: mariadb:10.6
    networks: [frappe_network]
    healthcheck:
      test: mysqladmin ping -h localhost --password=123
      interval: 1s
      retries: 20
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --skip-character-set-client-handshake
      - --skip-innodb-read-only-compressed
    environment:
      MYSQL_ROOT_PASSWORD: 123
      MARIADB_ROOT_PASSWORD: 123
    volumes: [db-data:/var/lib/mysql]

  frontend:
    image: \${CUSTOM_IMAGE:-frappe/erpnext}:\${CUSTOM_TAG:-\$ERPNEXT_VERSION}
    networks: [frappe_network]
    depends_on: [websocket]
    deploy:
      restart_policy:
        condition: on-failure
    command: [nginx-entrypoint.sh]
    environment:
      BACKEND: backend:8000
      FRAPPE_SITE_NAME_HEADER: frontend
      SOCKETIO: websocket:9000
      UPSTREAM_REAL_IP_ADDRESS: 127.0.0.1
      UPSTREAM_REAL_IP_HEADER: X-Forwarded-For
      UPSTREAM_REAL_IP_RECURSIVE: "off"
      PROXY_READ_TIMEOUT: 120
      CLIENT_MAX_BODY_SIZE: 50m
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs
    ports: ["8080:8080"]

  queue-long:
    image: \${CUSTOM_IMAGE:-frappe/erpnext}:\${CUSTOM_TAG:-\$ERPNEXT_VERSION}
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: on-failure
    command: [bench, worker, --queue, long,default,short]
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  queue-short:
    image: \${CUSTOM_IMAGE:-frappe/erpnext}:\${CUSTOM_TAG:-\$ERPNEXT_VERSION}
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: on-failure
    command: [bench, worker, --queue, short,default]
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  redis-queue:
    image: redis:6.2-alpine
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: on-failure
    volumes: [redis-queue-data:/data]

  redis-cache:
    image: redis:6.2-alpine
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: on-failure

  scheduler:
    image: \${CUSTOM_IMAGE:-frappe/erpnext}:\${CUSTOM_TAG:-\$ERPNEXT_VERSION}
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: on-failure
    command: [bench, schedule]
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  websocket:
    image: \${CUSTOM_IMAGE:-frappe/erpnext}:\${CUSTOM_TAG:-\$ERPNEXT_VERSION}
    networks: [frappe_network]
    deploy:
      restart_policy:
        condition: on-failure
    command: [node, /home/frappe/frappe-bench/apps/frappe/socketio.js]
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  # PLC Services
  openplc:
    image: appliedrelevance/openplc:latest
    networks: [frappe_network]
    ports:
      - "8081:8080"
      - "502:502"
    volumes:
      - openplc_data:/workdir
    environment:
      - OPENPLC_LOG_LEVEL=INFO
    restart: unless-stopped

  plc-bridge:
    build: ./plc-bridge
    networks: [frappe_network]
    ports:
      - "7654:7654"
    environment:
      - OPENPLC_HOST=openplc
      - OPENPLC_PORT=502
      - FRAPPE_SITE=frontend
    volumes:
      - sites:/home/frappe/frappe-bench/sites:ro
    depends_on:
      - openplc
      - backend
    restart: unless-stopped

volumes:
  db-data:
  redis-queue-data:
  sites:
  logs:
  openplc_data:

networks:
  frappe_network:
    driver: bridge
EOF
    
    docker compose -f deploy.yml up -d
else
    log "Deploying basic Frappe"
    docker compose -f pwd.yml up -d
fi

# Wait for completion
log "Waiting for site creation"
if [ "$DEPLOY_TYPE" = "with-plc" ]; then
    COMPOSE_FILE="deploy.yml"
else
    COMPOSE_FILE="pwd.yml"
fi

# Wait for create-site to complete (up to 10 minutes)
for i in {1..600}; do
    if docker compose -f "$COMPOSE_FILE" ps create-site 2>/dev/null | grep -q "Exited (0)"; then
        log "Site creation completed"
        break
    fi
    sleep 1
    if [ $i -eq 600 ]; then 
        log "Site creation taking longer than expected, but may still be in progress"
        break
    fi
done

# Get port and verify
PORT=$(docker compose -f "$COMPOSE_FILE" port frontend 8080 2>/dev/null | cut -d: -f2 || echo "8080")

# Test frontend
log "Testing deployment"
sleep 10
if curl -f -s "http://localhost:$PORT" >/dev/null 2>&1; then
    log "SUCCESS! Deployment completed"
    echo "=================================="
    echo "Access: http://localhost:$PORT"
    echo "Login: Administrator / admin"
    echo "Deploy Type: $DEPLOY_TYPE"
    if [ "$DEPLOY_TYPE" = "with-plc" ]; then
        echo "OpenPLC: http://localhost:8081 (openplc/openplc)"
        echo "PLC Bridge: http://localhost:7654"
    fi
    echo "=================================="
else
    log "Frontend may still be starting. Check http://localhost:$PORT in a moment."
fi

# Cleanup
rm -f deploy.yml

log "Deployment script completed"