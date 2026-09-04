### 3.1 From requirements to a file

This compose example turns a long list of requirements into configuration. Its eighty lines exercise code-block pagination without relying on real services.

```yaml
version: "3.9"
services:
  service01:
    image: example/service01:latest
    restart: unless-stopped
  service02:
    image: example/service02:latest
    restart: unless-stopped
  service03:
    image: example/service03:latest
    restart: unless-stopped
  service04:
    image: example/service04:latest
    restart: unless-stopped
  service05:
    image: example/service05:latest
    restart: unless-stopped
  service06:
    image: example/service06:latest
    restart: unless-stopped
  service07:
    image: example/service07:latest
    restart: unless-stopped
  service08:
    image: example/service08:latest
    restart: unless-stopped
  service09:
    image: example/service09:latest
    restart: unless-stopped
  service10:
    image: example/service10:latest
    restart: unless-stopped
  service11:
    image: example/service11:latest
    restart: unless-stopped
  service12:
    image: example/service12:latest
    restart: unless-stopped
  service13:
    image: example/service13:latest
    restart: unless-stopped
  service14:
    image: example/service14:latest
    restart: unless-stopped
  service15:
    image: example/service15:latest
    restart: unless-stopped
  service16:
    image: example/service16:latest
    restart: unless-stopped
  service17:
    image: example/service17:latest
    restart: unless-stopped
  service18:
    image: example/service18:latest
    restart: unless-stopped
  service19:
    image: example/service19:latest
    restart: unless-stopped
  service20:
    image: example/service20:latest
    restart: unless-stopped
  service21:
    image: example/service21:latest
    restart: unless-stopped
  service22:
    image: example/service22:latest
    restart: unless-stopped
  service23:
    image: example/service23:latest
    restart: unless-stopped
  service24:
    image: example/service24:latest
    restart: unless-stopped
  service25:
    image: example/service25:latest
    restart: unless-stopped
  service26:
    image: example/service26:latest
    restart: unless-stopped
```
