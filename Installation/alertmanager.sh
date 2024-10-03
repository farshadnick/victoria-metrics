
# ALERTMANAGER Installation 

export VERSION=0.26.0
wget https://github.com/prometheus/alertmanager/releases/download/v${VERSION}/alertmanager-${VERSION}.linux-amd64.tar.gz
tar -xvf alertmanager-${VERSION}.linux-amd64.tar.gz
cp alertmanager-${VERSION}.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-${VERSION}.linux-amd64/amtool /usr/local/bin/
mkdir /etc/alertmanager
chown alertmanager:alertmanager  /etc/alertmanager
useradd --no-create-home --shell /bin/false alertmanager
chown alertmanager:alertmanager /usr/local/bin/alertmanager
chown alertmanager:alertmanager /usr/local/bin/amtool


echo -n "global:
  resolve_timeout: 1m
  slack_api_url: 'https://hooks.slack.com/services/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'
route:
  receiver: 'telegram'
  routes:
    - match:
        severity: critical
      receiver: 'slack'
receivers:
- name: 'telegram'
  telegram_configs:
  - bot_token: 6571067885:AAHa1AuvHHRRpAd5TY1KtUbuT2n5mm4LdDo
    chat_id: 96100908
    api_url: "https://api.telegram.org"
    send_resolved: true
    parse_mode: ""

- name: 'slack'
  slack_configs:
  - channel: '#prom'
    send_resolved: true
    title: "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}"
    text: "{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}"

        #- name: 'slack-notifications'
        #  slack_configs:
        #  - send_resolved: true
"> /etc/alertmanager/alertmanager.yml

echo -n "[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target
[Service]
User=alertmanager
Group=alertmanager
Type=simple
WorkingDirectory=/etc/alertmanager/
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --web.external-url http://0.0.0.0:9093
[Install]
WantedBy=multi-user.target " >  /etc/systemd/system/alertmanager.service
