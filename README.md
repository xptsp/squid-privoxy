# squid-privoxy

A docker image with Squid and Privoxy based on Alpine Linux. Now it has Squid as well for caching and modifying requests.

As soon as you have several devices connected to your network and accessing Internet (TV, computers, tablets and smartphones), you're better off running a proxy to access the Internet.
One proxy or 2 proxies cascaded ?
- A filtering proxy will protect you from unwanted ads
- A filtering proxy will speed up your Internet browser, because you will no longer require to add an blockAds extention in any of the browsers of your devices and computers.
- A cache proxy will speed up your Internet surfing by caching all latest used objects and load only what is necessary.

# Squid settings

Docker compose file for this container:
```
services:
  squid-privoxy:
    image: xptsp/squid-privoxy:latest
    container_name: squid-privoxy
    ports:
      - 3128:3128     # Squid HTTP proxy server
      - 3129:3129     # Squid Transparent HTTP server 
      - 8118:8118     # Privoxy server
    environment:
      - UPDATE_BLOCKLIST=weekly  # Uncomment and change to add privoxy-blocklist to crond  
    volumes:
      - ./cache:/var/cache/squid
      #- ./privoxy-blocklist.cfg:/etc/privoxy-blocklist.cfg
      #- ./privoxy:/opt/privoxy
      #- ./squid:/opt/squid
    restart: always
```
If Squid and Privoxy settings directories are mounted, any missing Squid and/or Privoxy files are copied into their respective directories.
Existing configurations will **NOT** be overridden unless they are older than the default files in this container.

# Built-in URL Rewriter
The image has an URL rewrite script to be able to modify request URLs. You can configure it by mounting a file into /opt/squid/rewriter.conf like this:

### URL rewriter: change in the server, not in the browser
```
SED="$SED;s|^http://\(.*google\)\.hu|\1.com|g"
```

### URL redirect in the browser with HTTP status code 302
```
SED="$SED;s|^http://\(.*google\)\.com|302:\1.hu|g"
```

# GitHub Repository

The GitHub Repository for this docker container is [here](https://github.com/xptsp/squid-privoxy).
