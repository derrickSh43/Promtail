# Promtail
Promtail userdata
Here's a detailed **README** for the script:



Setup Script for Promtail and Apache Web Server Logging

This script sets up Promtail to forward logs from a web server (Apache HTTP server) and system logs to a Loki instance. It also configures the web server with basic logging.

Features
1. Installs and configures Promtail for log forwarding.
2. Sets up an Apache web server with custom log formatting.
3. Ensures both services are enabled to start on boot.
4. Sends logs from:
   - Web server (`access_log`, `error_log`)
   - System (`/var/log/*.log`)

---

Instructions for Usage

### 1. Prerequisites
- An Amazon Linux 2023 EC2 instance with internet access.
- A Loki server running and accessible (IP or hostname required).
- Basic understanding of Amazon EC2 user data.

---

### 2. How to Use the Script
1. **Update the Script**:
   - Locate the `clients.url` field in the script:
     ```yaml
     clients:
       - url: http://<LOKI_SERVER_IP>:3100/loki/api/v1/push
     ```
   - Replace `<LOKI_SERVER_IP>` with the private IP or hostname of your Loki server. For example:
     ```yaml
     clients:
       - url: http://192.168.1.100:3100/loki/api/v1/push
     ```

2. Launch EC2 Instance:
   - Paste the entire script into the **User Data** section when launching your EC2 instance.
   - Ensure the security group for the instance allows:
     - Outbound HTTP (`port 3100`) for sending logs to the Loki server.
     - Inbound HTTP (`port 80`) for the web server.

3. Optional Configuration Changes:
   - **Promtail Configuration** (`/etc/promtail/promtail-config.yaml`):
     - To add more log paths or change labels, edit the `scrape_configs` section.
     - Example: Add an additional log file:
       ```yaml
       scrape_configs:
         - job_name: additional_logs
           static_configs:
             - targets:
                 - localhost
               labels:
                 job: additional
                 instance: $(hostname)
                 __path__: /path/to/your/log/file.log
       ```
   - Web Server Logging (`/etc/httpd/conf.d/log_config.conf`):
     - To modify the log format or location:
       ```bash
       LogFormat "%h %l %u %t \"%r\" %>s %b" custom_format
       CustomLog /var/log/httpd/custom_access_log custom_format
       ErrorLog /var/log/httpd/custom_error_log
       ```
       - Adjust `CustomLog` and `ErrorLog` directives as needed.

---

 3. Post-Launch Verification
1. **Web Server**:
   - Access the web server using the instance's public IP:
     ```
     http://<EC2_PUBLIC_IP>
     ```
   - Check logs:
     ```
     sudo tail -f /var/log/httpd/access_log
     sudo tail -f /var/log/httpd/error_log
     ```

2. **Promtail**:
   - Verify Promtail is running and forwarding logs:
     ```
     sudo systemctl status promtail
     sudo journalctl -u promtail
     ```
   - Look for logs indicating successful connections to the Loki server.

3. **Grafana**:
   - Query logs in Grafana:
     - Web server logs:
       ```bash
       {job="webserver"}
       ```
     - System logs:
       ```bash
       {job="system"}
       ```

---

### **4. Maintenance and Updates**
- To update the configuration:
  1. SSH into the instance.
  2. Edit the Promtail configuration:
     ```bash
     sudo nano /etc/promtail/promtail-config.yaml
     ```
  3. Edit the web server configuration:
     ```bash
     sudo nano /etc/httpd/conf.d/log_config.conf
     ```
  4. Restart the affected services:
     ```bash
     sudo systemctl restart promtail
     sudo systemctl restart httpd
     ```

- To check for Promtail and Apache updates:
  ```bash
  sudo dnf upgrade -y
  ```

---

### **5. Troubleshooting**
1. **No Logs in Grafana**:
   - Verify Loki server URL in `/etc/promtail/promtail-config.yaml`.
   - Check Promtail logs for errors:
     ```bash
     sudo journalctl -u promtail
     ```

2. **Web Server Not Accessible**:
   - Verify Apache is running:
     ```bash
     sudo systemctl status httpd
     ```
   - Check if the security group allows inbound traffic on port 80.

3. **Incorrect Logs**:
   - Verify the log paths in `/etc/promtail/promtail-config.yaml`.
   - Ensure correct permissions on log files.

---

### **6. Security Considerations**
- Restrict access to your Loki server using a private network or allowlist specific IPs.
- Rotate and archive logs to prevent disk space issues.

---
