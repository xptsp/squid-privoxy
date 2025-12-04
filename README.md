# squid-privoxy

A docker image with Squid and Privoxy based on Alpine Linux. Now it has Squid as well for caching and modifying
requests.

As soon as you have several devices connected to your network and accessing Internet (TV, computers, tablets and
smartphones), you're better off running a proxy to access the Internet.  One proxy or 2 proxies cascaded?
- A filtering proxy will protect you from unwanted ads
- A filtering proxy will speed up your Internet browser, because you will no longer require to add an blockAds
extention in any of the browsers of your devices and computers.
- A cache proxy will speed up your Internet surfing by caching all latest used objects and load only what is
necessary.

# Launching Container: 

Docker compose file for this container:
```
services:
  squid-privoxy:
    image: xptsp/squid-privoxy:latest
    container_name: squid-privoxy
    ports:
      - 3128:3128     # Squid HTTP proxy server
      - 3129:3129     # Squid Transparent HTTP server
      - 3130:3130     # Squid Transparent HTTPS server
      - 8118:8118     # Privoxy server
      - 8080:8080     # Container WebUI
    #environment:
      # Uncomment next line to add privoxy-blocklist to crond (15min, daily, hourly, weekly, monthly)
      #- UPDATE_BLOCKLIST=weekly
    volumes:
      - ./cache:/var/cache/squid
      #- ./logs:/var/log/squid
      #- ./privoxy:/etc/privoxy
      #- ./squid:/etc/squid
    restart: always
```
If Squid and Privoxy settings directories are mounted, any missing Squid and/or Privoxy files are copied into 
their respective directories.  Existing configurations will **NOT** be overridden unless they are older than 
the default files in this container.

The [privoxy-blocklist.conf](https://github.com/xptsp/squid-privoxy/blob/master/service/privoxy-blocklist.conf) 
file can be found at **/etc/privoxy/privoxy-blocklist.conf**.  When environment variable UPDATE_BLOCKLIST is set,
the script is run at container launch, as well as added to the crond tasks at the specified cron period
(15min, daily, hourly, weekly, or monthly).

# Divert traffic to the transparent proxy with iptables ([Source](https://dev.to/suntong/a-short-guide-on-squid-transparent-proxy-ssl-bumping-k5c))

From other computers, we use the PREROUTING chain, specifying the source with -s:
```
iptables -t nat -A PREROUTING -s 192.168.0.0/2 -p tcp --dport 80 -j REDIRECT --to-port 3129
iptables -t nat -A PREROUTING -s 192.168.0.0/2 -p tcp --dport 443 -j REDIRECT --to-port 3130
```

On localhost this is a tougher issue since we want to avoid forwarding loops (packet is diverted to Squid but 
it should be sent to the Internet when Squid done its thing). Fortunately iptables can differentiate between 
packet owner users. We need to use the OUTPUT chain for locally-generated packets. So we allow packets by root 
and squid through and divert everything else to Squid.
```
iptables -t nat -A OUTPUT -p tcp -m tcp --dport 80 -m owner --uid-owner root -j RETURN
iptables -t nat -A OUTPUT -p tcp -m tcp --dport 80 -m owner --uid-owner squid -j RETURN
iptables -t nat -A OUTPUT -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3129
iptables -t nat -A OUTPUT -p tcp -m tcp --dport 443 -m owner --uid-owner root -j RETURN
iptables -t nat -A OUTPUT -p tcp -m tcp --dport 443 -m owner --uid-owner squid -j RETURN
iptables -t nat -A OUTPUT -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 3130
```

# Project History:

### **v0.3**
- Added althttpd for HTTP service on port 8080 
- Added SARG v2.4.0  for Squid usage reports.
### **v0.2** - [Release](https://github.com/xptsp/squid-privoxy/releases/tag/0.2)
- Added support for HTTPS transparent proxying (port 3130)
- Removed non-functional URL rewriter script.
- Docker Image: [xptsp/squid-privoxy:0.2](https://hub.docker.com/layers/xptsp/squid-privoxy/0.2/images/sha256-40eb47bc11ca9ad68a2d5f8d53a6e60b85bde546141b47fcd0b7a9e23e5fae19) 
### **v0.1** - [Release](https://github.com/xptsp/squid-privoxy/releases/tag/0.1)
- Forked from [synopsis8/squid-privoxy](https://github.com/synopsis8/squid-privoxy).  
- Fixed issue where the modified Squid and Privoxy weren't being placed in their respective directories.
- Empty mounted configuration folders now have default Squid and Privoxy configurations copied into them.  
- Added [privoxy-blocklist](https://github.com/Andrwe/privoxy-blocklist/) to the repo.
- Docker Image: [xptsp/squid-privoxy:0.1](https://hub.docker.com/layers/xptsp/squid-privoxy/0.1/images/sha256-db41c452c0aecd65c0277a27bd12e62fbea29256dd9c55b596eee0e761fe87eb) 
