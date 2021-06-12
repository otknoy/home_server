FROM prom/alertmanager:v0.21.0

ENV SLACK_API_URL http://your_slack_api_url.example.com

USER root

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER nobody

COPY alertmanager.yml /etc/alertmanager/alertmanager.template.yml

EXPOSE 9093

ENTRYPOINT ["/tini", "--", "docker-entrypoint.sh"]
