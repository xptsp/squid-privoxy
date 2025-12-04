# This step builds SARG v2.4.0:
#============================================================================================== 
FROM alpine:latest AS builder
RUN apk add build-base gcc gd gd-dev make perl-gd wget pcre-dev && \
    wget https://netactuate.dl.sourceforge.net/project/sarg/sarg/sarg-2.4.0/sarg-2.4.0.tar.gz && \
    tar -xvzf sarg-2.4.0.tar.gz && \
    cd /sarg-2.4.0 && \ 
    ./configure && \
    sed -i "s|CFLAGS      = |CFLAGS      = -fcommon |g" Makefile && \
    make

# Build the actual container to use:
#============================================================================================== 
FROM alpine:latest

ENV UPDATE_BLOCKLIST=false
ENV EDITOR=/usr/bin/nano

# Copy SARG files from builder container made earlier:
COPY --from=builder /sarg-2.4.0/sarg /usr/local/bin/
COPY --from=builder /sarg-2.4.0/sarg.conf /usr/local/etc/
COPY --from=builder /sarg-2.4.0/css.tpl /usr/local/etc/
COPY --from=builder /sarg-2.4.0/exclude_codes /usr/local/etc/
COPY --from=builder /sarg-2.4.0/images/ /usr/local/share/sarg/images
COPY --from=builder /sarg-2.4.0/fonts/ /usr/local/share/sarg/fonts
COPY /service/sarg.conf /usr/local/etc/
RUN ln /usr/local/etc/sarg.conf /etc/sarg.conf && \
    echo "*       */1     *       *       *       /usr/local/bin/sarg -x" >> /etc/crontabs/root

# Install Squid and Privoxy:
RUN apk --no-cache --update add privoxy squid ca-certificates openssl althttpd logrotate nano gd && \
    ln -sf /dev/stdout /var/log/privoxy/logfile && \
    mkdir -p /var/cache/squid /var/log/squid && \
    touch /var/log/squid/access.log

# Get "privoxy-blocklist.sh" from GitHub:
RUN apk add --no-cache --update bash grep privoxy sed wget && \
    wget https://github.com/Andrwe/privoxy-blocklist/raw/refs/heads/main/privoxy-blocklist.sh -O /usr/bin/privoxy-blocklist && \
    chmod +x /usr/bin/privoxy-blocklist && \
    ln -sf /etc/privoxy/privoxy-blocklist /etc/privoxy-blocklist

# Initialize Squid SSL database:
RUN /usr/lib/squid/security_file_certgen -s /var/lib/ssl_db -M 4MB -c && \
    chown squid:squid -R /var/lib/ssl_db

# Copy default configuration files to "/opt":
COPY service /opt/

# Copy websites to "/www" and change ownership to /www:
COPY www /www/
RUN chown nobody:nobody -R /www

# We need ports 3128, 3129, 3130, 8080 and 8118 exposed:
EXPOSE 3128 3129 3130 8118 8080

# When container starts, execute "/opt/start.sh":
CMD ["/bin/sh", "/opt/start.sh"]
