FROM alpine:latest

ENV UPDATE_BLOCKLIST=false

# Copy default configuration files to "/opt":
COPY service /opt/

# Install Squid and Privoxy:
RUN apk --no-cache --update add privoxy squid ca-certificates && \
    ln -sf /dev/stdout /var/log/privoxy/logfile && \
    mkdir -p /var/cache/squid /var/log/squid && \
    cp /opt/privoxy-blocklist.conf /etc/

# Get "privoxy-blocklist.sh" from GitHub:
RUN apk add --no-cache bash grep privoxy sed wget && \
    wget https://github.com/Andrwe/privoxy-blocklist/raw/refs/heads/main/privoxy-blocklist.sh -O /usr/bin/privoxy-blocklist && \
    chmod +x /usr/bin/privoxy-blocklist

# Configure services as necessary:
RUN cp -aRu /etc/squid/* /opt/squid/ && \
    cp -aRu /etc/privoxy/* /opt/privoxy

# We need ports 3128, 3129 and 8118 exposed:
EXPOSE 3128 3129 8118

# When container starts, execute "/opt/start.sh":
CMD ["/bin/sh", "/opt/start.sh"]
