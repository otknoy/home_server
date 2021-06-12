#!/bin/ash
cat /etc/alertmanager/alertmanager.template.yml | sed -e "s@\${SLACK_API_URL}@${SLACK_API_URL}@g" > /etc/alertmanager/alertmanager.yml

/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/alertmanager
