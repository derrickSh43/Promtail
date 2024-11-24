#!/bin/bash
# Update the system packages
sudo dnf upgrade -y

# Install necessary tools
sudo dnf install -y wget unzip httpd

# ------------------------------
# Configure Promtail for Loki
# ------------------------------
# Download Promtail
wget https://github.com/grafana/loki/releases/download/v2.8.2/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod a+x /usr/local/bin/promtail

# Create Promtail configuration directory
sudo mkdir /etc/promtail

# NOTE: Replace "<LOKI_SERVER_IP>" with the private IP address or hostname of your Loki server
sudo tee /etc/promtail/promtail-config.yaml <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/positions.yaml

clients:
  - url: http://<LOKI_SERVER_IP>:3100/loki/api/v1/push

scrape_configs:
  - job_name: webserver_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: webserver
          instance: $(hostname)
          __path__: /var/log/httpd/access_log
  - job_name: system_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: system
          instance: $(hostname)
          __path__: /var/log/*.log
EOF

# Create Promtail systemd service
sudo tee /etc/systemd/system/promtail.service <<EOF
[Unit]
Description=Promtail Log Collector
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail/promtail-config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Promtail
sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail

# ------------------------------
# Configure Web Server (Apache)
# ------------------------------
# Start and enable the web server
sudo systemctl start httpd
sudo systemctl enable httpd

# Configure logging for the web server
sudo tee /etc/httpd/conf.d/log_config.conf <<EOF
# Custom Log Format for Apache
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
CustomLog /var/log/httpd/access_log combined
ErrorLog /var/log/httpd/error_log
EOF

# Restart Apache to apply logging changes
sudo systemctl restart httpd

# ------------------------------
# Verify Setup
# ------------------------------
# Print completion message
echo "Setup complete. Web server running, and Promtail is configured to send logs to Loki."
