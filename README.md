# Prometheus Monitoring Stack Installation Script

![Prometheus Logo](https://prometheus.io/_next/static/media/prometheus-logo.7aa022e5.svg)

A comprehensive automated installation script for deploying Prometheus monitoring and alerting platform with AlertManager, Node Exporter, Nginx reverse proxy, and SSL certificates.

## 🚀 Features

- **Complete Monitoring Stack**: Prometheus, AlertManager, and Node Exporter
- **Automated Installation**: Full stack deployment with minimal user input
- **Docker-based**: Uses official Prometheus Docker images for easy management
- **SSL/HTTPS Support**: Automatic SSL certificate generation with Let's Encrypt
- **Nginx Reverse Proxy**: Professional web server configuration with HTTP authentication
- **Pre-configured Alerts**: Built-in alerting rules for system monitoring
- **Security Hardened**: Basic authentication and security headers
- **Data Persistence**: Persistent storage for metrics and configuration
- **Management Scripts**: Built-in scripts for easy maintenance and monitoring

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 18.04+ / Debian 10+ / CentOS 7+
- **RAM**: Minimum 2GB (recommended 4GB+)
- **Disk Space**: Minimum 10GB free space (more for long-term metrics storage)
- **Network**: Public IP address with domain pointing to it
- **Privileges**: Root access or sudo privileges

### Required Ports
- **80**: HTTP (for SSL certificate validation)
- **443**: HTTPS (Nginx reverse proxy)
- **9090**: Prometheus Server (localhost only)
- **9093**: AlertManager (localhost only)
- **9100**: Node Exporter (localhost only)

## 🛠 Installation

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/defendx1/Prometheus.git
   cd Prometheus
   chmod +x install-prometheus.sh
   ```

   **Or download directly**:
   ```bash
   wget https://raw.githubusercontent.com/defendx1/Prometheus/main/install-prometheus.sh
   chmod +x install-prometheus.sh
   ```

2. **Run the installation**:
   ```bash
   sudo ./install-prometheus.sh
   ```

3. **Follow the prompts**:
   - Enter your domain name (e.g., `prometheus.yourdomain.com`)
   - Provide email for SSL certificate
   - Set admin username (default: admin)
   - Set admin password for web interface

### Manual Installation Steps

The script automatically handles:
- ✅ Docker and Docker Compose installation
- ✅ Nginx web server installation
- ✅ Certbot for SSL certificates
- ✅ System requirements validation
- ✅ Port conflict resolution
- ✅ Directory structure creation
- ✅ Prometheus configuration
- ✅ AlertManager setup
- ✅ Node Exporter configuration
- ✅ SSL certificate generation
- ✅ HTTP Basic Authentication setup

## 🔧 Configuration

### Default Access
- **URL**: `https://your-domain.com`
- **Username**: Set during installation (default: admin)
- **Password**: Set during installation
- **AlertManager**: `https://your-domain.com/alertmanager/`

### Docker Services
The installation creates the following containers:
- `prometheus`: Main Prometheus server for metrics collection
- `alertmanager`: AlertManager for handling alerts
- `node-exporter`: System metrics exporter

### File Structure
```
/opt/prometheus-stack/
├── docker-compose.yml          # Main Docker Compose configuration
├── .env                        # Environment variables
├── manage-prometheus.sh        # Management script
├── prometheus/
│   ├── config/
│   │   ├── prometheus.yml      # Prometheus configuration
│   │   └── alert_rules.yml     # Alerting rules
│   └── data/                   # Prometheus data storage
├── alertmanager/
│   ├── config/
│   │   └── alertmanager.yml    # AlertManager configuration
│   └── data/                   # AlertManager data storage
└── node-exporter/              # Node Exporter directory
```

## 🎮 Management Commands

Use the built-in management script for easy operations:

```bash
cd /opt/prometheus-stack

# Start all services
./manage-prometheus.sh start

# Stop all services
./manage-prometheus.sh stop

# Restart all services
./manage-prometheus.sh restart

# View logs (all services)
./manage-prometheus.sh logs

# View specific service logs
./manage-prometheus.sh logs prometheus     # Prometheus logs
./manage-prometheus.sh logs alertmanager   # AlertManager logs
./manage-prometheus.sh logs node-exporter  # Node Exporter logs

# Check status
./manage-prometheus.sh status

# Create backup
./manage-prometheus.sh backup

# Update containers
./manage-prometheus.sh update

# Reload Prometheus configuration
./manage-prometheus.sh reload

# Test alert rules
./manage-prometheus.sh test-alerts
```

## 🔐 Security Features

### SSL/TLS Configuration
- **TLS 1.2/1.3** support only
- **HSTS** (HTTP Strict Transport Security) headers
- **Security headers**: X-Content-Type-Options, X-Frame-Options
- **Automatic HTTP to HTTPS** redirection

### Authentication
- **HTTP Basic Authentication** for web interface access
- **Bcrypt password hashing** for secure credential storage
- **Configurable user credentials** during installation

### Network Security
- All services accessible only through Nginx proxy
- Local-only binding for Prometheus services
- Configurable port assignments to avoid conflicts

## 📊 Monitoring Capabilities

### Built-in Metrics Collection

1. **System Metrics** (via Node Exporter):
   - CPU usage, load average
   - Memory and swap utilization
   - Disk space and I/O statistics
   - Network interface statistics
   - System uptime and boot time

2. **Prometheus Self-Monitoring**:
   - Query performance metrics
   - Storage and ingestion statistics
   - Rule evaluation metrics
   - Target scrape statistics

3. **Web Server Monitoring**:
   - Nginx access and error logs
   - HTTP response codes and latency
   - SSL certificate expiration

### Pre-configured Alert Rules

The installation includes essential alerting rules:

- **InstanceDown**: Alerts when monitored instances become unreachable
- **HighCPUUsage**: Triggers when CPU usage exceeds 80% for 10 minutes
- **HighMemoryUsage**: Alerts when memory usage exceeds 90% for 10 minutes
- **DiskSpaceLow**: Warns when disk space falls below threshold
- **ServiceDown**: Alerts when critical services stop responding

### Custom Metrics and Targets

Add custom monitoring targets by editing `/opt/prometheus-stack/prometheus/config/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'custom-app'
    static_configs:
      - targets: ['app-server:8080']
    scrape_interval: 30s
    metrics_path: /metrics
```

## 🔔 AlertManager Configuration

### Default Alert Routing
- **Group By**: Alert name for efficient notification grouping
- **Group Wait**: 10 seconds before sending grouped alerts
- **Repeat Interval**: 1 hour for repeat notifications

### Notification Channels
Configure various notification methods by editing `/opt/prometheus-stack/alertmanager/config/alertmanager.yml`:

**Email Notifications**:
```yaml
receivers:
  - name: 'email-alerts'
    email_configs:
      - to: 'admin@yourdomain.com'
        from: 'alertmanager@yourdomain.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'
```

**Slack Notifications**:
```yaml
receivers:
  - name: 'slack-alerts'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
        title: 'Prometheus Alert'
```

## 🔄 Backup and Restore

### Automated Backup
```bash
./manage-prometheus.sh backup
```
Creates timestamped backup including:
- Prometheus time-series data
- Configuration files
- AlertManager data and configuration

### Manual Backup
```bash
# Stop services
./manage-prometheus.sh stop

# Create backup
tar -czf prometheus-backup-$(date +%Y%m%d).tar.gz /opt/prometheus-stack/

# Start services
./manage-prometheus.sh start
```

### Restore Process
```bash
# Stop services
./manage-prometheus.sh stop

# Restore data
tar -xzf prometheus-backup.tar.gz -C /

# Fix permissions
chown -R nobody:nogroup /opt/prometheus-stack/prometheus/data
chown -R nobody:nogroup /opt/prometheus-stack/alertmanager/data

# Start services
./manage-prometheus.sh start
```

## 🚨 Troubleshooting

### Common Issues

**1. Services won't start**
```bash
# Check logs
./manage-prometheus.sh logs

# Check Docker daemon
systemctl status docker

# Verify configuration
docker-compose config
```

**2. Metrics not appearing**
```bash
# Check Prometheus targets
curl -u admin:password https://your-domain.com/api/v1/targets

# Verify scrape configurations
./manage-prometheus.sh logs prometheus
```

**3. Alerts not firing**
```bash
# Check alert rules
./manage-prometheus.sh test-alerts

# Verify AlertManager status
./manage-prometheus.sh logs alertmanager
```

**4. SSL certificate issues**
```bash
# Renew certificate
certbot renew --nginx

# Check certificate status
certbot certificates
```

### Log Locations
- **Prometheus**: `docker logs prometheus`
- **AlertManager**: `docker logs alertmanager`
- **Node Exporter**: `docker logs node-exporter`
- **Nginx**: `/var/log/nginx/`

## 🔄 Updates and Maintenance

### Update Prometheus Stack
```bash
cd /opt/prometheus-stack
./manage-prometheus.sh update
```

### Configuration Reload
```bash
# Reload Prometheus configuration without restart
./manage-prometheus.sh reload

# Restart specific service
docker-compose restart prometheus
```

### Data Retention
Configure data retention in `/opt/prometheus-stack/docker-compose.yml`:
```yaml
command:
  - '--storage.tsdb.retention.time=365d'  # Keep data for 1 year
  - '--storage.tsdb.retention.size=50GB'  # Maximum storage size
```

## 📊 Performance Tuning

### Storage Optimization
```yaml
# In docker-compose.yml, adjust Prometheus command:
command:
  - '--storage.tsdb.retention.time=30d'
  - '--storage.tsdb.retention.size=10GB'
  - '--storage.tsdb.wal-compression'
```

### Query Performance
```yaml
# Increase query timeout and max samples
command:
  - '--query.timeout=2m'
  - '--query.max-samples=50000000'
```

### Resource Limits
```yaml
# Add resource limits to docker-compose.yml
services:
  prometheus:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

## 🔗 Integration Examples

### Grafana Integration
```bash
# Prometheus data source URL for Grafana
http://prometheus:9090
```

### Custom Application Metrics
```python
# Python example using prometheus_client
from prometheus_client import Counter, start_http_server

REQUEST_COUNT = Counter('app_requests_total', 'Total requests')

@app.route('/metrics')
def metrics():
    REQUEST_COUNT.inc()
    return generate_latest()
```

## 🆘 Support and Resources

### Project Resources
- **GitHub Repository**: [https://github.com/defendx1/Prometheus](https://github.com/defendx1/Prometheus)
- **Issues & Support**: [Report Issues](https://github.com/defendx1/Prometheus/issues)
- **Latest Releases**: [View Releases](https://github.com/defendx1/Prometheus/releases)

### Official Documentation
- [Prometheus Documentation](https://prometheus.io/docs/)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Node Exporter Documentation](https://github.com/prometheus/node_exporter)
- [Docker Documentation](https://docs.docker.com/)

### Community Support
- [Prometheus Community](https://prometheus.io/community/)
- [CNCF Slack #prometheus](https://slack.cncf.io/)
- [DefendX1 Telegram](https://t.me/defendx1)

## 📄 License

This script is provided under the MIT License. See LICENSE file for details.

---

## 👨‍💻 Author & Contact

**Script Developer**: DefendX1 Team  
**Website**: [https://defendx1.com/](https://defendx1.com/)  
**Telegram**: [t.me/defendx1](https://t.me/defendx1)

### About DefendX1
DefendX1 specializes in cybersecurity solutions, infrastructure automation, and monitoring systems. Visit [defendx1.com](https://defendx1.com/) for more security tools and monitoring resources.

---

## 🔗 Resources & Links

### Project Resources
- **GitHub Repository**: [https://github.com/defendx1/Prometheus](https://github.com/defendx1/Prometheus)
- **Issues & Support**: [Report Issues](https://github.com/defendx1/Prometheus/issues)
- **Latest Releases**: [View Releases](https://github.com/defendx1/Prometheus/releases)

### Download & Installation
**GitHub Repository**: [https://github.com/defendx1/Prometheus](https://github.com/defendx1/Prometheus)

Clone or download the latest version:
```bash
git clone https://github.com/defendx1/Prometheus.git
```

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository: [https://github.com/defendx1/Prometheus](https://github.com/defendx1/Prometheus)
2. Create a feature branch
3. Submit a pull request

## ⭐ Star This Project

If this script helped you, please consider starring the repository at [https://github.com/defendx1/Prometheus](https://github.com/defendx1/Prometheus)!

---

**Last Updated**: June 2025  
**Version**: 1.0.0
