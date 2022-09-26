# docker-dpitunnel

[python-proxy](https://github.com/qwj/python-proxy) + [DPITunnel-cli](https://github.com/zhenyolka/DPITunnel-cli)

## Usage

```yaml
version: '3'

services:
  dpitunnel:
    container_name: dpitunnel
    image: ghcr.io/by275/dpitunnel:latest
    restart: always
    network_mode: bridge
    ports:
      - "${PORT_TO_EXPOSE}:${PROXY_PORT:-8008}"
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - PROXY_USER=${PROXY_USER}
      - PROXY_PASS=${PROXY_PASS}
```

Up and run your container as above. Then you can access to your password-authenticated proxy server via

```http://${PROXY_USER}:${PROXY_PASS}@${DOCKER_HOST}:${PORT_TO_EXPOSE}```

Python-proxy running at front will forward all your requests to the internally working dpitunnel below

```bash
dpitunnel-cli --port ${DT_PORT:-8080} ${DT_USER_OPTS}
```

## Direct connection to DPITunnel

As dpitunnel is binding to ```0.0.0.0:8080```, you can directly access it independently to the proxy running at front by publishing your container port ```8080```. It is highly recommended exposing the port for internal use only.

## Environment variables

| ENV  | Description  | Default  |
|---|---|---|
| ```PUID``` / ```PGID```  | uid and gid for running an app  | ```911``` / ```911```  |
| ```TZ```  | timezone  | ```Asia/Seoul```  |
| ```PROXY_ENABLED```  | set ```false``` to disable proxy | ```true``` |
| ```PROXY_USER``` / ```PROXY_PASS```  | required both to activate proxy authentication   |  |
| ```PROXY_PORT```  | to run proxy in a different port  | ```8008``` |
| ```PROXY_VERBOSE```  | simple access logging  |  |
| ```PROXY_AUTHTIME```  | re-auth time interval for same ip (second in string format)  | ```0``` |
| ```DT_ENABLED```  | set ```false``` to disable dpitunnel  | ```true``` |
| ```DT_PORT```  | to run dpitunnel in different port  | ```8080```  |
| ```DT_USER_OPTS```  | extra agruments which will be passed to [DPITunnel-cli](https://github.com/zhenyolka/DPITunnel-cli)  | ```--desync-attacks=disorder_fake --wrong-seq```  |
| ```DT_DOH```  | resolve hosts over DoH server  | ```false```  |
| ```DT_DOHSERVER```  | DoH server URL  | ```https://dns.google/dns-query```  |
