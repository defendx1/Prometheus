#!/bin/bash

# Prometheus Standalone Installation Script
# Install Prometheus with Docker and Nginx SSL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_banner() {
    clear
    print_color $CYAN "======================================"
    print_color $CYAN "     📈 Prometheus Installation 📈"
    print_color $CYAN "======================================"
    print_color $YELLOW "    Monitoring & Alerting Platform"
    print_color $CYAN "======================================"
    echo
}

check_prerequisites() {
    print_color $BLUE "🔍 Checking prerequisites..."
    
    if [ "$EUID" -ne 0 ]; then
        print_color $RED "❌ Please run as root or with sudo"
        exit 1
    fi
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        print_color $YELLOW "📦 Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        rm get-docker.sh
    fi
    
    # Install Docker Compose if not present
    if ! command -v docker-compose &> /dev/null; then
        print_color $YELLOW "📦 Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # Install Nginx if not present
    if ! command -v nginx &> /dev/null; then
        print_color $YELLOW "📦 Installing Nginx..."
        apt update
        apt install -y nginx
        systemctl start nginx
        systemctl enable nginx
    fi
    
    # Install Certbot if not present
    if ! command -v certbot &> /dev/null; then
        print_color $YELLOW "📦 Installing Certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx apache2-utils
    fi
    
    print_color $GREEN "✅ Prerequisites ready!"
}

get_configuration() {
    print_banner
    print_color $YELLOW "🌐 Configuration Setup"
    echo
    
    # Get domain
    read -p "Enter domain for Prometheus (e.g., prometheus.yourdomain.com): " PROMETHEUS_DOMAIN
    if [ -z "$PROMETHEUS_DOMAIN" ]; then
        print_color $RED "❌ Domain cannot be empty"
        get_configuration
    fi
    
    # Get email for SSL
    read -p "Enter email for SSL certificate: " SSL_EMAIL
    if [ -z "$SSL_EMAIL" ]; then
        print_color $RED "❌ Email cannot be empty"
        get_configuration
    fi
    
    # Get admin credentials
    read -p "Enter admin username (default: admin): " PROM_USER
    PROM_USER=${PROM_USER:-admin}
    
    read -s -p "Enter admin password: " PROM_PASSWORD
    echo
    if [ -z "$PROM_PASSWORD" ]; then
        print_color $RED "❌ Password cannot be empty"
        get_configuration
    fi
    
    # Check port conflicts
    PROMETHEUS_PORT=9090
    ALERTMANAGER_PORT=9093
    NODE_EXPORTER_PORT=9100
    
    while netstat -tlnp | grep ":$PROMETHEUS_PORT " > /dev/null 2>&1; do
        PROMETHEUS_PORT=$((PROMETHEUS_PORT + 1))
    done
    
    while netstat -tlnp | grep ":$ALERTMANAGER_PORT " > /dev/null 2>&1; do
        ALERTMANAGER_PORT=$((ALERTMANAGER_PORT + 1))
    done
    
    while netstat -tlnp | grep ":$NODE_EXPORTER_PORT " > /dev/null 2>&1; do
        NODE_EXPORTER_PORT=$((NODE_EXPORTER_PORT + 1))
    done
    
    print_color $GREEN "✅ Configuration complete!"
    print_color $BLUE "   Domain: $PROMETHEUS_DOMAIN"
    print_color $BLUE "   Prometheus Port: $PROMETHEUS_PORT"
    print_color $BLUE "   AlertManager Port: $ALERTMANAGER_PORT"
    print_color $BLUE "   Node Exporter Port: $NODE_EXPORTER_PORT"
    print_color $BLUE "   Username: $PROM_USER"
    sleep 2
}

install_prometheus() {
    print_color $BLUE "📁 Creating directory structure..."
    mkdir -p /opt/prometheus-stack/{prometheus,alertmanager,node-exporter}
    mkdir -p /opt/prometheus-stack/prometheus/{data,config}
    mkdir -p /opt/prometheus-stack/alertmanager/{data,config}
    
    chown -R nobody:nogroup /opt/prometheus-stack/prometheus/data
    chown -R nobody:nogroup /opt/prometheus-stack/alertmanager/data
    
    cd /opt/prometheus-stack
    
    print_color $BLUE "📝 Creating Prometheus configuration..."
    cat > prometheus/config/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'nginx'
    static_configs:
      - targets: ['host.docker.internal:80', 'host.docker.internal:443']
    metrics_path: /metrics
    scrape_interval: 30s
EOF

    cat > prometheus/config/alert_rules.yml << EOF
groups:
  - name: basic_alerts
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ \$labels.instance }} down"
          description: "{{ \$labels.instance }} of job {{ \$labels.job }} has been down for more than 5 minutes."

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ \$labels.instance }}"
          description: "CPU usage is above 80% for more than 10 minutes."

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage on {{ \$labels.instance }}"
          description: "Memory usage is above 90% for more than 10 minutes."
EOF

    cat > alertmanager/config/alertmanager.yml << EOF
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alertmanager@${PROMETHEUS_DOMAIN}'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'
        send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF

    print_color $BLUE "🐳 Creating Docker Compose configuration..."
    cat > docker-compose.yml << EOF
version: '3.8'

networks:
  prometheus-network:
    driver: bridge

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "127.0.0.1:${PROMETHEUS_PORT}:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
      - '--web.external-url=https://${PROMETHEUS_DOMAIN}'
    volumes:
      - ./prometheus/config:/etc/prometheus
      - ./prometheus/data:/prometheus
    networks:
      - prometheus-network
    extra_hosts:
      - "host.docker.internal:host-gateway"

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    ports:
      - "127.0.0.1:${ALERTMANAGER_PORT}:9093"
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=https://${PROMETHEUS_DOMAIN}/alertmanager'
    volumes:
      - ./alertmanager/config:/etc/alertmanager
      - ./alertmanager/data:/alertmanager
    networks:
      - prometheus-network

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "127.0.0.1:${NODE_EXPORTER_PORT}:9100"
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    networks:
      - prometheus-network
EOF

    cat > .env << EOF
PROMETHEUS_DOMAIN=${PROMETHEUS_DOMAIN}
PROMETHEUS_PORT=${PROMETHEUS_PORT}
ALERTMANAGER_PORT=${ALERTMANAGER_PORT}
NODE_EXPORTER_PORT=${NODE_EXPORTER_PORT}
PROM_USER=${PROM_USER}
PROM_PASSWORD=${PROM_PASSWORD}
SSL_EMAIL=${SSL_EMAIL}
EOF

    # Generate htpasswd for basic auth
    HTPASSWD_ENTRY=$(htpasswd -nbB "$PROM_USER" "$PROM_PASSWORD")

    print_color $BLUE "🚀 Starting Prometheus stack..."
    docker-compose up -d
    
    sleep 30
    
    if docker-compose ps | grep -q "prometheus.*Up" && docker-compose ps | grep -q "alertmanager.*Up"; then
        print_color $GREEN "✅ Prometheus stack is running"
    else
        print_color $RED "❌ Some services failed to start"
        docker-compose logs
        exit 1
    fi
}

configure_nginx() {
    print_color $BLUE "🌐 Configuring Nginx..."
    
    # Initial HTTP configuration
    cat > /etc/nginx/sites-available/${PROMETHEUS_DOMAIN} << EOF
server {
    listen 80;
    server_name ${PROMETHEUS_DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/${PROMETHEUS_DOMAIN} /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    
    print_color $BLUE "🔒 Obtaining SSL certificate..."
    certbot --nginx -d ${PROMETHEUS_DOMAIN} --email ${SSL_EMAIL} --agree-tos --non-interactive --redirect
    
    # Create htpasswd file
    echo "$HTPASSWD_ENTRY" > /etc/nginx/.htpasswd_prometheus
    chmod 644 /etc/nginx/.htpasswd_prometheus
    
    # Final HTTPS configuration
    cat > /etc/nginx/sites-available/${PROMETHEUS_DOMAIN} << EOF
server {
    listen 80;
    server_name ${PROMETHEUS_DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${PROMETHEUS_DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${PROMETHEUS_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${PROMETHEUS_DOMAIN}/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;

    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;

    access_log /var/log/nginx/${PROMETHEUS_DOMAIN}_access.log;
    error_log /var/log/nginx/${PROMETHEUS_DOMAIN}_error.log;

    auth_basic "Prometheus Monitoring";
    auth_basic_user_file /etc/nginx/.htpasswd_prometheus;

    location / {
        proxy_pass http://127.0.0.1:${PROMETHEUS_PORT};
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /alertmanager/ {
        proxy_pass http://127.0.0.1:${ALERTMANAGER_PORT}/;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }
}
EOF

    nginx -t && systemctl reload nginx
    print_color $GREEN "✅ Nginx configured with SSL and authentication"
}

create_management_script() {
    print_color $BLUE "📝 Creating management script..."
    cat > /opt/prometheus-stack/manage-prometheus.sh << 'EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "$1" in
    start)
        echo "Starting Prometheus stack..."
        docker-compose up -d
        ;;
    stop)
        echo "Stopping Prometheus stack..."
        docker-compose down
        ;;
    restart)
        echo "Restarting Prometheus stack..."
        docker-compose restart
        ;;
    logs)
        service=${2:-}
        if [ -z "$service" ]; then
            echo "Showing all logs..."
            docker-compose logs -f
        else
            case $service in
                prometheus|prom)
                    docker-compose logs -f prometheus
                    ;;
                alertmanager|alert)
                    docker-compose logs -f alertmanager
                    ;;
                node-exporter|node)
                    docker-compose logs -f node-exporter
                    ;;
                *)
                    echo "Unknown service. Use: prometheus, alertmanager, or node-exporter"
                    ;;
            esac
        fi
        ;;
    status)
        echo "Prometheus stack status:"
        docker-compose ps
        echo
