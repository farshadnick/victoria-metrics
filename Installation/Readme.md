#!/bin/bash

set -e

system_set_hostname "$HOSTNAME"

apt update && apt upgrade -y && apt install -y curl wget net-tools traceroute jq
# Generate files
mkdir -p /etc/victoriametrics/single
mkdir -p /var/lib/victoria-metrics-data

# Create victoriametrics user
groupadd -r victoriametrics
useradd -g victoriametrics -d /var/lib/victoria-metrics-data -s /sbin/nologin --system victoriametrics
chown -R victoriametrics:victoriametrics /var/lib/victoria-metrics-data

# Install VictoriaMetrics Single
VM_VERSION=`curl -sg "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/tags" | jq -r '.[0].name'`
wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${VM_VERSION}/victoria-metrics-linux-amd64-${VM_VERSION}.tar.gz  -O /tmp/victoria-metrics.tar.gz
tar xvf /tmp/victoria-metrics.tar.gz -C /usr/bin
chmod +x /usr/bin/victoria-metrics-prod
chown root:root /usr/bin/victoria-metrics-prod

cat <<END >/etc/systemd/system/vmsingle.service
[Unit]
Description=VictoriaMetrics is a fast, cost-effective and scalable monitoring solution and time series database.
# https://docs.victoriametrics.com
After=network.target
[Service]
Type=simple
User=victoriametrics
Group=victoriametrics
WorkingDirectory=/var/lib/victoria-metrics-data
StartLimitBurst=5
StartLimitInterval=0
Restart=on-failure
RestartSec=5
EnvironmentFile=-/etc/victoriametrics/single/victoriametrics.conf
ExecStart=/usr/bin/victoria-metrics-prod \$ARGS
ExecStop=/bin/kill -s SIGTERM \$MAINPID
ExecReload=/bin/kill -HUP \$MAINPID
# See docs https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#tuning
ProtectSystem=full
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vmsingle
[Install]
WantedBy=multi-user.target
END

cat <<END >/etc/victoriametrics/single/victoriametrics.conf
# See https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#list-of-command-line-flags to get more information about supported command-line flags
# 
# If you use IPv6 pleas add "-enableTCP6" to args line
ARGS="-promscrape.config=/etc/victoriametrics/single/scrape.yml -storageDataPath=/var/lib/victoria-metrics-data -retentionPeriod=12 -httpListenAddr=:8428 -graphiteListenAddr=:2003 -opentsdbListenAddr=:4242 -influxListenAddr=:8089 -enableTCP6"
END

cat <<END >/etc/victoriametrics/single/scrape.yml
# Scrape config example
#
scrape_configs:
  - job_name: self_scrape
    scrape_interval: 10s
    static_configs:
      - targets: ['127.0.0.1:8428'] 
END

chown -R victoriametrics:victoriametrics /etc/victoriametrics/single

# Start VictoriaMetrics
systemctl enable vmsingle.service
systemctl restart vmsingle.service
systemctl status vmsingle.service
