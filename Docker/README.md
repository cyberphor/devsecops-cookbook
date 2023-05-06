# Docker

**Build a Container**
```
docker build . -t foo:latest
```

**Prune Images, Containers, and Networks**
```
docker system prune -f
```

**Copy a File From a Container to the Host**
```
docker cp elasticsearch:/usr/share/elasticsearch/config/certs/http_ca.crt .
```

## References
* [Windows, curl, and Self-signed Certs](https://www.phillipsj.net/posts/windows-curl-and-self-signed-certs/)
