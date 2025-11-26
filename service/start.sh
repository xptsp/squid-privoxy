#!/bin/sh

_trap() {
    local pid=1
    for p in /opt/*/; do
        service=`basename "$p"`
        eval "pid=\${pid${service}}"
        echo "Killing service: ${service} (${pid})..."
        kill ${pid} 2>/dev/null
    done
}

trap _trap SIGTERM SIGINT

# Copy default files into their respective directories:
cp -aRu /opt/privoxy/* /etc/privoxy/
cp -aRu /opt/squid/* /etc/squid/

# Make sure that permissions are set correctly:
chown -R squid:squid /var/cache/squid
chown -R squid:squid /var/log/squid
chown -R privoxy:privoxy /etc/privoxy/*

# if specified periodic cron.d directory specified by environmental variable "USE_BLOCKLIST"
# exists, then create crond symbolic link to "/usr/bin/privoxy-blocklist" and run script:
if [[ -d /etc/periodic/${UPDATE_BLOCKLIST:="false"} ]]; then
  ln -sf /usr/bin/privoxy-blocklist /etc/periodic/${UPDATE_BLOCKLIST:="false"}/
  privoxy-blocklist
fi 
    
# Launch all services:
for p in /opt/*/; do
    service=`basename "$p"`
    echo "Starting service: $service..."
    cd "$p"
    /bin/sh ./run &

    lastPid=$!
    eval "pid${service}=${lastPid}"
done

# Wait for all services to exit
for p in /opt/*/; do
    service=`basename "$p"`
    pid=1
    eval "pid=\${pid${service}}"
    echo "Waiting for service to exit: ${service} (${pid})"
    wait ${pid}
done
